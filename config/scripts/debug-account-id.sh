#!/bin/bash
# Debug AWS Account ID configuration

echo "🔍 AWS Account ID Debug Tool"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check current AWS credentials
echo "1️⃣ Checking AWS CLI credentials..."
if aws sts get-caller-identity &>/dev/null; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
    echo "✅ AWS CLI configured successfully"
    echo "   Account ID: $ACCOUNT_ID"
    echo "   User ARN:   $USER_ARN"
else
    echo "❌ AWS CLI not configured or credentials expired"
    exit 1
fi

echo ""
echo "2️⃣ Checking GitHub Secrets (if running in GitHub Actions)..."
if [ ! -z "$GITHUB_ACTIONS" ]; then
    echo "   AWS_ACCOUNT_ID secret: ${AWS_ACCOUNT_ID:-<NOT SET>}"
    echo "   Current account: $ACCOUNT_ID"
    
    if [ "$AWS_ACCOUNT_ID" != "$ACCOUNT_ID" ]; then
        echo "   ⚠️  WARNING: Secret doesn't match current account!"
    else
        echo "   ✅ Secret matches current account"
    fi
else
    echo "   ℹ️  Not running in GitHub Actions (skipping)"
fi

echo ""
echo "3️⃣ Checking Terraform configuration..."
cd "$(dirname "$0")/../terraform"

if [ -f "terraform.tfvars" ]; then
    echo "   ✅ terraform.tfvars exists"
    echo "   Contents:"
    cat terraform.tfvars | sed 's/^/     /'
    
    # Extract account ID from tfvars
    TFVARS_ACCOUNT=$(grep 'aws_account_id' terraform.tfvars | awk -F '"' '{print $2}')
    echo ""
    echo "   Extracted account ID: ${TFVARS_ACCOUNT:-<NOT FOUND>}"
    
    if [ "$TFVARS_ACCOUNT" != "$ACCOUNT_ID" ]; then
        echo "   ⚠️  WARNING: tfvars account doesn't match current account!"
        echo ""
        echo "   💡 Fix: Update terraform.tfvars with correct account ID:"
        echo "      aws_account_id = \"$ACCOUNT_ID\""
    else
        echo "   ✅ tfvars account matches current account"
    fi
else
    echo "   ❌ terraform.tfvars NOT FOUND"
    echo ""
    echo "   💡 Creating terraform.tfvars with current account..."
    cat > terraform.tfvars <<EOF
aws_region     = "us-west-2"
aws_account_id = "$ACCOUNT_ID"
EOF
    echo "   ✅ Created terraform.tfvars"
    cat terraform.tfvars | sed 's/^/     /'
fi

echo ""
echo "4️⃣ Testing IAM Role ARN generation..."
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/LabRole"
echo "   Expected role ARN: $ROLE_ARN"

# Check if role exists
if aws iam get-role --role-name LabRole &>/dev/null; then
    echo "   ✅ LabRole exists"
    ACTUAL_ARN=$(aws iam get-role --role-name LabRole --query 'Role.Arn' --output text)
    echo "   Actual ARN: $ACTUAL_ARN"
    
    if [ "$ROLE_ARN" = "$ACTUAL_ARN" ]; then
        echo "   ✅ ARN matches!"
    else
        echo "   ⚠️  ARN mismatch!"
    fi
else
    echo "   ⚠️  LabRole not found (this is normal for AWS Learner Lab)"
    echo "   ℹ️  Role will be available when services are deployed"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Debug complete!"
echo ""
echo "📝 Summary:"
echo "   Current AWS Account: $ACCOUNT_ID"
echo "   Expected IAM Role:   arn:aws:iam::${ACCOUNT_ID}:role/LabRole"
echo ""
echo "🚀 Next steps:"
echo "   1. Make sure GitHub Secret 'AWS_ACCOUNT_ID' is set to: $ACCOUNT_ID"
echo "   2. Update config/terraform/terraform.tfvars if needed"
echo "   3. Run: cd config/terraform && terraform plan"
