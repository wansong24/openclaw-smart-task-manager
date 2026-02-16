# 维护者指南

## 仓库信息

- **GitHub仓库**: https://github.com/wansong24/openclaw-smart-task-manager
- **所有者**: wansong24
- **本地路径**: `~/openclaw-smart-task-manager`

## 权限配置

✅ GitHub CLI已配置并授权
✅ Git用户信息已设置
✅ 具有完整的repo权限（读写）

## 日常维护

### 1. 更新代码并推送

**自动方式（推荐）**：
```bash
cd ~/openclaw-smart-task-manager
./auto-update.sh
```

**手动方式**：
```bash
cd ~/openclaw-smart-task-manager

# 查看更改
git status

# 添加更改
git add .

# 提交
git commit -m "描述你的更改"

# 推送
git push origin main
```

### 2. 同步本地脚本到仓库

当你修改了 `~/.openclaw/scripts/` 中的脚本后：

```bash
# 复制最新版本
cp ~/.openclaw/scripts/smart-task-manager.sh ~/openclaw-smart-task-manager/
cp ~/.openclaw/scripts/check-status.sh ~/openclaw-smart-task-manager/
cp ~/.openclaw/scripts/SMART_TASK_README.md ~/openclaw-smart-task-manager/DOCUMENTATION.md

# 推送更新
cd ~/openclaw-smart-task-manager
./auto-update.sh
```

### 3. 创建新版本

```bash
cd ~/openclaw-smart-task-manager

# 更新CHANGELOG.md
# 编辑版本信息...

# 创建git tag
git tag -a v1.1.0 -m "Version 1.1.0 - 新功能描述"
git push origin v1.1.0

# 创建GitHub Release
gh release create v1.1.0 \
  --title "v1.1.0 - 新功能" \
  --notes "## 更新内容
- 新功能1
- 优化2
- 修复3"
```

### 4. 查看仓库状态

```bash
# 查看本地状态
cd ~/openclaw-smart-task-manager
git status

# 查看远程仓库信息
gh repo view wansong24/openclaw-smart-task-manager

# 查看最近的提交
git log --oneline -10

# 查看所有releases
gh release list
```

### 5. 处理Issues和PR

```bash
# 查看issues
gh issue list

# 创建新issue
gh issue create --title "标题" --body "描述"

# 查看PR
gh pr list

# 合并PR
gh pr merge PR_NUMBER
```

## 优化计划

### 短期优化（v1.1.0）
- [ ] 添加更多错误处理
- [ ] 支持自定义超时时间
- [ ] 添加性能监控
- [ ] 优化日志输出

### 中期优化（v1.2.0）
- [ ] 支持更多模型提供商
- [ ] 添加Web界面
- [ ] 集成Moltbook API
- [ ] 添加单元测试

### 长期优化（v2.0.0）
- [ ] 完全自动化的任务分解
- [ ] AI驱动的超时预测
- [ ] 分布式任务执行
- [ ] 社区插件系统

## 文件结构

```
openclaw-smart-task-manager/
├── README.md                    # 主README（双语）
├── DOCUMENTATION.md             # 完整文档
├── CHANGELOG.md                 # 版本历史
├── MAINTAINER_GUIDE.md         # 本文件
├── GITHUB_PUSH_GUIDE.md        # GitHub推送指南
├── LICENSE                      # MIT许可证
├── .gitignore                   # Git忽略规则
├── auto-update.sh              # 自动更新脚本
├── smart-task-manager.sh       # 主优化脚本
├── check-status.sh             # 状态检查脚本
├── smart-task.skill.json       # Skill定义
└── TASK_BREAKDOWN.md          # 任务分解模板
```

## 常用命令速查

```bash
# 快速推送更新
cd ~/openclaw-smart-task-manager && ./auto-update.sh

# 查看仓库
gh repo view --web

# 查看统计
gh repo view wansong24/openclaw-smart-task-manager

# 克隆到其他机器
gh repo clone wansong24/openclaw-smart-task-manager

# 查看stars和forks
gh api repos/wansong24/openclaw-smart-task-manager | jq '{stars: .stargazers_count, forks: .forks_count}'
```

## 备份策略

仓库已经在GitHub上，但建议：
1. 定期导出重要配置
2. 保留本地备份
3. 使用GitHub的Archive功能

## 社区互动

### 回复Issues
```bash
gh issue comment ISSUE_NUMBER --body "回复内容"
```

### 感谢贡献者
在PR合并后：
```bash
gh pr comment PR_NUMBER --body "感谢你的贡献！🎉"
```

### 发布公告
在README中添加徽章：
```markdown
![GitHub stars](https://img.shields.io/github/stars/wansong24/openclaw-smart-task-manager)
![GitHub forks](https://img.shields.io/github/forks/wansong24/openclaw-smart-task-manager)
![GitHub issues](https://img.shields.io/github/issues/wansong24/openclaw-smart-task-manager)
```

## 故障排除

### 推送失败
```bash
# 强制同步（谨慎使用）
git fetch origin
git reset --hard origin/main
```

### 权限问题
```bash
# 重新登录
gh auth logout
gh auth login
```

### 冲突解决
```bash
# 查看冲突
git status

# 手动解决后
git add .
git commit -m "Resolve conflicts"
git push
```

## 联系方式

- **GitHub**: @wansong24
- **仓库**: https://github.com/wansong24/openclaw-smart-task-manager
- **Issues**: https://github.com/wansong24/openclaw-smart-task-manager/issues

---

**最后更新**: 2026-02-16
**维护者**: Claude Code + wansong24
