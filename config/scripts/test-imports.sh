#!/bin/bash
# Test import commands locally before CI/CD

REGION="us-west-2"
cd "$(dirname "$0")/../terraform"

echo "🧪 Testing import commands..."
echo ""

# Check AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
if [ -z "$ACCOUNT_ID" ]; then
  echo "❌ Unable to get AWS Account ID. Please configure AWS CLI credentials."
  exit 1
fi
echo "🔑 AWS Account ID: $ACCOUNT_ID"
echo "🌍 Region: $REGION"
echo ""

# Test Target Groups
echo "📦 Testing Target Group imports..."
TG_PURCHASE=$(aws elbv2 describe-target-groups --region $REGION --query "TargetGroups[?TargetGroupName=='purchase-service-tg'].TargetGroupArn" --output text 2>/dev/null || echo "")
if [ ! -z "$TG_PURCHASE" ]; then
  echo "  Found: purchase-service-tg"
  echo "  ARN: $TG_PURCHASE"
  echo "  Command: terraform import 'module.shared_alb.aws_lb_target_group.services[\"purchase-service\"]' \"$TG_PURCHASE\""
else
  echo "  ⚠️  purchase-service-tg not found"
fi

# Test Redis SG
echo ""
echo "🔒 Testing Redis Security Group import..."
REDIS_SG=$(aws ec2 describe-security-groups --region $REGION --filters "Name=group-name,Values=ticketing-redis-sg" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || echo "")
if [ ! -z "$REDIS_SG" ] && [ "$REDIS_SG" != "None" ]; then
  echo "  Found: ticketing-redis-sg"
  echo "  ID: $REDIS_SG"
  echo "  Command: terraform import 'module.elasticache.aws_security_group.redis_sg' \"$REDIS_SG\""
else
  echo "  ⚠️  ticketing-redis-sg not found"
fi

# Test RDS Cluster
echo ""
echo "🗄️  Testing RDS Cluster import..."
RDS_CLUSTER=$(aws rds describe-db-clusters --region $REGION --query "DBClusters[?DBClusterIdentifier=='ticketing-aurora'].DBClusterIdentifier" --output text 2>/dev/null || echo "")
if [ ! -z "$RDS_CLUSTER" ]; then
  echo "  Found: ticketing-aurora"
  echo "  Command: terraform import 'module.rds.aws_rds_cluster.this' 'ticketing-aurora'"
  
  # Check for instances (writer and reader)
  WRITER=$(aws rds describe-db-instances --region $REGION --query "DBInstances[?DBInstanceIdentifier=='ticketing-aurora-writer'].DBInstanceIdentifier" --output text 2>/dev/null || echo "")
  READER=$(aws rds describe-db-instances --region $REGION --query "DBInstances[?DBInstanceIdentifier=='ticketing-aurora-reader-1'].DBInstanceIdentifier" --output text 2>/dev/null || echo "")
  
  if [ ! -z "$WRITER" ]; then
    echo "  Found writer: $WRITER"
    echo "  Command: terraform import 'module.rds.aws_rds_cluster_instance.writer' 'ticketing-aurora-writer'"
  else
    echo "  ⚠️  Writer instance (ticketing-aurora-writer) not found"
  fi
  
  if [ ! -z "$READER" ]; then
    echo "  Found reader: $READER"
    echo "  Command: terraform import 'module.rds.aws_rds_cluster_instance.readers[0]' 'ticketing-aurora-reader-1'"
  else
    echo "  ⚠️  Reader instance (ticketing-aurora-reader-1) not found"
  fi
else
  echo "  ⚠️  ticketing-aurora not found"
fi

# Test ALB
echo ""
echo "⚖️  Testing ALB import..."
ALB_ARN=$(aws elbv2 describe-load-balancers --region $REGION --query "LoadBalancers[?LoadBalancerName=='ticketing-alb'].LoadBalancerArn" --output text 2>/dev/null || echo "")
if [ ! -z "$ALB_ARN" ]; then
  echo "  Found: ticketing-alb"
  echo "  ARN: $ALB_ARN"
  echo "  Command: terraform import 'module.shared_alb.aws_lb.shared' \"$ALB_ARN\""
else
  echo "  ⚠️  ticketing-alb not found"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Test complete!"
echo ""
echo "🔑 IAM Role Check:"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/LabRole"
echo "   Expected IAM Role: $ROLE_ARN"
if aws iam get-role --role-name LabRole &>/dev/null; then
  echo "   ✅ LabRole exists"
else
  echo "   ⚠️  LabRole not accessible (normal for Learner Lab)"
fi
echo ""
echo "If you see resources above, you can run the import commands locally:"
echo "  cd config/terraform"
echo "  # Copy the commands shown above"
echo ""
echo "Or just push and let CI/CD auto-import them!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
