#!/bin/bash
# Cleanup AWS resources that Terraform couldn't destroy due to missing state

set -e

REGION="us-west-2"
echo "🗑️  Cleaning up AWS resources in region: $REGION"

# Delete ECR repositories
echo "Deleting ECR repositories..."
aws ecr delete-repository --repository-name purchase-service --region $REGION --force 2>/dev/null || true
aws ecr delete-repository --repository-name query-service --region $REGION --force 2>/dev/null || true
aws ecr delete-repository --repository-name message-persistence-service --region $REGION --force 2>/dev/null || true

# Delete ECS services (must be done before cluster)
echo "Deleting ECS services..."
aws ecs update-service --cluster ticketing-prod-cluster --service ticketing-purchase-service --desired-count 0 --region $REGION 2>/dev/null || true
aws ecs update-service --cluster ticketing-prod-cluster --service ticketing-query-service --desired-count 0 --region $REGION 2>/dev/null || true
aws ecs update-service --cluster ticketing-prod-cluster --service ticketing-message-persistence-service --desired-count 0 --region $REGION 2>/dev/null || true

sleep 10

aws ecs delete-service --cluster ticketing-prod-cluster --service ticketing-purchase-service --region $REGION --force 2>/dev/null || true
aws ecs delete-service --cluster ticketing-prod-cluster --service ticketing-query-service --region $REGION --force 2>/dev/null || true
aws ecs delete-service --cluster ticketing-prod-cluster --service ticketing-message-persistence-service --region $REGION --force 2>/dev/null || true

# Delete ECS cluster
echo "Deleting ECS cluster..."
aws ecs delete-cluster --cluster ticketing-prod-cluster --region $REGION 2>/dev/null || true

# Delete ALB Target Groups
echo "Deleting ALB target groups..."
for tg in purchase-service-tg query-service-tg message-persistence-service-tg; do
  TG_ARN=$(aws elbv2 describe-target-groups --region $REGION --query "TargetGroups[?TargetGroupName=='$tg'].TargetGroupArn" --output text 2>/dev/null || echo "")
  if [ ! -z "$TG_ARN" ]; then
    aws elbv2 delete-target-group --target-group-arn $TG_ARN --region $REGION 2>/dev/null || true
  fi
done

# Delete ALB
echo "Deleting Application Load Balancer..."
ALB_ARN=$(aws elbv2 describe-load-balancers --region $REGION --query "LoadBalancers[?contains(LoadBalancerName, 'ticketing')].LoadBalancerArn" --output text 2>/dev/null || echo "")
if [ ! -z "$ALB_ARN" ]; then
  aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN --region $REGION 2>/dev/null || true
fi

# Delete CloudWatch Log Groups
echo "Deleting CloudWatch log groups..."
aws logs delete-log-group --log-group-name /ecs/purchase-service --region $REGION 2>/dev/null || true
aws logs delete-log-group --log-group-name /ecs/query-service --region $REGION 2>/dev/null || true
aws logs delete-log-group --log-group-name /ecs/message-persistence-service --region $REGION 2>/dev/null || true

# Delete Secrets Manager secrets
echo "Deleting Secrets Manager secrets..."
aws secretsmanager delete-secret --secret-id ticketing-redis-credentials --force-delete-without-recovery --region $REGION 2>/dev/null || true
aws secretsmanager delete-secret --secret-id ticketing-db-credentials --force-delete-without-recovery --region $REGION 2>/dev/null || true
aws secretsmanager delete-secret --secret-id ticketing-redis-credentials-v --force-delete-without-recovery --region $REGION 2>/dev/null || true
aws secretsmanager delete-secret --secret-id ticketing-db-credentials-v --force-delete-without-recovery --region $REGION 2>/dev/null || true

# Delete RDS Cluster (if exists)
echo "Deleting RDS cluster..."
aws rds delete-db-cluster --db-cluster-identifier ticketing-aurora --skip-final-snapshot --region $REGION 2>/dev/null || true

# Delete RDS Subnet Group
echo "Deleting RDS subnet group..."
sleep 30  # Wait for cluster deletion to start
aws rds delete-db-subnet-group --db-subnet-group-name ticketing-aurora-subnet-group --region $REGION 2>/dev/null || true

# Wait for RDS subnet group to be fully deleted
echo "Waiting for RDS subnet group to be fully deleted..."
for i in {1..30}; do
  if ! aws rds describe-db-subnet-groups --db-subnet-group-name ticketing-aurora-subnet-group --region $REGION 2>/dev/null | grep -q "ticketing-aurora-subnet-group"; then
    echo "✅ RDS subnet group deleted"
    break
  fi
  echo "⏳ Still deleting... ($i/30)"
  sleep 10
done

# Delete RDS Parameter Group
echo "Deleting RDS parameter group..."
aws rds delete-db-cluster-parameter-group --db-cluster-parameter-group-name ticketing-mysql-params --region $REGION 2>/dev/null || true

# Wait for RDS parameter group to be fully deleted
echo "Waiting for RDS parameter group to be fully deleted..."
for i in {1..30}; do
  if ! aws rds describe-db-cluster-parameter-groups --db-cluster-parameter-group-name ticketing-mysql-params --region $REGION 2>/dev/null | grep -q "ticketing-mysql-params"; then
    echo "✅ RDS parameter group deleted"
    break
  fi
  echo "⏳ Still deleting... ($i/30)"
  sleep 10
done

# Delete ElastiCache cluster
echo "Deleting ElastiCache cluster..."
aws elasticache delete-cache-cluster --cache-cluster-id ticketing-redis --region $REGION 2>/dev/null || true

# Delete ElastiCache Subnet Group
echo "Deleting ElastiCache subnet group..."
sleep 30  # Wait for cluster deletion
aws elasticache delete-cache-subnet-group --cache-subnet-group-name ticketing-cache-subnet-group --region $REGION 2>/dev/null || true

# Wait for subnet group to be fully deleted
echo "Waiting for ElastiCache subnet group to be fully deleted..."
for i in {1..30}; do
  if ! aws elasticache describe-cache-subnet-groups --cache-subnet-group-name ticketing-cache-subnet-group --region $REGION 2>/dev/null | grep -q "ticketing-cache-subnet-group"; then
    echo "✅ ElastiCache subnet group deleted"
    break
  fi
  echo "⏳ Still deleting... ($i/30)"
  sleep 10
done

# Delete ElastiCache Parameter Group
echo "Deleting ElastiCache parameter group..."
aws elasticache delete-cache-parameter-group --cache-parameter-group-name ticketing-redis-params --region $REGION 2>/dev/null || true

# Wait for parameter group to be fully deleted
echo "Waiting for ElastiCache parameter group to be fully deleted..."
for i in {1..30}; do
  if ! aws elasticache describe-cache-parameter-groups --cache-parameter-group-name ticketing-redis-params --region $REGION 2>/dev/null | grep -q "ticketing-redis-params"; then
    echo "✅ ElastiCache parameter group deleted"
    break
  fi
  echo "⏳ Still deleting... ($i/30)"
  sleep 10
done

# Delete IAM Policy
echo "Deleting IAM policy..."
POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='ticketing-message-messaging-access'].Arn" --output text 2>/dev/null || echo "")
if [ ! -z "$POLICY_ARN" ]; then
  aws iam delete-policy --policy-arn $POLICY_ARN 2>/dev/null || true
fi

# Delete NAT Gateway and release EIPs
echo "Deleting NAT Gateway and releasing EIPs..."
for NAT_ID in $(aws ec2 describe-nat-gateways --region $REGION --filter "Name=tag:Name,Values=ticketing-nat" "Name=state,Values=available,pending" --query "NatGateways[].NatGatewayId" --output text 2>/dev/null); do
  ALLOC_ID=$(aws ec2 describe-nat-gateways --region $REGION --nat-gateway-ids $NAT_ID --query "NatGateways[0].NatGatewayAddresses[0].AllocationId" --output text 2>/dev/null || echo "")
  aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID --region $REGION 2>/dev/null || true
  [ -n "$ALLOC_ID" ] && aws ec2 release-address --allocation-id $ALLOC_ID --region $REGION 2>/dev/null || true
done

# Clean up VPC (route tables, subnets, IGW, SGs) by tag Name=ticketing-vpc
VPC_ID=$(aws ec2 describe-vpcs --region $REGION --filters "Name=tag:Name,Values=ticketing-vpc" --query "Vpcs[0].VpcId" --output text 2>/dev/null || echo "")
if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
  echo "Cleaning VPC resources for $VPC_ID..."
  # Detach and delete IGW
  IGW_ID=$(aws ec2 describe-internet-gateways --region $REGION --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[0].InternetGatewayId" --output text 2>/dev/null || echo "")
  if [ -n "$IGW_ID" ] && [ "$IGW_ID" != "None" ]; then
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION 2>/dev/null || true
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION 2>/dev/null || true
  fi
  # Delete non-main route tables
  for RT in $(aws ec2 describe-route-tables --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[?Associations[?Main==`false`]].RouteTableId" --output text 2>/dev/null); do
    aws ec2 delete-route-table --route-table-id $RT --region $REGION 2>/dev/null || true
  done
  # Delete subnets
  for SUBNET in $(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[].SubnetId" --output text 2>/dev/null); do
    aws ec2 delete-subnet --subnet-id $SUBNET --region $REGION 2>/dev/null || true
  done
  # Delete security groups matching ticketing-*
  for sg_name in ticketing-alb-sg ticketing-ecs-sg ticketing-rds-sg ticketing-redis-sg; do
    SG_ID=$(aws ec2 describe-security-groups --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=$sg_name" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || echo "")
    if [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
      aws ec2 delete-security-group --group-id $SG_ID --region $REGION 2>/dev/null || true
    fi
  done
  # Finally delete VPC
  aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION 2>/dev/null || true
fi

# Delete Security Groups (must be done last after all resources are deleted)
echo "Waiting 60s for resources to fully delete before removing security groups..."
sleep 60

echo "Deleting security groups..."
for sg_name in ticketing-alb-sg ticketing-ecs-sg ticketing-rds-sg; do
  SG_ID=$(aws ec2 describe-security-groups --region $REGION --filters "Name=group-name,Values=$sg_name" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || echo "")
  if [ ! -z "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
    aws ec2 delete-security-group --group-id $SG_ID --region $REGION 2>/dev/null || true
  fi
done

# Wait for security groups to be fully deleted
echo "Waiting for security groups to be fully deleted..."
for i in {1..30}; do
  REMAINING_SGS=$(aws ec2 describe-security-groups --region $REGION --filters "Name=group-name,Values=ticketing-*" --query "SecurityGroups[].GroupName" --output text 2>/dev/null || echo "")
  if [ -z "$REMAINING_SGS" ]; then
    echo "✅ All security groups deleted"
    break
  fi
  echo "⏳ Still deleting security groups... ($i/30)"
  sleep 10
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Cleanup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  IMPORTANT: Wait 2-3 more minutes before deploying!"
echo ""
echo "AWS uses eventual consistency - some resources may still"
echo "be processing deletions in the background even though the"
echo "delete commands succeeded."
echo ""
echo "Recommended: Wait 3 minutes, then run your deployment."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
