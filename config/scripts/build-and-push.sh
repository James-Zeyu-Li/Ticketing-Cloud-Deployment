#!/usr/bin/env bash
set -eo pipefail  # Removed -u flag to allow associative array iteration

# ======= AWS Credentials =======
AWS_ACCESS_KEY_ID="ASIAU6GDWL3RJP7RTABC"
AWS_SECRET_ACCESS_KEY="gTiTfSyirewpb/nL9k/Tevq6UrcBDQUh375RiL7n"
AWS_SESSION_TOKEN="IQoJb3JpZ2luX2VjEIP//////////wEaCXVzLXdlc3QtMiJGMEQCIG8ejYFkN8f+YXgY2/lY+kCJaqycNChEoT0o4W4V27DVAiA4Va1/fHLbfKWUDjRWCuMgAz+Bh3nhXV+KFxcpxHDRYSqzAghMEAAaDDMzOTcxMjgyNzEwNiIMeHJoeFQSFQR56mKOKpACIOPWj7lOHAnSiONVpTnV/+/310b3kzApS+AIQ/eeW2wkUJj0ds+wq2DIWdE3lVnf3QohH6jA5Xigd1Zed9R3llNVU4Mg6qJhpXVPDXqVjRrrLCV5tSBQAdAlWpqhbgoCPd93uMSVy6hnML2FMqw1rGpKtYLIRbFmg31/eOwMsg8dFm6Sj9U66p0OLvYUhZqLNugeBsVzx0koHrvwb9p+2YS/tJx2HrcJC2MuzgaTXVc3WeSg8l3VZX5d0KOBDsriNBM8Upn/1klIG4/OtQK4HxJHt8VCmdpVYmJSwhDxLbZpJeMg4Hy9J1KK4a/cj0zLZtmcORJO6XpbCrJuUcd1A3fXcKeyXzj0ef9FItAZkKYw4dWeyAY6ngENMR4xFdF+3S4QR9P1gabxV5AJwIy+d4tsG6Lm9tCf5J4jFbYtcVpRxhHGJSal/Y8Z80luANuQKEJakWmAh/eb8TD3fjllJdRK6mlORP1Lm02MqclIFPaNIHQVXVL/b2OiP/3ufYX0P5iwIGnBkT4tk9QlntrZfIaxuRkE/FFirOPg/znEnrLtee4h77JEKLjDYuIFiSOPMJBPCmOxOg=="

# ======= Other Variables =======

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$SCRIPT_DIR/../..")"
TF_DIR="${TF_DIR:-$REPO_ROOT/config/terraform}" 
AWS_REGION="${AWS_REGION:-us-west-2}"
PLATFORM="${PLATFORM:-linux/amd64}"
TAG="${TAG:-$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)}"      

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN
export AWS_REGION

echo "[INFO] Using hardcoded AWS credentials (Learner Lab)"
aws sts get-caller-identity || { echo "[ERR] Invalid credentials"; exit 1; }

# 检查必要工具
command -v jq >/dev/null || { echo "[ERR] jq not found (brew install jq)"; exit 1; }

# 读取 Terraform 输出中的 ECR 仓库信息
echo "[INFO] Reading ECR repo URLs from Terraform outputs..."
pushd "$TF_DIR" >/dev/null
terraform init -input=false >/dev/null

if ! terraform output ecr_repository_urls &>/dev/null; then
  echo "[WARN] ECR repositories not found in Terraform state."
  echo "[INFO] Running 'terraform apply' to create ECR repositories first..."
  terraform apply -auto-approve -target=module.ecr
  echo "[OK] ECR repositories created. Continuing with image build..."
fi

terraform output -json ecr_repository_urls > /tmp/ecr.json
popd >/dev/null

# 登录 ECR
REGISTRY="$(jq -r 'to_entries[0].value | split("/")[0]' /tmp/ecr.json)"
echo "[INFO] Logging into ECR: $REGISTRY"
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"


# === Build & Push Images =====================================================
# Service directory name -> Terraform service key mapping
SERVICES_DIRS=("PurchaseService" "QueryService" "RabbitCombinedConsumer")
SERVICES_KEYS=("purchase-service" "query-service" "mq-projection-service")

echo "[INFO] Building & pushing Docker images... TAG=$TAG"

for i in "${!SERVICES_DIRS[@]}"; do
  dir="${SERVICES_DIRS[$i]}"
  key="${SERVICES_KEYS[$i]}"
  repo="$(jq -r --arg k "$key" '.[$k]' /tmp/ecr.json)"

  if [[ -z "$repo" || "$repo" == "null" ]]; then
    echo "[ERR] ECR repo for $key not found"
    exit 1
  fi

  echo "  -> Building $key  =>  $repo:$TAG"
  docker build --platform "$PLATFORM" -t "$repo:$TAG" "$REPO_ROOT/$dir"
  docker push "$repo:$TAG"
done


echo "[INFO] Applying Terraform with new image tags..."
pushd "$TF_DIR" >/dev/null
terraform apply -auto-approve \
  -var="service_image_tags={
    \"purchase-service\":\"$TAG\",
    \"query-service\":\"$TAG\",
    \"mq-projection-service\":\"$TAG\"
  }"
popd >/dev/null

echo "[OK] Deployment complete. Current tag: $TAG"