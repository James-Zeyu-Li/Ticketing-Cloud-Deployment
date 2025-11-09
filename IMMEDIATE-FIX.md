# 🚨 立即修复 - IAM Role 错误

## 当前错误

```
Error: Role is not valid
execution_role_arn = "arn:aws:iam:::role/LabRole"
                                  ^^^
                                  Account ID 缺失！
```

## ⚡ 30 秒快速修复

### 1️⃣ 获取正确的 Account ID（10 秒）

```bash
aws sts get-caller-identity --query Account --output text
```

复制输出的 12 位数字（例如：`339713034274`）

### 2️⃣ 更新 GitHub Secret（15 秒）

1. 打开：https://github.com/James-Zeyu-Li/Ticketing-Cloud-Deployment/settings/secrets/actions
2. 找到 `AWS_ACCOUNT_ID`
3. 点击 ✏️ 编辑
4. 粘贴第 1 步的数字
5. 点击 **Update secret**

### 3️⃣ 重新运行 CI/CD（5 秒）

1. 打开：https://github.com/James-Zeyu-Li/Ticketing-Cloud-Deployment/actions
2. 点击最新失败的 workflow run
3. 点击 **Re-run all jobs** 按钮

---

## 💡 为什么会失败？

### 问题 1: Account ID 缺失

**现象**: `arn:aws:iam:::role/LabRole` (三个冒号)  
**原因**: GitHub Secret `AWS_ACCOUNT_ID` 未设置或为空  
**后果**: ECS 无法创建 Task Definition（需要有效的 IAM Role ARN）

### 问题 2: RDS Instances 已存在

**现象**: `DBInstanceAlreadyExists`  
**原因**: Writer 和 Reader 实例在上次运行中创建，但导入路径错误  
**后果**: Terraform 尝试创建已存在的实例

### 问题 3: Target Groups 已存在

**现象**: `ELBv2 Target Group already exists`  
**原因**: 虽然 Proactive Import 运行了，但在重试步骤中导入，不是第一次 apply 之前  
**后果**: 第一次 apply 失败，重试时导入

---

## ✅ 本次修复内容

### 修复 1: 自动检测 Account ID

```yaml
# 新增：自动从 AWS STS 获取，覆盖错误的 secret
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "🔍 Current AWS Account ID: $ACCOUNT_ID"
cat > terraform.tfvars <<EOF
aws_account_id = "$ACCOUNT_ID"
EOF
```

### 修复 2: 正确的 RDS Instance 导入

```bash
# ✅ 正确（新）
terraform import 'module.rds.aws_rds_cluster_instance.writer' ticketing-aurora-writer
terraform import 'module.rds.aws_rds_cluster_instance.readers[0]' ticketing-aurora-reader-1

# ❌ 错误（旧）
terraform import 'module.rds.aws_rds_cluster_instance.this[0]' ticketing-aurora-instance-1
```

### 修复 3: Proactive Import 时机正确

```yaml
Terraform Init
↓
🆕 Proactive Import (在这里！)
↓
Terraform Plan
↓
Terraform Apply
```

---

## 🧪 本地测试（可选）

如果你想在推送前验证：

```bash
# 1. 检查 Account ID 配置
./config/scripts/debug-account-id.sh

# 2. 测试导入命令
./config/scripts/test-imports.sh

# 3. 如果一切正常，提交
git add .
git commit -m "Fix: AWS Account ID auto-detection and RDS instance imports"
git push origin SujieBranch
```

---

## 📊 预期结果

### 成功的工作流日志应该看起来像：

```
✅ Step 1: Create terraform.tfvars
   🔍 Current AWS Account ID: 339713034274
   ✅ terraform.tfvars created:
      aws_region     = "us-west-2"
      aws_account_id = "339713034274"

✅ Step 2: Terraform Init
   Initializing provider plugins...
   Terraform has been successfully initialized!

✅ Step 3: Proactive Import of Existing Resources
   🔄 Proactively checking and importing any existing resources...
   ✅ Imported module.shared_alb.aws_lb_target_group.services["purchase-service"]
   ✅ Imported module.shared_alb.aws_lb_target_group.services["query-service"]
   ✅ Imported module.shared_alb.aws_lb_target_group.services["mq-projection-service"]
   ✅ Imported module.rds.aws_rds_cluster.this
   ✅ Imported module.rds.aws_rds_cluster_instance.writer
   ✅ Imported module.rds.aws_rds_cluster_instance.readers[0]

✅ Step 4: Terraform Plan
   Plan: 14 to add, 5 to change, 0 to destroy.

✅ Step 5: Terraform Apply
   Apply complete! Resources: 14 added, 5 changed, 0 destroyed.

   Outputs:
   alb_dns_name = "ticketing-alb-xxxx.us-west-2.elb.amazonaws.com"
```

---

## 🆘 如果还是失败

### 检查清单：

- [ ] GitHub Secret `AWS_ACCOUNT_ID` 是 12 位数字
- [ ] AWS Credentials 没有过期（4 小时限制）
- [ ] 没有其他 workflow 同时运行（状态冲突）

### 获取帮助：

```bash
# 运行完整诊断
./config/scripts/debug-account-id.sh > debug-output.txt

# 然后把 debug-output.txt 发给我
```

---

**创建时间**: 2025-01-09  
**解决问题**: IAM Role ARN 缺少 Account ID，RDS Instances 导入路径错误  
**预计解决时间**: 2-3 分钟（更新 secret + 重新运行）
