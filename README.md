# 🎫 High-Concurrency Ticketing Platform - CQRS Architecture# High-Concurrency Ticketing Platform - CQRS Architecture

A high-performance ticketing system built with CQRS pattern, implementing read-write separation and event-driven architecture using AWS services.A high-performance ticketing system built with CQRS pattern, implementing read-write separation and event-driven architecture using AWS services.

## 📋 Table of Contents## Table of Contents

- [Architecture Overview](#architecture-overview)- [Architecture Overview](#architecture-overview)

- [Technology Stack](#technology-stack)- [Services](#services)

- [Services](#services)- [API Documentation](#api-documentation)

- [Quick Start](#quick-start)- [Deployment](#deployment)

- [API Documentation](#api-documentation)- [Troubleshooting](#troubleshooting)

- [Deployment Options](#deployment-options)

- [Troubleshooting](#troubleshooting)## Architecture Overview

---### CQRS Pattern Implementation

## 🏗️ Architecture OverviewThis system implements Command Query Responsibility Segregation (CQRS) with event-driven architecture:

### CQRS Pattern Implementation```

Ticket Purchase Request → PurchaseService (Redis seat locking + SNS event publishing)

This system implements Command Query Responsibility Segregation (CQRS) with event-driven architecture: ↓

                    Amazon SNS Topic → SQS Queue

````↓

Ticket Purchase Request → PurchaseService (Redis seat locking + SNS event publishing)                   SqsConsumer (async MySQL write)

                              ↓                              ↓

                    Amazon SNS Topic → SQS Queue                   QueryService (MySQL data read)

                              ↓```

                   SqsConsumer (async MySQL write)

                              ↓### Technology Stack

                   QueryService (MySQL data read)

```- **Java 21** + **Spring Boot 3.x**

- **MySQL 8.x** (primary data store)

### Infrastructure Components- **Redis 7.x** (seat state caching)

- **AWS SNS/SQS** (event messaging)

| Component                           | Purpose                                  | Configuration                                                                  |- **Docker** (containerization)

| ----------------------------------- | ---------------------------------------- | ------------------------------------------------------------------------------ |- **Terraform** (infrastructure as code)

| **Application Load Balancer (ALB)** | HTTP routing with path-based rules       | Routes `/purchase*`, `/query*`, `/events*` to respective services              |

| **ECS Auto Scaling**                | Dynamic task scaling based on CPU        | purchase-service: 3-6 tasks (CPU > 60%), query/consumer: 1-3 tasks (CPU > 70%) |### Service Architecture

| **MySQL (RDS Aurora)**              | Primary data persistence                 | Aurora cluster: 1 writer + 1 reader replica (db.t4g.medium)                    |

| **Redis (ElastiCache)**             | Seat state caching and distributed locks | Single-node cluster (cache.t3.small)                                           || Service             | Port | Responsibility                                          | Technologies |

| **AWS SNS/SQS**                     | Event publishing and async consumption   | SNS: ticket-events topic, SQS: ticket-sql queue                                || ------------------- | ---- | ------------------------------------------------------- | ------------ |

| **PurchaseService** | 8080 | Handle ticket purchases, seat locking, event publishing | Redis + SNS  |

---| **QueryService**    | 8081 | Provide ticket query and analytics APIs                 | MySQL + JPA  |

| **SqsConsumer**     | N/A  | Consume events and project data to MySQL                | SQS + MySQL  |

## 🔧 Technology Stack

### Infrastructure Components

- **Java 21** + **Spring Boot 3.x**

- **MySQL 8.x** (primary data store)| Component                           | Purpose                                  | Configuration                                                                  |

- **Redis 7.x** (seat state caching)| ----------------------------------- | ---------------------------------------- | ------------------------------------------------------------------------------ |

- **AWS SNS/SQS** (event messaging)| **Application Load Balancer (ALB)** | HTTP routing with path-based rules       | Routes `/purchase*`, `/query*`, `/events*` to respective services              |

- **Docker** (containerization)| **ECS Auto Scaling**                | Dynamic task scaling based on CPU        | purchase-service: 3-6 tasks (CPU > 60%), query/consumer: 1-3 tasks (CPU > 70%) |

- **Terraform** (infrastructure as code)| **MySQL (RDS Aurora)**              | Primary data persistence                 | Aurora cluster: 1 writer + 1 reader replica (db.t4g.medium)                    |

| **Redis (ElastiCache)**             | Seat state caching and distributed locks | Single-node cluster (cache.t3.small)                                           |

---| **AWS SNS/SQS**                     | Event publishing and async consumption   | SNS: ticket-events topic, SQS: ticket-sql queue                                |



## 🎯 Services**Load Balancing**: ALB distributes traffic across ECS tasks with health checks

**Auto Scaling**: Purchase service maintains 3-6 tasks (scales at CPU > 60%), Query/Consumer maintain 1-3 tasks (scale at CPU > 70%)

| Service             | Port | Responsibility                      | Key Technologies        | Main Features                                                     |**Database HA**: Aurora provides automatic failover from writer to reader replica

| ------------------- | ---- | ----------------------------------- | ----------------------- | ----------------------------------------------------------------- |

| **PurchaseService** | 8080 | Write operations - ticket purchases | Spring Boot, Redis, SNS | Redis seat locking, SNS event publishing, Input validation        |## Services

| **QueryService**    | 8081 | Read operations - ticket queries    | Spring Boot, JPA, MySQL | Multi-dimensional queries, Revenue analytics, Optimized reads     |

| **SqsConsumer**     | N/A  | Event consumption & data projection | Spring Boot, SQS, MySQL | Async processing, Transactional consistency, Dead letter handling || Service             | Port | Responsibility                      | Key Technologies        | Main Features                                                     |

| ------------------- | ---- | ----------------------------------- | ----------------------- | ----------------------------------------------------------------- |

---| **PurchaseService** | 8080 | Write operations - ticket purchases | Spring Boot, Redis, SNS | Redis seat locking, SNS event publishing, Input validation        |

| **QueryService**    | 8081 | Read operations - ticket queries    | Spring Boot, JPA, MySQL | Multi-dimensional queries, Revenue analytics, Optimized reads     |

## 🚀 Quick Start| **SqsConsumer**     | N/A  | Event consumption & data projection | Spring Boot, SQS, MySQL | Async processing, Transactional consistency, Dead letter handling |



### Prerequisites## API Documentation



- AWS CLI v2 configured with credentials**Base URL**: `http://<alb-dns-name>` (Get from: `terraform output -raw alb_dns_name`)

- Terraform 1.6+

- Docker Desktop**Complete API Reference**: See `Ticketing-System-API-Tests.postman_collection.json` for full Postman collection.

- jq (JSON processor)

### Quick Reference

### Fastest Deployment (Local)

#### Purchase Service (`/purchase/*`)

```bash

# 1. Configure AWS credentials```bash

aws configure# Purchase a ticket

POST /purchase/api/v1/tickets

# 2. Deploy infrastructureBody: {"venueId":"Venue1","eventId":"Event1","zoneId":1,"row":"A","column":"1"}

cd config/terraform

terraform init# Health check

terraform apply -auto-approveGET /purchase/health

````

# 3. Build and deploy services

cd ../scripts#### Query Service (`/query/*`)

./build-and-push.sh

```bash

# 4. Wait 3 minutes, then verify# Get all tickets

./check-infrastructure.shGET /query/api/v1/tickets

```

# Get ticket by ticket ID (UUID)

**Total Time:** ~10-15 minutesGET /query/api/v1/tickets/{ticketId}

# Example: GET /query/api/v1/tickets/5b15a8a4-1f84-44dd-8f3d-9ae9de6e6d1b

---

# Get ticket count for event

## 📖 API DocumentationGET /query/api/v1/tickets/count/{eventId}

# Example: GET /query/api/v1/tickets/count/Event1

**Base URL**: `http://<alb-dns-name>` (Get from: `terraform output -raw alb_dns_name`)

# Get revenue for venue and event

### Purchase Service (`/purchase/*`)GET /query/api/v1/tickets/revenue/{venueId}/{eventId}

# Example: GET /query/api/v1/tickets/revenue/Venue1/Event1

```````bash

# Purchase a ticket# Health check

POST /purchase/api/v1/ticketsGET /query/health

Body: {"venueId":"Venue1","eventId":"Event1","zoneId":1,"row":"A","column":"1"}```



# Health check#### MQ Projection Service (`/events/*`)

GET /purchase/health

``````bash

# Health check (monitoring only)

### Query Service (`/query/*`)GET /events/health

```````

````bash

# Get all tickets### Testing Example

GET /query/api/v1/tickets

```bash

# Get ticket by ticket ID (UUID)# Get ALB URL

GET /query/api/v1/tickets/{ticketId}ALB_URL=$(cd config/terraform && terraform output -raw alb_dns_name)



# Get ticket count for event# Purchase a ticket

GET /query/api/v1/tickets/count/{eventId}curl -X POST http://$ALB_URL/purchase/api/v1/tickets \

  -H "Content-Type: application/json" \

# Get revenue for venue and event  -d '{"venueId":"Venue1","eventId":"Event1","zoneId":1,"row":"A","column":"1"}'

GET /query/api/v1/tickets/revenue/{venueId}/{eventId}

# Query all tickets (wait 2s for async processing)

# Health checksleep 2 && curl http://$ALB_URL/query/api/v1/tickets

GET /query/health```

````

## Deployment

### MQ Projection Service (`/events/*`)

> 🎓 **Using AWS Learner Lab?** See [AWS-LEARNER-LAB-GUIDE.md](AWS-LEARNER-LAB-GUIDE.md) for special instructions!

````bash

# Health check (monitoring only)### Prerequisites

GET /events/health

```- AWS CLI v2 configured with credentials

- Terraform 1.6+

### Quick Test- Docker Desktop

- jq (JSON processor)

```bash

# Get ALB URL### Deployment Options

ALB_URL=$(cd config/terraform && terraform output -raw alb_dns_name)

You can deploy this system in multiple ways:

# Purchase a ticket

curl -X POST http://$ALB_URL/purchase/api/v1/tickets \1. **GitHub Actions CI/CD** (Recommended): Automated deployment with 5 workflow options

  -H "Content-Type: application/json" \2. **Local Deployment**: Using terminal commands for testing

  -d '{"venueId":"Venue1","eventId":"Event1","zoneId":1,"row":"A","column":"1"}'

#### GitHub Actions Workflows

# Query all tickets (wait 2s for async processing)

sleep 2 && curl http://$ALB_URL/query/api/v1/tickets| Workflow                      | Purpose            | Use Case                     |

```| ----------------------------- | ------------------ | ---------------------------- |

| 🚀 **full-deployment**        | Deploy everything  | Fresh start, complete setup  |

**Complete API Reference**: See `Ticketing-System-API-Tests.postman_collection.json` for full Postman collection.| 🏗️ **infrastructure-only**    | AWS resources only | Test infra changes           |

| 🐳 **services-only**          | Update containers  | Code changes, quick updates  |

---| 🗑️ **destroy-infrastructure** | Clean shutdown     | Proper resource cleanup      |

| 🧹 **force-cleanup**          | Nuclear cleanup    | When state is lost/corrupted |

## 🎯 Deployment Options

**🔄 Auto-Import Feature (NEW!):**

You have **two independent deployment methods**:

- ✅ **Automatically imports existing resources** if deployment fails

### Option 1: Local Deployment (Recommended)- ✅ **Retries deployment** after import

- ✅ **Recovers from partial deployments** seamlessly

**Best for:** Development, AWS Learner Lab, Fast Iterations- ✅ Perfect for AWS Learner Lab & development environments

- 📖 See [AUTO-IMPORT-EXPLAINED.md](AUTO-IMPORT-EXPLAINED.md) for details

#### Step 1: Configure Terraform

**Smart State Management:**

```bash

cd config/terraform- ✅ State saved AFTER successful deployment (for destroy)

cp terraform.tfvars.template terraform.tfvars- ✅ State restored ONLY for destroy operations

# Edit terraform.tfvars with your AWS account details- ✅ Fresh deployments bypass cache (avoid conflicts)

```- ✅ Auto-fallback to cleanup script if state missing



#### Step 2: Configure AWS Credentials---



```bash## Local Deployment (For Testing)

# For AWS Learner Lab users:

aws configure set aws_access_key_id YOUR_ACCESS_KEY### Deployment Steps

aws configure set aws_secret_access_key YOUR_SECRET_KEY

aws configure set aws_session_token YOUR_SESSION_TOKEN#### 1. Configure Terraform Variables

aws configure set region us-west-2

```bash

# Verifycd config/terraform

aws sts get-caller-identitycp terraform.tfvars.template terraform.tfvars

```nano terraform.tfvars  # Edit: aws_region, aws_account_id, project_name, environment

````

#### Step 3: Deploy Infrastructure

#### 2. Configure AWS Credentials

````bash

cd config/terraform```bash

terraform init# For AWS Learner Lab users:

terraform apply -auto-approveaws configure set aws_access_key_id YOUR_ACCESS_KEY

```aws configure set aws_secret_access_key YOUR_SECRET_KEY

aws configure set aws_session_token YOUR_SESSION_TOKEN

**Creates**: VPC, ECR (3 repos), RDS Aurora MySQL, ElastiCache Redis, SNS, SQS, ALB, ECS Fargate, Secrets Manager, CloudWatchaws configure set region us-west-2



**Expected Time**: ~10-15 minutes# Verify

aws sts get-caller-identity

#### Step 4: Build & Deploy Services```



```bash#### 3. Grant Script Permissions

cd ../scripts

chmod +x build-and-push.sh```bash

./build-and-push.shchmod +x config/scripts/build-and-push.sh

```chmod +x config/scripts/check-infrastructure.sh

````

#### Step 5: Verify Deployment

#### 4. Create Infrastructure

````bash

# Wait 3-5 minutes after build-and-push.sh completes```bash

chmod +x check-infrastructure.shcd config/terraform

./check-infrastructure.shterraform init

terraform apply -auto-approve

# Check service health endpoints```

ALB_URL=$(cd ../terraform && terraform output -raw alb_dns_name)

curl http://$ALB_URL/purchase/health**Creates**: VPC, ECR (3 repos), RDS Aurora MySQL, ElastiCache Redis, SNS, SQS, ALB, ECS Fargate, Secrets Manager, CloudWatch

curl http://$ALB_URL/query/health

curl http://$ALB_URL/events/health** Expected Time**: ~10-15 minutes (RDS Aurora and ElastiCache initialization are the slowest)

````

#### 5. Build & Deploy Services

#### Update Services (After Code Changes)

```````bash

```bashcd config/scripts

# Rebuild and redeploy./build-and-push.sh

cd config/scripts```

./build-and-push.sh

```---



#### Cleanup### Deployment Flow



```bash```

# Option 1: Terraform destroy (if state exists)terraform.tfvars → aws configure → chmod +x → terraform apply → ./build-and-push.sh

cd config/terraform```

terraform destroy -auto-approve

---

# Option 2: Force cleanup (works without state)

cd config/scripts### Verification

./cleanup-aws-resources.sh

``````bash

# Wait 3-5 minutes after build-and-push.sh completes, then verify:

---./config/scripts/check-infrastructure.sh



### Option 2: GitHub Actions CI/CD (Optional)# Check service health endpoints

ALB_URL=$(cd config/terraform && terraform output -raw alb_dns_name)

**Best for:** Demonstrations, Portfolio, Automated Deploymentscurl http://$ALB_URL/purchase/health

curl http://$ALB_URL/query/health

#### Setup (One-time)curl http://$ALB_URL/events/health

```````

1. **Add GitHub Secrets:**

   - Go to: Repository → Settings → Secrets → Actions**Note**: If health checks fail initially, wait another 2-3 minutes for containers to fully initialize.

   - Add the following secrets:

     - `AWS_ACCESS_KEY_ID`### Update Services

     - `AWS_SECRET_ACCESS_KEY`

     - `AWS_SESSION_TOKEN````bash

     - `AWS_ACCOUNT_ID` (12-digit number)# After making code changes, rebuild and redeploy

cd config/scripts

2. **Workflow File:**./build-and-push.sh

   - Already committed at `.github/workflows/deploy.yml````

#### Usage**Note**: The script uses the current git commit SHA as the image tag. If you want to track changes, commit before deploying:

1. Go to: **GitHub → Actions → "Deploy Ticketing System"**```bash

2. Click **"Run workflow"** dropdowncd config/scripts && ./build-and-push.sh

3. Select deployment option:```

   - **full-deployment**: Complete infrastructure + services (15-20 min)

   - **infrastructure-only**: AWS resources only (10-15 min)### Cleanup

   - **services-only**: Update containers only (3-5 min)

   - **destroy-infrastructure**: Clean shutdown```bash

   - **force-cleanup**: Emergency cleanup (works without state)cd config/terraform

4. Click green **"Run workflow"** buttonterraform destroy -auto-approve

````

#### Workflow Options Explained

---

| Option                      | What It Does                 | When To Use                  | Duration  |

| --------------------------- | ---------------------------- | ---------------------------- | --------- |## CI/CD Pipeline (Optional)

| **full-deployment**         | Infrastructure + Services    | Fresh start, complete demo   | 15-20 min |

| **infrastructure-only**     | Just AWS resources           | Test infra changes           | 10-15 min |### Overview

| **services-only**           | Just update containers       | Code changes only            | 3-5 min   |

| **destroy-infrastructure**  | Proper cleanup with state    | End of session               | 5-10 min  |This project includes a **GitHub Actions CI/CD pipeline** for automated build and deployment. The pipeline provides three deployment modes and is triggered **manually via GitHub's web interface**, not from the terminal.

| **force-cleanup**           | Emergency cleanup (no state) | State lost/corrupted         | 3-5 min   |

**Important**: Local deployment via `terraform apply` + `./build-and-push.sh` remains the **recommended approach for AWS Learner Lab** due to session time limits. The CI/CD pipeline is provided for **demonstration and learning purposes**.

#### Benefits

### Pipeline Modes

✅ **Infrastructure as Code**: Terraform manages all AWS resources

✅ **Automated Testing**: Maven runs unit tests before deployment  | Mode                    | Description                                                       | Duration  | Use Case                              |

✅ **Container Orchestration**: Docker + ECS for consistent environments  | ----------------------- | ----------------------------------------------------------------- | --------- | ------------------------------------- |

✅ **Zero-Downtime Deployment**: Rolling updates with health checks  | **infrastructure-only** | Run Terraform to create/update AWS infrastructure                 | 10-15 min | Initial setup, infrastructure changes |

✅ **Traceability**: Git SHA tags track deployed versions  | **services-only**       | Build & deploy Docker images only (assumes infrastructure exists) | 3-5 min   | Code updates, bug fixes               |

✅ **Cost Awareness**: Manual triggers prevent unnecessary AWS charges| **full-deployment**     | Run both Terraform and service deployment                         | 15-20 min | Complete automation demo, portfolio   |



---### Setup (One-time)



## 🔍 Deployment Comparison#### 1. Add GitHub Secrets



| Aspect             | Local Deployment             | GitHub Actions CI/CD                  |Navigate to: **Repository → Settings → Secrets and variables → Actions → New repository secret**

| ------------------ | ---------------------------- | ------------------------------------- |

| **Trigger**        | Terminal commands            | GitHub web interface                  |Add these secrets (get from AWS Learner Lab):

| **Speed**          | Fast (10-15 min)             | Slower (15-20 min)                    |

| **AWS Credits**    | Moderate usage               | Higher usage (clean builds)           |```

| **State Storage**  | Local `terraform.tfstate`    | GitHub Actions cache                  |AWS_ACCESS_KEY_ID        = <your-access-key>

| **Best For**       | Development, AWS Learner Lab | Demos, portfolio, team collaboration  |AWS_SECRET_ACCESS_KEY    = <your-secret-key>

| **Control**        | Immediate execution          | Requires web browser                  |AWS_SESSION_TOKEN        = <your-session-token>

| **Learning Value** | Practical deployment         | DevOps best practices                 |AWS_ACCOUNT_ID           = <your-12-digit-account-id>

````

---

**Getting AWS Credentials from Learner Lab**:

## 🛠️ Troubleshooting

1. Start AWS Learner Lab session

### Service Health Check Failures2. Click **"AWS Details"** button

3. Click **"Show"** next to AWS CLI credentials

````bash4. Copy the values to GitHub Secrets

# Wait 2-3 minutes for containers to fully start

sleep 180#### 2. Commit Workflow File



# Check infrastructure statusThe workflow file has already been created at `.github/workflows/deploy.yml`. Commit and push it:

cd config/scripts

./check-infrastructure.sh```bash

git add .github/workflows/deploy.yml

# Check CloudWatch logsgit commit -m "Add CI/CD pipeline"

aws logs tail /ecs/purchase-service --followgit push origin main

aws logs tail /ecs/query-service --follow```

aws logs tail /ecs/mq-projection-service --follow

```### How to Trigger CI/CD Deployment



### "Resource Already Exists" Errors**⚠️ Important**: The workflow does **NOT** run automatically on `git push`. You must trigger it manually via GitHub's web interface.



If Terraform fails with "already exists" errors:#### Step-by-Step Trigger Process



```bash**Step 1: Navigate to GitHub Actions** (Web Browser)

# Option 1: Wait for AWS eventual consistency (3 minutes)

sleep 180 && cd config/terraform && terraform apply -auto-approve```

1. Open browser and go to: https://github.com/YOUR_USERNAME/YOUR_REPO_NAME

# Option 2: Force cleanup and redeploy2. Click the "Actions" tab at the top of the page

cd config/scripts```

./cleanup-aws-resources.sh

sleep 180  # Wait for AWS to propagate deletions**Step 2: Select Workflow**

cd ../terraform

terraform apply -auto-approve```

```3. In the left sidebar, click "Deploy Ticketing System"

4. You'll see a "Run workflow" dropdown button on the right side

### Database Connection Errors```



```bash**Step 3: Configure and Run**

# Verify RDS cluster status

aws rds describe-db-clusters --db-cluster-identifier ticketing-aurora --region us-west-2```

5. Click the "Run workflow" dropdown button

# Check Secrets Manager for correct credentials6. Select branch: main

aws secretsmanager get-secret-value --secret-id ticketing-prod/mysql/admin --region us-west-27. Choose deployment action from dropdown:

   - infrastructure-only: Creates AWS resources (VPC, RDS, Redis, ECS, ALB)

# Ensure security groups allow ECS → RDS communication   - services-only: Builds Docker images and deploys to ECS ← Recommended

aws ec2 describe-security-groups --region us-west-2 --filters Name=tag:Name,Values=ticketing-*   - full-deployment: Runs both infrastructure and services

```8. Click green "Run workflow" button

````

### Message Processing Issues

**Step 4: Monitor Progress**

````bash

# Check SQS queue has messages```

aws sqs get-queue-attributes --queue-url $(aws sqs get-queue-url --queue-name ticket-sql-queue --query QueueUrl --output text --region us-west-2) --attribute-names ApproximateNumberOfMessages --region us-west-29. Click on the running workflow (appears at top of page)

10. Watch real-time logs for each job:

# Verify SNS topic subscriptions    - build: Maven compilation + unit tests

aws sns list-subscriptions --region us-west-2    - terraform-infrastructure: Terraform apply (if selected)

    - deploy-services: Docker build + ECR push + ECS update

# Review CloudWatch logs for SQS consumer```

aws logs tail /ecs/mq-projection-service --follow --region us-west-2

```**Step 5: View Results**



### GitHub Actions Failures```

11. Once complete, check the "Summary" tab for:

**AWS Credentials Error:**    - Deployment status

- Update GitHub Secrets with fresh AWS Learner Lab credentials (they expire after 4 hours)    - Image tags (git commit SHA)

- Verify secret names match exactly: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `AWS_ACCOUNT_ID`    - ALB URL

    - Health check results

**"Run workflow button not visible":**```

- Ensure `.github/workflows/deploy.yml` is pushed to your branch

- Refresh GitHub page and wait 1-2 minutes for GitHub to detect workflow### Visual Workflow



**Terraform State Issues:**```

- First time running: Expected - workflow will create new stateGitHub Web UI (Browser)

- Cache expired: Run "force-cleanup" then "full-deployment"         ↓

- State corruption: Delete cache in GitHub Actions and re-run "full-deployment"   [Run workflow] button

         ↓

### Monitoring┌────────────────────────────────┐

│  Select Deployment Mode        │

- **CloudWatch Logs**: `/ecs/{service-name}` log groups│  ○ infrastructure-only          │

- **Health Checks**: `curl http://<alb>/purchase/health`│  ● services-only (selected)    │

- **Infrastructure Script**: `./config/scripts/check-infrastructure.sh`│  ○ full-deployment             │

└────────────┬───────────────────┘

---             ↓

┌────────────────────────────────┐

## 📁 Project Structure│ Job 1: Build Java Services     │

│ - Maven compile & test         │

```│ - Upload JAR artifacts         │

Ticketing-Cloud-Deployment/└────────────┬───────────────────┘

├── README.md                          # This file             ↓

├── .github/workflows/┌────────────────────────────────┐

│   └── deploy.yml                     # CI/CD pipeline│ Job 2: Terraform (conditional) │

├── config/│ - Restore state from cache     │

│   ├── terraform/                     # Infrastructure code│ - terraform plan & apply       │

│   │   ├── main.tf                    # Main infrastructure└────────────┬───────────────────┘

│   │   ├── variables.tf               # Configuration             ↓

│   │   ├── outputs.tf                 # Outputs (ALB URL, etc.)┌────────────────────────────────┐

│   │   ├── provider.tf                # AWS provider│ Job 3: Deploy Services         │

│   │   ├── terraform.tfvars.template  # Config template│ - Build Docker images          │

│   │   └── modules/                   # Infrastructure modules│ - Push to ECR                  │

│   │       ├── alb/                   # Application Load Balancer│ - Update ECS tasks             │

│   │       ├── ecr/                   # Container Registry│ - Run health checks            │

│   │       ├── ecs/                   # ECS Fargate└────────────────────────────────┘

│   │       ├── elasticache/           # Redis```

│   │       ├── logging/               # CloudWatch

│   │       ├── messaging/             # SNS/SQS### Typical Workflows

│   │       ├── network/               # VPC

│   │       └── rds/                   # Aurora MySQL#### For AWS Learner Lab Users (Recommended):

│   └── scripts/

│       ├── build-and-push.sh          # Local deployment```bash

│       ├── cleanup-aws-resources.sh   # Manual cleanup# 1. Deploy infrastructure locally (once per session)

│       └── check-infrastructure.sh    # Health checkscd config/terraform

├── PurchaseService/                   # Write serviceterraform apply -auto-approve

├── QueryService/                      # Read service

└── RabbitCombinedConsumer/            # Event consumer# 2. For code updates, use CI/CD "services-only" mode

```#    Go to: GitHub → Actions → Run workflow → Select "services-only"

#    This rebuilds Docker images and redeploys to ECS (3-5 min)

---

# 3. For quick iterations during development, use local script

## 🎓 Learning Resourcescd config/scripts

./build-and-push.sh

- **GitHub Actions Docs**: https://docs.github.com/actions```

- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

- **Docker Multi-Stage Builds**: https://docs.docker.com/build/building/multi-stage/**Why this approach?**

- **CQRS Pattern**: https://martinfowler.com/bliki/CQRS.html

- **AWS ECS Best Practices**: https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/intro.html- AWS Learner Lab sessions expire after 4 hours

- Local Terraform is faster and more reliable for infrastructure setup

---- CI/CD demonstrates DevOps skills without consuming session time on infrastructure recreation

- Local script is fastest for frequent code changes

## 📝 Notes

#### For Portfolio/Demo Purposes:

### AWS Learner Lab Users

```bash

- **Session Timeout**: AWS Learner Lab sessions expire after 4 hours# Show complete automated infrastructure deployment

- **Recommended Approach**: Use local deployment for infrastructure, optionally use CI/CD for demonstrations# Go to: GitHub → Actions → Run workflow → Select "full-deployment"

- **Credentials**: Must update AWS CLI credentials each session

- **Cleanup**: Always run cleanup before session ends to avoid resource charges# This demonstrates:

# - Infrastructure as Code (Terraform)

### Production Considerations# - Automated build pipeline (Maven)

# - Container orchestration (Docker + ECS)

If deploying to a real AWS account (not Learner Lab):# - Zero-downtime deployment

# - Health monitoring

1. **Use S3 Backend for Terraform State**:```



```hcl### Comparison: Local vs CI/CD

# config/terraform/backend.tf

terraform {| Aspect             | Local Deployment             | GitHub Actions CI/CD                                 |

  backend "s3" {| ------------------ | ---------------------------- | ---------------------------------------------------- |

    bucket         = "your-terraform-state-bucket"| **Trigger**        | Terminal commands            | GitHub web interface                                 |

    key            = "ticketing/terraform.tfstate"| **Infrastructure** | `terraform apply` (local)    | Terraform in GitHub Actions                          |

    region         = "us-west-2"| **Speed**          | Fast (5-10 min total)        | Slow (15-20 min full) / Fast (3-5 min services-only) |

    encrypt        = true| **AWS Credits**    | Moderate usage               | Higher usage (clean builds)                          |

    dynamodb_table = "terraform-state-lock"| **State Storage**  | Local `terraform.tfstate`    | GitHub Actions cache                                 |

  }| **Best For**       | Development, AWS Learner Lab | Demos, portfolio, team collaboration                 |

}| **Control**        | Immediate execution          | Requires web browser                                 |

```| **Learning Value** | Practical deployment         | DevOps best practices                                |



2. **Enable Auto-Scaling Alarms**:### Pipeline Architecture Details

   - CPU-based scaling (already configured)

   - Memory-based scaling#### Terraform State Management

   - Request count-based scaling

The CI/CD pipeline uses **GitHub Actions cache** for Terraform state storage:

3. **Add Monitoring & Alerting**:

   - CloudWatch Dashboards**Advantages**:

   - SNS alerts for service failures

   - X-Ray tracing for performance analysis- ✅ No S3 bucket setup required

- ✅ Zero additional AWS costs

4. **Implement Security Best Practices**:- ✅ Suitable for learning/demo projects

   - Enable AWS WAF on ALB- ✅ Simple configuration

   - Use AWS Secrets Manager rotation

   - Enable VPC Flow Logs**Limitations**:

   - Configure AWS GuardDuty

- ⚠️ Cache expires after 7 days of inactivity

---- ⚠️ No state locking (avoid concurrent workflow runs)

- ⚠️ Not recommended for production (use S3 backend with DynamoDB locking instead)

## 📄 License

**State Recovery**: If cache expires and state is lost:

This project is for educational purposes.

```bash

---# Option 1: Run Terraform locally to recreate state

cd config/terraform

## 🤝 Contributingterraform apply



This is a course project. For questions or suggestions, please open an issue.# Option 2: Re-run "infrastructure-only" mode in GitHub Actions

# The workflow will recreate infrastructure and cache new state

---

# Option 3: Import existing resources (advanced)

## ✨ Summaryterraform import aws_vpc.main vpc-xxxxx

terraform import aws_ecs_cluster.main ticketing-prod-cluster

**Your deployment is now simplified to:**# ... repeat for all resources

````

1. **Local:** `terraform apply` → `./build-and-push.sh` ✅

2. **CI/CD:** GitHub Actions → Run workflow → Select option ✅#### Image Tagging Strategy

3. **Cleanup:** `./cleanup-aws-resources.sh` or GitHub workflow ✅

The pipeline uses **Git commit SHA** for image tags:

**That's it!** Simple, clean, and production-ready.

```bash
# Automatically tagged in CI/CD
docker tag purchase-service:latest <ecr-url>/purchase-service:a1b2c3d4
docker tag purchase-service:latest <ecr-url>/purchase-service:latest

# Benefits:
# - Track exactly which code version is deployed
# - Enable rollbacks to specific commits
# - Audit trail for deployments
```

### Demo Script for Presentations

When demonstrating the CI/CD pipeline to professors/reviewers:

#### Part 1: Show Local Deployment Still Works (2 min)

```bash
# Terminal demonstration
echo "=== Traditional Local Deployment ==="
cd config/scripts
./build-and-push.sh

# Talking point:
# "This is our traditional deployment method. Developers can still use this
#  for quick iterations. Now let me show you the automated CI/CD pipeline..."
```

#### Part 2: Trigger CI/CD Workflow (1 min)

1. Open browser → GitHub repository
2. Navigate to **Actions** tab
3. Click **Deploy Ticketing System** (left sidebar)
4. Click **Run workflow** dropdown (right side)
5. Select: **services-only** (fastest for demo)
6. Click green **Run workflow** button

**Talking point**:

> "The pipeline is triggered manually here for cost control, but in production this would run automatically on every push to main. Let me show you each stage..."

#### Part 3: Walk Through Pipeline Stages (3 min)

Click on the running workflow to show live logs:

**Stage 1: Build & Test**

```
🔨 Building PurchaseService...
🔨 Building QueryService...
🧪 Running unit tests...
✅ All tests passed!
```

**Talking point**: "First, we compile all microservices and run unit tests to catch bugs before deployment."

**Stage 2: Build Docker Images**

```
🐳 Building and pushing PurchaseService...
🐳 Building and pushing QueryService...
✅ Images pushed to ECR!
```

**Talking point**: "Next, we containerize each service and push to AWS ECR for deployment."

**Stage 3: Deploy to ECS**

```
♻️ Updating ECS services...
⏳ Waiting for services to stabilize...
🏥 Running health checks...
✅ All services healthy!
```

**Talking point**: "Finally, we update ECS to pull new images. This is zero-downtime deployment using rolling updates."

#### Part 4: Show Results (1 min)

Open the **Summary** tab and point out:

- ✅ All checks passed
- 🏷️ Image tag: `abc123def` (git commit SHA)
- 🔗 ALB URL with health check commands
- 📊 Deployment duration

**Talking point**:

> "This workflow demonstrates industry-standard DevOps practices: automated testing, containerization, and infrastructure as code. The entire process is tracked, auditable, and repeatable."

### Troubleshooting CI/CD

**"Run workflow button not visible"**

- Ensure `.github/workflows/deploy.yml` is pushed to `main` branch
- Check file is in `.github/workflows/` directory (not `github/workflows`)
- Refresh GitHub page and wait 1-2 minutes for GitHub to detect workflow

**"Workflow doesn't have workflow_dispatch trigger"**

- Verify YAML has `on: workflow_dispatch:` section at the top
- Check YAML indentation is correct (use spaces, not tabs)
- Commit and push any changes to the workflow file

**"AWS credentials error during workflow"**

- Update GitHub Secrets with fresh AWS Learner Lab credentials
- Verify secret names match exactly: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `AWS_ACCOUNT_ID`
- Test credentials work locally: `aws sts get-caller-identity`
- AWS Learner Lab credentials expire after 4 hours - refresh them

**"Terraform state not found"**

- First time running: Expected - workflow will create new state
- Cache expired: Run Terraform locally first or select "infrastructure-only" mode
- State corruption: Delete cache and re-run "infrastructure-only" mode

**"ECS service not found"**

- Infrastructure doesn't exist yet
- Run "infrastructure-only" or "full-deployment" mode first
- Or deploy infrastructure locally: `cd config/terraform && terraform apply`

**"Docker build timeout or failure"**

- Maven dependencies may take long to download on first build
- Retry workflow - subsequent runs will use cached dependencies
- Check CloudWatch Logs for detailed error messages

**"Health checks failing after deployment"**

- Wait an additional 2-3 minutes for containers to fully start
- Check ECS task logs in CloudWatch for application errors
- Verify security groups allow ALB → ECS communication
- Ensure RDS and Redis are accessible from ECS tasks

### Best Practices

#### For AWS Learner Lab Environment

**Recommended Workflow**:

1. **Infrastructure**: Deploy locally with `terraform apply` (once per session)
2. **Development**: Use local `./build-and-push.sh` for rapid iterations
3. **Demonstration**: Use GitHub Actions "services-only" for showing CI/CD to reviewers
4. **Documentation**: Include "full-deployment" workflow screenshot in project portfolio

**Why this hybrid approach?**

- ⏱️ Learner Lab sessions are time-limited (4 hours)
- 💰 Minimize AWS credit consumption
- 🚀 Faster development cycle with local deployment
- 🎓 Still demonstrates CI/CD knowledge for educational purposes
- 🔄 Flexibility to use either method based on situation

#### For Production Projects

If deploying to a real AWS account (not Learner Lab):

1. **Use S3 Backend for Terraform State**:

```hcl
# config/terraform/backend.tf
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "ticketing/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

2. **Enable Automatic Triggers**:

```yaml
# .github/workflows/deploy.yml
on:
  push:
    branches: [main] # Auto-deploy on push
  workflow_dispatch: # Keep manual trigger option
```

3. **Add Approval Gates**:

```yaml
environment:
  name: production
  url: ${{ steps.deploy.outputs.url }}
  # Requires manual approval in GitHub Settings
```

4. **Implement Blue-Green Deployment**:

- Use ECS task set for blue-green deployments
- Route 10% traffic to new version first
- Gradually shift traffic after health checks pass

### CI/CD Benefits Demonstrated

This CI/CD implementation showcases:

✅ **Infrastructure as Code**: Terraform manages all AWS resources  
✅ **Automated Testing**: Maven runs unit tests before deployment  
✅ **Container Orchestration**: Docker + ECS for consistent environments  
✅ **Zero-Downtime Deployment**: Rolling updates with health checks  
✅ **Traceability**: Git SHA tags track deployed versions  
✅ **Flexibility**: Multiple deployment modes for different scenarios  
✅ **Cost Awareness**: Manual triggers prevent unnecessary AWS charges  
✅ **Industry Standards**: GitHub Actions, Docker, Terraform best practices

### Additional Resources

- **GitHub Actions Docs**: https://docs.github.com/actions
- **Terraform Best Practices**: https://www.terraform-best-practices.com
- **ECS Blue-Green Deployment**: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-type-bluegreen.html
- **Docker Multi-Stage Builds**: https://docs.docker.com/build/building/multi-stage/

---

## Troubleshooting

### Common Issues

**Service Health Check Failures**

- Verify AWS credentials: `aws sts get-caller-identity`
- Check CloudWatch logs for error messages
- Ensure security groups allow ALB → ECS communication

**Database Connection Errors**

- Verify RDS cluster status in AWS Console
- Check Secrets Manager for correct credentials
- Confirm VPC and subnet configuration

**Message Processing Issues**

- Check SQS queue has messages: `aws sqs get-queue-attributes`
- Review CloudWatch logs for SQS consumer errors
- Verify SNS topic subscriptions exist

**Terraform Errors - "Resource Already Exists"**

If you see errors like:

```
Error: creating ECS Cluster: ResourceAlreadyExistsException
Error: creating RDS Cluster: DBClusterAlreadyExistsFault
Error: creating Target Group: DuplicateTargetGroupName
```

**✅ Solution**: The CI/CD pipeline now has **Auto-Import** feature!

1. **First Time**: Just run the workflow again - it will automatically import existing resources
2. **Persistent Issues**: Use the `force-cleanup` workflow action to delete all resources first
3. **Manual Import**: Run `./config/scripts/test-imports.sh` to test import commands locally

📖 See [AUTO-IMPORT-EXPLAINED.md](AUTO-IMPORT-EXPLAINED.md) for technical details.

**Terraform State Issues**

```bash
# If state is corrupted or lost
cd config/terraform

# Option 1: Refresh state from AWS
terraform refresh

# Option 2: Import existing resources
terraform import 'module.ecr.aws_ecr_repository.repos["purchase-service"]' purchase-service
# ... (see COMPLETE-IMPORT-LIST.md for all resources)

# Option 3: Clean start (⚠️ deletes everything!)
./config/scripts/cleanup-aws-resources.sh
```

**GitHub Actions Failures**

```bash
# Check workflow logs in: GitHub → Actions → <failed-run>

# Common fixes:
1. Update AWS credentials in GitHub Secrets (they expire in Learner Lab)
2. Wait for previous workflow to complete before running new one
3. Use "force-cleanup" if resources are stuck in bad state
4. Check CloudWatch Logs for application errors
```

### Monitoring

- **CloudWatch Logs**: `/ecs/{service-name}` log groups
- **Health Checks**: `curl http://<alb>/purchase/health`
- **Infrastructure Script**: `./config/scripts/check-infrastructure.sh`
- **Import Test**: `./config/scripts/test-imports.sh` (test resource imports locally)

### Getting Help

1. **Check Logs**:

   ```bash
   # ECS task logs
   aws logs tail /ecs/purchase-service --follow

   # Recent deployment errors
   cd config/terraform && terraform show
   ```

2. **Verify Resources**:

   ```bash
   ./config/scripts/check-infrastructure.sh
   ```

3. **Test Imports**:

   ```bash
   chmod +x config/scripts/test-imports.sh
   ./config/scripts/test-imports.sh
   ```

4. **Documentation**:
   - [AWS Learner Lab Guide](AWS-LEARNER-LAB-GUIDE.md)
   - [Auto-Import Documentation](AUTO-IMPORT-EXPLAINED.md)
   - [Complete Import Resource List](COMPLETE-IMPORT-LIST.md)
