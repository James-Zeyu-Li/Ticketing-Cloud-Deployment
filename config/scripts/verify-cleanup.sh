#!/bin/bash
# Verify that AWS resources are fully deleted before deploying

REGION="us-west-2"
echo "🔍 Verifying cleanup status in region: $REGION"
echo ""

ALL_CLEAR=true

# Check ElastiCache Subnet Groups
echo "📦 Checking ElastiCache Subnet Groups..."
ELASTICACHE_SG=$(aws elasticache describe-cache-subnet-groups --region $REGION --query "CacheSubnetGroups[?contains(CacheSubnetGroupName, 'ticketing')].CacheSubnetGroupName" --output text 2>/dev/null || echo "")
if [ ! -z "$ELASTICACHE_SG" ]; then
  echo "❌ ElastiCache subnet groups still exist: $ELASTICACHE_SG"
  ALL_CLEAR=false
else
  echo "✅ ElastiCache subnet groups cleared"
fi

# Check ElastiCache Parameter Groups
echo "⚙️  Checking ElastiCache Parameter Groups..."
ELASTICACHE_PG=$(aws elasticache describe-cache-parameter-groups --region $REGION --query "CacheParameterGroups[?contains(CacheParameterGroupName, 'ticketing')].CacheParameterGroupName" --output text 2>/dev/null || echo "")
if [ ! -z "$ELASTICACHE_PG" ]; then
  echo "❌ ElastiCache parameter groups still exist: $ELASTICACHE_PG"
  ALL_CLEAR=false
else
  echo "✅ ElastiCache parameter groups cleared"
fi

# Check RDS Subnet Groups
echo "🗄️  Checking RDS Subnet Groups..."
RDS_SG=$(aws rds describe-db-subnet-groups --region $REGION --query "DBSubnetGroups[?contains(DBSubnetGroupName, 'ticketing')].DBSubnetGroupName" --output text 2>/dev/null || echo "")
if [ ! -z "$RDS_SG" ]; then
  echo "❌ RDS subnet groups still exist: $RDS_SG"
  ALL_CLEAR=false
else
  echo "✅ RDS subnet groups cleared"
fi

# Check RDS Parameter Groups
echo "⚙️  Checking RDS Parameter Groups..."
RDS_PG=$(aws rds describe-db-cluster-parameter-groups --region $REGION --query "DBClusterParameterGroups[?contains(DBClusterParameterGroupName, 'ticketing')].DBClusterParameterGroupName" --output text 2>/dev/null || echo "")
if [ ! -z "$RDS_PG" ]; then
  echo "❌ RDS parameter groups still exist: $RDS_PG"
  ALL_CLEAR=false
else
  echo "✅ RDS parameter groups cleared"
fi

# Check Security Groups
echo "🔒 Checking Security Groups..."
SECURITY_GROUPS=$(aws ec2 describe-security-groups --region $REGION --filters "Name=group-name,Values=ticketing-*" --query "SecurityGroups[].GroupName" --output text 2>/dev/null || echo "")
if [ ! -z "$SECURITY_GROUPS" ]; then
  echo "❌ Security groups still exist: $SECURITY_GROUPS"
  ALL_CLEAR=false
else
  echo "✅ Security groups cleared"
fi

# Check Target Groups
echo "🎯 Checking Target Groups..."
TARGET_GROUPS=$(aws elbv2 describe-target-groups --region $REGION --query "TargetGroups[?contains(TargetGroupName, 'service')].TargetGroupName" --output text 2>/dev/null || echo "")
if [ ! -z "$TARGET_GROUPS" ]; then
  echo "❌ Target groups still exist: $TARGET_GROUPS"
  ALL_CLEAR=false
else
  echo "✅ Target groups cleared"
fi

# Check ECR Repositories
echo "🐳 Checking ECR Repositories..."
ECR_REPOS=$(aws ecr describe-repositories --region $REGION --query "repositories[?contains(repositoryName, 'service')].repositoryName" --output text 2>/dev/null || echo "")
if [ ! -z "$ECR_REPOS" ]; then
  echo "❌ ECR repositories still exist: $ECR_REPOS"
  ALL_CLEAR=false
else
  echo "✅ ECR repositories cleared"
fi

# Check CloudWatch Log Groups
echo "📊 Checking CloudWatch Log Groups..."
LOG_GROUPS=$(aws logs describe-log-groups --region $REGION --log-group-name-prefix "/ecs/" --query "logGroups[].logGroupName" --output text 2>/dev/null || echo "")
if [ ! -z "$LOG_GROUPS" ]; then
  echo "❌ CloudWatch log groups still exist: $LOG_GROUPS"
  ALL_CLEAR=false
else
  echo "✅ CloudWatch log groups cleared"
fi

# Check IAM Policies
echo "🔑 Checking IAM Policies..."
IAM_POLICIES=$(aws iam list-policies --query "Policies[?contains(PolicyName, 'ticketing')].PolicyName" --output text 2>/dev/null || echo "")
if [ ! -z "$IAM_POLICIES" ]; then
  echo "❌ IAM policies still exist: $IAM_POLICIES"
  ALL_CLEAR=false
else
  echo "✅ IAM policies cleared"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$ALL_CLEAR" = true ]; then
  echo "✅ ALL CLEAR! Safe to deploy now."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "You can now run:"
  echo "  • terraform apply (locally)"
  echo "  • GitHub Actions: full-deployment"
  exit 0
else
  echo "⚠️  NOT READY - Resources still exist!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "What to do:"
  echo "1. Wait 2-3 more minutes for AWS eventual consistency"
  echo "2. Run this script again to verify"
  echo "3. If resources persist after 10 minutes, check AWS Console"
  exit 1
fi
