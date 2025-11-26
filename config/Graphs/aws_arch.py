# file: network_boundaries_v3.py
# Requires: pip install diagrams ; local Graphviz installed

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.general import InternetAlt2
from diagrams.aws.network import ALB, InternetGateway, RouteTable, NATGateway
from diagrams.aws.compute import Fargate
from diagrams.aws.database import RDS, ElastiCache
from diagrams.aws.integration import SNS, SQS
from diagrams.aws.security import Shield  # 用作 SG 图标

with Diagram(
    "Ticketing - Network Boundaries (us-west-2)",
    filename="network_boundaries_v3",
    show=False,
    direction="LR",  # left-to-right to place services on left and data/messaging on right
):
    internet = InternetAlt2("Internet")

    # ================= Region / Account / VPC（仅 Public 子网） =================
    with Cluster("Region: us-west-2"):
        with Cluster("AWS Account"):
            with Cluster(
                "VPC: ticketing VPC 10.0.0.0/16",
                direction="LR",
            ):
                # Public subnet: hosts ALB, IGW, RT and NAT
                with Cluster("Public Subnet (ALB + NAT)"):
                    # 可选：把 IGW/RTB 用虚线表示“控制层/路由”，不影响核心链路可读性
                    igw = InternetGateway("IGW")
                    rtb_public = RouteTable("Public RT\n0.0.0.0/0 → IGW")

                    # 入口：ALB + SG（内联）
                    sg_alb = Shield("ALB-SG\n80/443 from 0.0.0.0/0")
                    alb = ALB("Application Load Balancer :80/:443")

                    # NAT Gateway in public subnet
                    nat = NATGateway("NAT Gateway")

                # Private subnet: hosts ECS, etc.
                with Cluster("Private Subnet (ECS)"):
                    # 应用：ECS + SG（内联）
                    sg_ecs = Shield("ECS-SG\n:8080 from ALB-SG")

                    # Adjusting the order of services
                    with Cluster(
                        "ECS Fargate Services (:8080)",
                        direction="TB"
                    ):
                        svc_purchase = Fargate("PurchaseService")
                        svc_projector = Fargate("MessagePersistenceService")
                        svc_query = Fargate("QueryService")

                    # ...existing code...

                        # 私有路由表 (→ NAT)
                        rtb_private = RouteTable(
                            "Private RT\\n0.0.0.0/0 → NAT"
                        )

                        # Backend Data & Messaging: move into private subnet
                        with Cluster(
                            "Backend Data & Messaging",
                            direction="LR",
                        ):
                            sg_redis = Shield("REDIS-SG\\n:6379 from ECS-SG")
                            redis = ElastiCache("Redis :6379\\n(single node)")

                            with Cluster("Messaging"):
                                sns = SNS("SNS Topic: ticket-events")
                                sqs = SQS("SQS Queue: ticket-sqs")

                            sg_rds = Shield("RDS-SG\\n:3306 from ECS-SG")
                            rds = RDS("Aurora MySQL :3306\\n(single instance)")

    # ========================== 流量路径（把 SG 放进链路） ==========================
    # Internet -> (ALB-SG) -> ALB
    internet >> Edge(label="HTTPS 443") >> sg_alb >> alb

    # ALB -> (ECS-SG) -> ECS Services (explicit per-service edges for clarity)
    alb >> Edge(label="HTTP 8080") >> sg_ecs
    sg_ecs >> Edge(label="HTTP/8080 → MsgPersist") >> svc_projector
    sg_ecs >> Edge(label="HTTP/8080 → Purchase") >> svc_purchase
    sg_ecs >> Edge(label="HTTP/8080 → Query") >> svc_query

    # Query/Projector -> RDS (use explicit Edge objects)
    edge_query_to_rds = Edge(color="green", label="TCP/3306 → RDS")
    svc_query >> edge_query_to_rds >> sg_rds
    sg_rds >> rds

    edge_projector_to_rds = Edge(color="orange", label="TCP/3306 → RDS")
    svc_projector >> edge_projector_to_rds >> sg_rds
    sg_rds >> rds

    # Purchase -> (REDIS-SG) -> Redis
    edge_purchase_redis = Edge(color="blue", label="TCP/6379 → Redis")
    svc_purchase >> edge_purchase_redis >> sg_redis
    sg_redis >> redis

    # 消息链路：Purchase -> SNS -> SQS -> Projector
    svc_purchase >> Edge(color="red", label="Publish → SNS") >> sns
    sns >> Edge(color="red", label="Fan-out → SQS") >> sqs
    sqs >> Edge(color="red", label="Consume → MsgPersist") >> svc_projector

    # (Observability moved to a separate diagram)

    # ============= 可选的“控制/路由面”虚线路径，帮助定位但不干扰主视图 =============
    internet >> Edge(style="dotted") >> igw
    igw >> Edge(style="dotted") >> rtb_public
    # Private RT -> NAT -> IGW (egress path)
    rtb_private >> Edge(style="dotted") >> nat
    nat >> Edge(style="dotted") >> igw
