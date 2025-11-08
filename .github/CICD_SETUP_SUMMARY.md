# CI/CD Setup Summary

## What Was Implemented

### 1. GitHub Actions Workflow File Created
**Location**: `.github/workflows/deploy.yml`

This workflow provides **three deployment modes**:
- **infrastructure-only**: Run Terraform to create AWS infrastructure (10-15 min)
- **services-only**: Build & deploy Docker images only (3-5 min) ← Recommended for Learner Lab
- **full-deployment**: Both infrastructure + services (15-20 min)

### 2. Hybrid Deployment Model

Both deployment methods coexist independently:

```
┌─────────────────────────┐     ┌──────────────────────────┐
│   Local Deployment      │     │  GitHub Actions CI/CD    │
│                         │     │                          │
│  - Terminal commands    │     │  - Web UI trigger        │
│  - Local state file     │     │  - Cached state          │
│  - Fast iterations      │     │  - Automated pipeline    │
│  - Recommended for dev  │     │  - Good for demos        │
└───────────┬─────────────┘     └────────────┬─────────────┘
            │                                 │
            └────────→  Same AWS Infrastructure  ←─────────┘
```

### 3. Pipeline Stages

```
GitHub Web UI → Manual Trigger
       ↓
┌──────────────────────────────────┐
│ Job 1: Build Java Services       │
│ - Maven compile & package        │
│ - Run unit tests                 │
│ - Upload JAR artifacts           │
└───────────────┬──────────────────┘
                ↓
┌──────────────────────────────────┐
│ Job 2: Terraform (conditional)   │
│ - Restore state from cache       │
│ - terraform plan & apply         │
│ - Export outputs (ALB DNS, etc)  │
└───────────────┬──────────────────┘
                ↓
┌──────────────────────────────────┐
│ Job 3: Deploy Services           │
│ - Build Docker images            │
│ - Push to ECR                    │
│ - Update ECS tasks               │
│ - Run health checks              │
└──────────────────────────────────┘
```

## How to Use

### Setup (One-time)

1. **Add GitHub Secrets** (Repository → Settings → Secrets and variables → Actions):
   ```
   AWS_ACCESS_KEY_ID
   AWS_SECRET_ACCESS_KEY
   AWS_SESSION_TOKEN
   AWS_ACCOUNT_ID
   ```

2. **Commit workflow file**:
   ```bash
   git add .github/workflows/deploy.yml
   git add README.md
   git commit -m "Add CI/CD pipeline with hybrid deployment model"
   git push origin main
   ```

### Daily Usage

#### For Development (Recommended):
```bash
# Deploy infrastructure once
cd config/terraform && terraform apply -auto-approve

# Quick service updates
cd config/scripts && ./build-and-push.sh
```

#### For Demonstrations:
```
1. Go to: https://github.com/YOUR_USERNAME/YOUR_REPO/actions
2. Click: "Deploy Ticketing System"
3. Click: "Run workflow" dropdown
4. Select: "services-only" (fastest)
5. Click: Green "Run workflow" button
6. Watch: Real-time logs as pipeline executes
```

## Key Features

### 1. Manual Trigger Only
- Workflow uses `workflow_dispatch` (manual trigger)
- Won't run automatically on `git push` (saves AWS credits)
- Perfect for AWS Learner Lab with time-limited sessions

### 2. Terraform State Caching
- Uses GitHub Actions cache (not S3)
- Zero additional AWS costs
- Cache expires after 7 days of inactivity
- Good for learning projects

### 3. Image Tagging Strategy
- Automatically tags images with Git commit SHA
- Example: `purchase-service:a1b2c3d4`
- Enables version tracking and rollbacks

### 4. Conditional Job Execution
- Jobs only run when needed based on selected mode
- Saves time and resources
- Flexible deployment options

## Comparison Matrix

| Feature | Local Deployment | CI/CD (services-only) | CI/CD (full-deployment) |
|---------|------------------|----------------------|-------------------------|
| Trigger | Terminal | GitHub UI | GitHub UI |
| Infrastructure | Local Terraform | Skipped | Terraform in pipeline |
| Speed | 5-10 min | 3-5 min | 15-20 min |
| State | Local file | GitHub cache | GitHub cache |
| Best For | Development | Code updates | Demos/Portfolio |
| AWS Credits | Moderate | Low | High |

## Demonstration Script

### For 5-Minute Demo:

1. **Show local deployment** (30 sec)
   ```bash
   cd config/scripts && ./build-and-push.sh
   ```
   *"This is our traditional local deployment method for quick iterations."*

2. **Navigate to GitHub Actions** (30 sec)
   - Open browser → Repository → Actions tab
   *"Now let me show you our automated CI/CD pipeline."*

3. **Trigger workflow** (1 min)
   - Click "Run workflow" → Select "services-only" → Run
   *"I'm triggering a deployment that will build, test, and deploy all microservices."*

4. **Walk through stages** (2 min)
   - Show build logs (Maven compile + tests)
   - Show Docker builds (containerization)
   - Show ECS updates (deployment)
   *"Each stage validates code quality before deploying to production."*

5. **Show results** (1 min)
   - Summary tab: Image tags, ALB URL, health checks
   *"The pipeline automatically tags images with Git SHA for traceability."*

## Benefits Demonstrated

✅ **Infrastructure as Code**: Terraform manages all AWS resources declaratively  
✅ **Automated Testing**: Maven runs unit tests before any deployment  
✅ **Containerization**: Docker ensures consistent environments  
✅ **Zero-Downtime Deployment**: ECS rolling updates with health checks  
✅ **Version Tracking**: Git commit SHA tags enable rollbacks  
✅ **Cost Control**: Manual triggers prevent unnecessary AWS charges  
✅ **Flexibility**: Local and CI/CD methods coexist independently  
✅ **Industry Standards**: GitHub Actions + Docker + Terraform best practices  

## Troubleshooting Quick Reference

| Issue | Solution |
|-------|----------|
| "Run workflow" button missing | Push `.github/workflows/deploy.yml` to main branch |
| AWS credentials error | Update GitHub Secrets with fresh Learner Lab credentials |
| Terraform state not found | Run "infrastructure-only" mode or deploy locally first |
| ECS service not found | Infrastructure doesn't exist - deploy infrastructure first |
| Health checks failing | Wait 2-3 minutes for containers to fully start |
| Docker build timeout | Retry workflow - Maven dependencies will be cached |

## Files Modified/Created

```
.github/
  └── workflows/
      └── deploy.yml        # New: GitHub Actions workflow (hybrid model)

README.md                   # Updated: Added comprehensive CI/CD section

config/terraform/
  ├── variables.tf          # Existing: Already supports image_tag variable
  └── main.tf               # Existing: Already supports dynamic image tags
```

## Next Steps

1. **Commit changes**:
   ```bash
   git add .github/workflows/deploy.yml README.md
   git commit -m "Add CI/CD pipeline with hybrid deployment model"
   git push origin main
   ```

2. **Add GitHub Secrets** (one-time setup)

3. **Test CI/CD**:
   - Trigger "services-only" mode (requires infrastructure deployed locally first)
   - Or trigger "full-deployment" mode (creates everything from scratch)

4. **For daily work**: Continue using local deployment (`./build-and-push.sh`)

5. **For demos**: Use GitHub Actions to showcase DevOps skills

## Why This Approach?

✅ **Practical**: Local deployment is faster and more reliable for Learner Lab  
✅ **Educational**: CI/CD demonstrates industry best practices  
✅ **Flexible**: Both methods available based on situation  
✅ **Cost-Effective**: Manual triggers prevent accidental AWS charges  
✅ **Portfolio-Ready**: Complete CI/CD implementation to showcase  

---

**Questions?** See the full CI/CD section in README.md for detailed documentation.
