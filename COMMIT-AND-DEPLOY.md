# 📋 提交和部署指南

## 🎯 本次修复内容

### 1. IAM Role ARN - Account ID 自动检测

**问题**: `arn:aws:iam:::role/LabRole` (缺少 account ID)
**修复**: 工作流自动从 AWS STS 获取正确的 Account ID

### 2. RDS Instance 导入路径修正

**问题**: 使用错误的实例名称 (`ticketing-aurora-instance-1`)
**修复**: 使用正确名称 (`ticketing-aurora-writer`, `ticketing-aurora-reader-1`)

### 3. 新增调试工具

- `debug-account-id.sh` - 检查 Account ID 配置
- 改进的 `test-imports.sh` - 测试资源导入

---

## 🚀 提交步骤

### 第一步：提交代码

```bash
cd /Users/sujiezong/Desktop/NEU/6620-cloud-computing/Ticketing-Cloud-Deployment-main

# 查看改动
git status

# 添加所有改动
git add .

# 提交
git commit -m "Fix: Auto-detect AWS Account ID and correct RDS instance import paths

- Add automatic Account ID detection from AWS STS
- Fix RDS instance import paths (writer/readers instead of this[0]/this[1])
- Add debug-account-id.sh for troubleshooting
- Improve test-imports.sh with Account ID check
- Update both proactive and retry import steps
- Add comprehensive documentation (IMMEDIATE-FIX.md, QUICK-FIX-ACCOUNT-ID.md)"

# 推送
git push origin SujieBranch
```

### 第二步：更新 GitHub Secret

1. 在本地运行：

   ```bash
   aws sts get-caller-identity --query Account --output text
   ```

   复制输出（例如：`339713034274`）

2. 打开浏览器：
   https://github.com/James-Zeyu-Li/Ticketing-Cloud-Deployment/settings/secrets/actions

3. 找到 `AWS_ACCOUNT_ID` → 点击 ✏️ 编辑 → 粘贴数字 → 保存

### 第三步：运行 CI/CD

1. 打开：https://github.com/James-Zeyu-Li/Ticketing-Cloud-Deployment/actions
2. 点击 **Deploy Ticketing System**
3. 点击 **Run workflow** 下拉菜单
4. 选择 **full-deployment**
5. 点击绿色 **Run workflow** 按钮

---

## 🔍 验证清单

### 运行前验证（可选）

```bash
# 1. 检查 Account ID 配置
./config/scripts/debug-account-id.sh

# 2. 测试导入命令
./config/scripts/test-imports.sh

# 应该看到：
# ✅ AWS Account ID: 339713034274
# ✅ terraform.tfvars 正确
# ✅ IAM Role ARN 格式正确
# ✅ 找到 Target Groups
# ✅ 找到 RDS Cluster 和 Instances
```

### 运行中监控

检查这些步骤的输出：

1. **Create terraform.tfvars**

   ```
   ✅ 应该看到：
   🔍 Current AWS Account ID: 339713034274
   aws_account_id = "339713034274"
   ```

2. **Proactive Import**

   ```
   ✅ 应该看到：
   Import prepared! (多次)
   Import complete
   ```

3. **Terraform Plan**

   ```
   ✅ 应该看到：
   Plan: X to add, Y to change, 0 to destroy
   不应该有 "already exists" 错误
   ```

4. **Terraform Apply**
   ```
   ✅ 应该看到：
   Apply complete! Resources: X added, Y changed, 0 destroyed.
   ```

### 运行后验证

```bash
# 获取 ALB URL
cd config/terraform
terraform output -raw alb_dns_name

# 测试健康检查（等待 2-3 分钟后）
ALB_URL=$(terraform output -raw alb_dns_name)
curl http://$ALB_URL/purchase/health
curl http://$ALB_URL/query/health
curl http://$ALB_URL/events/health

# 应该都返回 200 OK
```

---

## 📊 预期时间线

| 步骤                 | 时间           | 说明                     |
| -------------------- | -------------- | ------------------------ |
| 提交代码             | 30 秒          | `git commit && git push` |
| 更新 Secret          | 30 秒          | 在 GitHub 网页操作       |
| 触发 CI/CD           | 10 秒          | Run workflow 按钮        |
| Build & Test         | 2-3 分钟       | Maven 编译和单元测试     |
| Terraform Init       | 30 秒          | 初始化 providers         |
| **Proactive Import** | **1-2 分钟**   | **导入已存在的资源**     |
| Terraform Plan       | 30 秒          | 生成执行计划             |
| Terraform Apply      | 8-10 分钟      | 创建/更新资源            |
| **总时间**           | **约 15 分钟** |                          |

---

## 🎯 成功标志

### 1. 没有 "already exists" 错误

```
✅ 所有 Target Groups 被导入
✅ RDS Cluster 和 Instances 被导入
✅ 没有 ELBv2 或 RDS 重复错误
```

### 2. IAM Role 有效

```
✅ execution_role_arn = "arn:aws:iam::339713034274:role/LabRole"
✅ task_role_arn = "arn:aws:iam::339713034274:role/LabRole"
✅ 没有 "Role is not valid" 错误
```

### 3. 所有服务运行

```bash
# 健康检查都应该返回 200
curl http://<alb-url>/purchase/health
curl http://<alb-url>/query/health
curl http://<alb-url>/events/health
```

---

## 🆘 故障排除

### 如果还是有 "Role is not valid" 错误

**原因**: GitHub Secret 还是空的或错误

**解决**:

```bash
# 1. 确认当前 Account ID
aws sts get-caller-identity

# 2. 检查 Secret 是否更新
# 在 GitHub Actions 日志中查找 "Current AWS Account ID"
# 应该是 12 位数字，不是空白

# 3. 手动创建 terraform.tfvars 测试
cd config/terraform
cat > terraform.tfvars <<EOF
aws_region     = "us-west-2"
aws_account_id = "339713034274"
EOF

# 4. 本地测试
terraform plan
```

### 如果还是有 "already exists" 错误

**原因**: Proactive Import 没有运行或失败了

**解决**:

```bash
# 1. 检查工作流日志中的 "Proactive Import" 步骤
# 应该看到多个 "Import prepared!"

# 2. 如果没有，手动导入
cd config/terraform
./config/scripts/test-imports.sh  # 显示需要的命令
# 复制并运行显示的 terraform import 命令

# 3. 然后手动 apply
terraform apply
```

### 如果 RDS Instances 还是报 "already exists"

**原因**: Instance 名称还是不匹配

**解决**:

```bash
# 1. 检查实际的 instance 名称
aws rds describe-db-instances --region us-west-2 \
  --query "DBInstances[?DBClusterIdentifier=='ticketing-aurora'].DBInstanceIdentifier"

# 2. 使用正确的名称导入
terraform import 'module.rds.aws_rds_cluster_instance.writer' <实际的writer名称>
terraform import 'module.rds.aws_rds_cluster_instance.readers[0]' <实际的reader名称>
```

---

## 📚 相关文档

- **IMMEDIATE-FIX.md** - 30 秒快速修复指南
- **QUICK-FIX-ACCOUNT-ID.md** - Account ID 问题详细说明
- **AUTO-IMPORT-EXPLAINED.md** - 自动导入机制原理
- **AWS-LEARNER-LAB-GUIDE.md** - Learner Lab 特殊注意事项

---

**最后更新**: 2025-01-09  
**预计解决率**: 95%+ （如果按步骤操作）  
**平均解决时间**: 5 分钟（secret 更新 + 重新运行）
