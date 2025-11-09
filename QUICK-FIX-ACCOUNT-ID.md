# 🔧 Quick Fix Guide - AWS Account ID Issue

## 问题诊断

你遇到的错误：

```
Error: Role is not valid
execution_role_arn = "arn:aws:iam:::role/LabRole"
                                  ^^^
                                  缺少 Account ID!
```

## 🎯 根本原因

GitHub Secrets 中的 `AWS_ACCOUNT_ID` 可能：

1. 没有设置
2. 设置错误
3. 或者是空字符串

## ✅ 解决步骤

### 第一步：获取正确的 Account ID

```bash
# 在本地运行（确保 AWS CLI 已配置）
aws sts get-caller-identity --query Account --output text
```

输出示例：`339713034274`

### 第二步：更新 GitHub Secrets

1. 打开浏览器 → https://github.com/James-Zeyu-Li/Ticketing-Cloud-Deployment
2. 点击 **Settings** → **Secrets and variables** → **Actions**
3. 找到或创建 `AWS_ACCOUNT_ID` secret
4. 粘贴第一步获取的 Account ID（纯数字，12 位）
5. 点击 **Update secret**

### 第三步：验证本地配置

```bash
# 运行调试脚本
chmod +x config/scripts/debug-account-id.sh
./config/scripts/debug-account-id.sh
```

这会检查：

- ✅ AWS CLI 配置
- ✅ Account ID
- ✅ terraform.tfvars 是否正确
- ✅ IAM Role ARN 格式

### 第四步：测试导入

```bash
# 运行导入测试
chmod +x config/scripts/test-imports.sh
./config/scripts/test-imports.sh
```

这会显示：

- 哪些资源已存在
- 需要运行哪些导入命令
- IAM Role 是否可访问

### 第五步：提交并重新运行 CI/CD

```bash
git add .
git commit -m "Fix: Verify AWS Account ID configuration and RDS instance imports"
git push origin SujieBranch
```

然后：

1. 打开 GitHub → **Actions**
2. 运行 **Deploy Ticketing System** workflow
3. 选择 **full-deployment** 或 **infrastructure-only**

## 🔍 改进内容

### 1. 自动检测 Account ID

新的工作流会自动从 AWS STS 获取 Account ID，即使 secret 错误也能修正：

```yaml
- name: Create terraform.tfvars
  run: |
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    echo "Current AWS Account ID: $ACCOUNT_ID"
    cat > terraform.tfvars <<EOF
    aws_region     = "us-west-2"
    aws_account_id = "$ACCOUNT_ID"
    EOF
```

### 2. 修正 RDS Instance 导入

现在使用正确的实例名称：

```bash
# ✅ 正确
terraform import 'module.rds.aws_rds_cluster_instance.writer' ticketing-aurora-writer
terraform import 'module.rds.aws_rds_cluster_instance.readers[0]' ticketing-aurora-reader-1

# ❌ 错误（旧版本）
terraform import 'module.rds.aws_rds_cluster_instance.this[0]' ticketing-aurora-instance-1
```

### 3. 新增调试工具

- `debug-account-id.sh` - 检查 Account ID 配置
- 改进的 `test-imports.sh` - 显示资源状态和导入命令

## 🎯 预期结果

运行 CI/CD 后，你应该看到：

```
✅ terraform.tfvars created:
   aws_region     = "us-west-2"
   aws_account_id = "339713034274"

🔍 Current AWS Account ID: 339713034274

🔄 Proactively checking and importing any existing resources...
   ✅ Imported purchase-service-tg
   ✅ Imported query-service-tg
   ✅ Imported mq-projection-service-tg
   ✅ Imported ticketing-aurora
   ✅ Imported ticketing-aurora-writer
   ✅ Imported ticketing-aurora-reader-1

terraform apply -auto-approve
   ✅ Apply complete! Resources: 20 added, 0 changed, 0 imported.
```

## 📝 常见问题

### Q: "LabRole not found" 错误

**A:** 这在 AWS Learner Lab 中是正常的。Role 会在服务启动时由 AWS 自动创建。

### Q: Target Groups 还是报 "already exists"

**A:** 确保 Proactive Import 步骤在 `terraform plan` **之前**运行。检查工作流日志中步骤顺序。

### Q: 如何手动导入资源？

**A:**

```bash
cd config/terraform
./config/scripts/test-imports.sh  # 查看需要导入的资源
# 复制显示的命令并执行
terraform apply
```

## 🚀 下一步

如果仍然失败：

1. 检查 GitHub Actions 日志中的 "Create terraform.tfvars" 步骤
2. 确认 Account ID 输出是 12 位数字
3. 运行本地 `debug-account-id.sh` 脚本对比
4. 在 Issues 中提供完整错误日志

---

**最后更新**: 2025-01-09  
**相关文档**: `AUTO-IMPORT-EXPLAINED.md`, `AWS-LEARNER-LAB-GUIDE.md`
