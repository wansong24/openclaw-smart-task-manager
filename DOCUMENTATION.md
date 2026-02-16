# OpenClaw 智能任务管理系统

## 概述

这个智能任务管理系统解决了openclaw在处理大型任务时的超时问题，采用了业界最佳实践。

## 核心策略

### 1. 多层超时保护
- **合理的超时时间**：30分钟（1800秒），而不是无限延长
- **自动压缩**：使用safeguard模式，在接近上下文限制时自动压缩
- **上下文修剪**：使用cache-ttl模式，智能清理旧的工具结果

### 2. 模型故障转移
- **实例1**：MiniMax → 智谱AI GLM-5
- **实例2(Vi)**：智谱AI GLM-5 → MiniMax
- 当一个模型API失败时，自动切换到备用模型

### 3. 任务分解策略
系统会自动提示AI助手：
- 评估任务复杂度
- 将大任务分解为10-15分钟的小任务
- 逐个执行，定期压缩上下文
- 记录进度到PROGRESS.md

### 4. 并发控制
- 主任务并发：2个
- 子任务并发：4个
- 防止资源竞争和内存溢出

### 5. 心跳监控
- 每30分钟主动检查
- 及时发现和处理问题

## 使用方法

### 自动优化（已完成）
系统已经自动优化了两个openclaw实例的配置。

### 手动命令

#### 查看配置状态
\`\`\`bash
jq '.agents.defaults' ~/.openclaw/openclaw.json
jq '.agents.defaults' ~/.openclaw-vi/openclaw.json
\`\`\`

#### 在聊天中使用
当执行大任务时，AI会自动：
1. 评估任务复杂度
2. 分解为小任务
3. 定期使用 \`/compact\` 压缩上下文
4. 记录进度

你也可以手动使用：
- \`/compact\` - 压缩当前会话上下文
- \`/status\` - 查看会话状态
- \`/new\` 或 \`/reset\` - 开始新会话

#### 重新运行优化
\`\`\`bash
~/.openclaw/scripts/smart-task-manager.sh
\`\`\`

## 配置详情

### 当前配置（两个实例）

\`\`\`json
{
  "timeoutSeconds": 1800,           // 30分钟超时
  "maxConcurrent": 2,                // 最多2个并发任务
  "compaction": {
    "mode": "safeguard"              // 智能压缩模式
  },
  "contextPruning": {
    "mode": "cache-ttl"              // 基于缓存TTL的修剪
  },
  "model": {
    "primary": "...",
    "fallbacks": ["..."]             // 故障转移模型
  },
  "heartbeat": {
    "every": "30m"                   // 30分钟心跳
  },
  "session": {
    "reset": {
      "mode": "daily",               // 每天重置
      "atHour": 4,                   // 凌晨4点
      "idleMinutes": 10080           // 7天无活动后重置
    }
  }
}
\`\`\`

## 工作原理

### 问题：大任务超时
- 原因：任务执行时间超过超时限制
- 传统方案：简单延长超时时间（不可行，可能无限等待）

### 解决方案：智能任务管理

#### 1. 任务分解
\`\`\`
大任务（60分钟）
  ↓ 分解
小任务1（10分钟）→ 完成 → /compact
小任务2（10分钟）→ 完成 → /compact
小任务3（10分钟）→ 完成 → /compact
...
\`\`\`

#### 2. 上下文管理
\`\`\`
会话开始 → 执行任务 → 上下文增长
  ↓
接近限制 → 自动压缩 → 继续执行
  ↓
定期压缩 → 保持上下文清洁
\`\`\`

#### 3. 故障转移
\`\`\`
主模型API调用
  ↓ 失败（超时/限流/认证）
自动切换到备用模型
  ↓ 继续执行
任务完成
\`\`\`

## 最佳实践（来自社区）

### 来源
- [Fix LLM Provider Hangs With First-Token Timeout](https://magazine.ediary.site/blog/openclaw-fix-llm-provider-hangs)
- [8 Ways to Stop Agents from Losing Context](https://codepointer.substack.com/p/openclaw-stop-losing-context-8-techniques)
- [How Clawdbot Performs Multi-Step Workflows](https://skywork.ai/blog/ai-agent/clawdbot-multi-step-workflows-guide/)
- [Best Practices for Reliable Agents](https://skywork.ai/blog/clawdbot-agent-design-best-practices/)

### 核心原则
1. **任务分解优于延长超时**
2. **主动压缩优于被动等待**
3. **故障转移优于单点依赖**
4. **进度跟踪优于黑盒执行**

## 监控和调试

### 查看日志
\`\`\`bash
# 主日志
tail -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log

# Gateway日志
tail -f ~/.openclaw/logs/gateway.log
tail -f ~/.openclaw-vi/logs/gateway.log

# 错误日志
tail -f ~/.openclaw/logs/gateway.err.log
tail -f ~/.openclaw-vi/logs/gateway.err.log
\`\`\`

### 检查进程
\`\`\`bash
ps aux | grep openclaw-gateway
lsof -nP -iTCP -sTCP:LISTEN | grep openclaw
\`\`\`

### 检查配置
\`\`\`bash
openclaw status --all
openclaw doctor
\`\`\`

## 故障排除

### 问题：任务仍然超时
**解决**：
1. 检查任务是否被正确分解
2. 手动使用 \`/compact\` 压缩上下文
3. 查看日志确认是否触发了故障转移

### 问题：模型切换频繁
**解决**：
1. 检查API密钥是否有效
2. 查看是否遇到限流
3. 考虑增加冷却时间

### 问题：上下文丢失
**解决**：
1. 使用PROGRESS.md记录进度
2. 定期使用 \`/compact\` 而不是 \`/new\`
3. 检查compaction配置

## 文件位置

- 优化脚本：\`~/.openclaw/scripts/smart-task-manager.sh\`
- Skill配置：\`~/.openclaw/scripts/smart-task.skill.json\`
- 任务分解提示：\`~/.openclaw/workspace/TASK_BREAKDOWN.md\`
- 任务分解提示（Vi）：\`~/.openclaw-vi/workspace/TASK_BREAKDOWN.md\`
- 日志：\`~/.openclaw/logs/smart-task-manager.log\`

## 下一步

1. 测试大型任务，观察是否还会超时
2. 查看PROGRESS.md中的任务分解记录
3. 根据实际使用情况调整配置
4. 考虑在Moltbook社区分享经验

---

**注意**：这个系统基于openclaw官方文档和社区最佳实践，不是简单地延长超时时间，而是从根本上解决大任务管理问题。
