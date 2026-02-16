# OpenClaw Smart Task Manager

[English](#english) | [中文](#中文)

---

## English

### Overview

A smart task management system for OpenClaw that solves timeout issues when handling large tasks. Based on community best practices from Moltbook and OpenClaw documentation.

### Problem

OpenClaw agents may timeout when executing large, complex tasks that take longer than the default timeout period (10 minutes).

### Solution

Instead of simply extending the timeout indefinitely, this system implements intelligent task management:

1. **Smart Timeout Management** (30 minutes with auto-compaction)
2. **Model Failover** (automatic fallback to backup models)
3. **Task Decomposition** (break large tasks into 10-15 minute chunks)
4. **Context Pruning** (cache-ttl mode for efficient memory usage)
5. **Concurrency Control** (prevent resource competition)
6. **Heartbeat Monitoring** (proactive health checks every 30 minutes)

### Features

- ✅ Automatic configuration optimization
- ✅ Dual-instance support (main + backup)
- ✅ Model failover between providers
- ✅ Task breakdown prompts
- ✅ Progress tracking
- ✅ Status monitoring scripts
- ✅ Configuration auto-fix (removes invalid keys)
- ✅ Comprehensive documentation

### Installation

**One-Click Install (Recommended):**

```bash
curl -fsSL https://raw.githubusercontent.com/wansong24/openclaw-smart-task-manager/main/install.sh | bash
```

Or using wget:

```bash
wget -qO- https://raw.githubusercontent.com/wansong24/openclaw-smart-task-manager/main/install.sh | bash
```

**Manual Installation:**

```bash
# Clone the repository
git clone https://github.com/wansong24/openclaw-smart-task-manager.git
cd openclaw-smart-task-manager

# Run the optimization script
chmod +x smart-task-manager.sh
./smart-task-manager.sh

# Restart OpenClaw gateway services (macOS)
launchctl bootout gui/$(id -u)/ai.openclaw.gateway
launchctl bootout gui/$(id -u)/ai.openclaw-vi.gateway
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw-vi.gateway.plist
```

### Usage

**Check system status:**
```bash
~/.openclaw/scripts/check-status.sh
```

**Test configuration validity:**
```bash
~/.openclaw/scripts/test-config.sh
```

**Fix configuration errors:**
```bash
~/.openclaw/scripts/fix-config.sh
```

**In chat:**
- AI will automatically decompose large tasks
- Use `/compact` to manually compress context
- Use `/status` to check session status
- Use `/new` or `/reset` to start fresh

### Configuration

The system configures both OpenClaw instances with:

```json
{
  "timeoutSeconds": 1800,
  "maxConcurrent": 2,
  "compaction": {
    "mode": "safeguard"
  },
  "contextPruning": {
    "mode": "cache-ttl"
  },
  "model": {
    "primary": "...",
    "fallbacks": ["..."]
  },
  "heartbeat": {
    "every": "30m"
  }
}
```

### Files

- `smart-task-manager.sh` - Main optimization script
- `check-status.sh` - Status monitoring script
- `fix-config.sh` - Configuration auto-fix script
- `test-config.sh` - Configuration validation test
- `smart-task.skill.json` - Skill definition
- `TASK_BREAKDOWN.md` - Task decomposition prompt template
- `DOCUMENTATION.md` - Complete documentation (Chinese)
- `CONFIG_FIX_GUIDE.md` - Configuration error fix guide

### Best Practices Sources

- [Fix LLM Provider Hangs With First-Token Timeout](https://magazine.ediary.site/blog/openclaw-fix-llm-provider-hangs)
- [8 Ways to Stop Agents from Losing Context](https://codepointer.substack.com/p/openclaw-stop-losing-context-8-techniques)
- [How Clawdbot Performs Multi-Step Workflows](https://skywork.ai/blog/ai-agent/clawdbot-multi-step-workflows-guide/)
- [Best Practices for Reliable Agents](https://skywork.ai/blog/clawdbot-agent-design-best-practices/)

### Requirements

- OpenClaw 2026.2.14+
- macOS (tested) / Linux (should work)
- jq (for JSON processing)
- Multiple model providers configured (for failover)

### License

MIT

### Contributing

Issues and pull requests are welcome!

---

## 中文

### 概述

OpenClaw智能任务管理系统，解决大任务超时问题。基于Moltbook社区和OpenClaw官方文档的最佳实践。

### 问题

OpenClaw在执行大型复杂任务时可能会超时（默认10分钟）。

### 解决方案

不是简单地延长超时时间，而是实现智能任务管理：

1. **智能超时管理**（30分钟+自动压缩）
2. **模型故障转移**（自动切换到备用模型）
3. **任务分解**（将大任务分解为10-15分钟的小任务）
4. **上下文修剪**（cache-ttl模式高效使用内存）
5. **并发控制**（防止资源竞争）
6. **心跳监控**（每30分钟主动检查）

### 功能特性

- ✅ 自动配置优化
- ✅ 双实例支持（主+备）
- ✅ 多模型故障转移
- ✅ 任务分解提示
- ✅ 进度跟踪
- ✅ 状态监控脚本
- ✅ 完整文档

### 安装

**一键安装（推荐）：**

```bash
curl -fsSL https://raw.githubusercontent.com/wansong24/openclaw-smart-task-manager/main/install.sh | bash
```

或使用wget：

```bash
wget -qO- https://raw.githubusercontent.com/wansong24/openclaw-smart-task-manager/main/install.sh | bash
```

**手动安装：**

```bash
# 克隆仓库
git clone https://github.com/wansong24/openclaw-smart-task-manager.git
cd openclaw-smart-task-manager

# 运行优化脚本
chmod +x smart-task-manager.sh
./smart-task-manager.sh

# 重启OpenClaw gateway服务（macOS）
launchctl bootout gui/$(id -u)/ai.openclaw.gateway
launchctl bootout gui/$(id -u)/ai.openclaw-vi.gateway
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw-vi.gateway.plist
```

### 使用方法

**检查系统状态：**
```bash
./check-status.sh
```

**在聊天中：**
- AI会自动分解大任务
- 使用 `/compact` 手动压缩上下文
- 使用 `/status` 查看会话状态
- 使用 `/new` 或 `/reset` 开始新会话

### 配置说明

系统会为两个OpenClaw实例配置：

```json
{
  "timeoutSeconds": 1800,
  "maxConcurrent": 2,
  "compaction": {
    "mode": "safeguard"
  },
  "contextPruning": {
    "mode": "cache-ttl"
  },
  "model": {
    "primary": "...",
    "fallbacks": ["..."]
  },
  "heartbeat": {
    "every": "30m"
  }
}
```

### 文件说明

- `smart-task-manager.sh` - 主优化脚本
- `check-status.sh` - 状态监控脚本
- `smart-task.skill.json` - Skill定义
- `TASK_BREAKDOWN.md` - 任务分解提示模板
- `DOCUMENTATION.md` - 完整文档

### 最佳实践来源

- [修复LLM提供商挂起问题](https://magazine.ediary.site/blog/openclaw-fix-llm-provider-hangs)
- [防止智能体丢失上下文的8种方法](https://codepointer.substack.com/p/openclaw-stop-losing-context-8-techniques)
- [Clawdbot如何执行多步骤工作流](https://skywork.ai/blog/ai-agent/clawdbot-multi-step-workflows-guide/)
- [可靠智能体的最佳实践](https://skywork.ai/blog/clawdbot-agent-design-best-practices/)

### 系统要求

- OpenClaw 2026.2.14+
- macOS（已测试）/ Linux（应该可用）
- jq（用于JSON处理）
- 配置多个模型提供商（用于故障转移）

### 许可证

MIT

### 贡献

欢迎提交Issue和Pull Request！

### 作者

由Claude Code协助创建

### 致谢

感谢OpenClaw社区和Moltbook平台的最佳实践分享。
