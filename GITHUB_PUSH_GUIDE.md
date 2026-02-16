# GitHub 推送指南

## 方法1：使用GitHub CLI (推荐)

如果你安装了GitHub CLI (`gh`)：

```bash
cd ~/openclaw-smart-task-manager

# 登录GitHub（如果还没登录）
gh auth login

# 创建仓库并推送
gh repo create openclaw-smart-task-manager --public --source=. --remote=origin --push

# 或者创建私有仓库
gh repo create openclaw-smart-task-manager --private --source=. --remote=origin --push
```

## 方法2：手动在GitHub网站创建仓库

### 步骤1：在GitHub创建新仓库

1. 访问 https://github.com/new
2. 仓库名称：`openclaw-smart-task-manager`
3. 描述：`Smart task management system for OpenClaw - solves timeout issues with intelligent task decomposition`
4. 选择 Public 或 Private
5. **不要**勾选 "Initialize this repository with a README"
6. 点击 "Create repository"

### 步骤2：推送本地代码

GitHub会显示推送命令，类似这样：

```bash
cd ~/openclaw-smart-task-manager

# 添加远程仓库（替换YOUR_USERNAME为你的GitHub用户名）
git remote add origin https://github.com/YOUR_USERNAME/openclaw-smart-task-manager.git

# 推送代码
git branch -M main
git push -u origin main
```

### 步骤3：添加Topics（可选）

在GitHub仓库页面，点击设置图标添加topics：
- `openclaw`
- `moltbook`
- `ai-agent`
- `task-management`
- `automation`
- `llm`

## 方法3：使用SSH（如果配置了SSH密钥）

```bash
cd ~/openclaw-smart-task-manager

# 添加远程仓库（SSH方式）
git remote add origin git@github.com:YOUR_USERNAME/openclaw-smart-task-manager.git

# 推送代码
git branch -M main
git push -u origin main
```

## 验证推送成功

推送成功后，访问：
```
https://github.com/YOUR_USERNAME/openclaw-smart-task-manager
```

你应该能看到：
- ✅ README.md 显示在首页
- ✅ 所有文件都已上传
- ✅ 提交历史显示正确

## 后续更新

当你修改代码后，使用以下命令推送更新：

```bash
cd ~/openclaw-smart-task-manager

# 查看修改
git status

# 添加修改的文件
git add .

# 提交
git commit -m "描述你的修改"

# 推送
git push
```

## 常见问题

### 问题1：需要输入用户名和密码

GitHub已经不支持密码认证，需要使用：
- Personal Access Token (PAT)
- 或者 GitHub CLI (`gh`)
- 或者 SSH密钥

### 问题2：推送被拒绝

如果看到 "Updates were rejected"，可能是因为：
```bash
# 先拉取远程更改
git pull origin main --rebase

# 再推送
git push origin main
```

### 问题3：修改git用户信息

```bash
git config --global user.name "你的GitHub用户名"
git config --global user.email "你的GitHub邮箱"
```

## 下一步

推送成功后，你可以：
1. 在README中更新仓库URL
2. 添加GitHub Actions（可选）
3. 创建Release版本
4. 分享到OpenClaw社区和Moltbook

---

**当前仓库位置**：`~/openclaw-smart-task-manager`

**需要帮助？** 告诉我你遇到的问题，我会帮你解决。
