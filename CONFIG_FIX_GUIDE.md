# OpenClaw 配置错误修复指南

## 常见错误：contextPruning.enabled

### 问题描述

OpenClaw 不支持 `agents.defaults.contextPruning.enabled` 字段，如果配置文件中包含此字段，会导致：

- Gateway 服务无法启动
- 配置验证失败
- 错误信息：`Unrecognized key: "enabled"`

### 错误配置示例

```json
{
  "agents": {
    "defaults": {
      "contextPruning": {
        "mode": "cache-ttl",
        "enabled": true  // ❌ 这个字段不支持！
      }
    }
  }
}
```

### 正确配置

```json
{
  "agents": {
    "defaults": {
      "contextPruning": {
        "mode": "cache-ttl"  // ✅ 只需要 mode 字段
      }
    }
  }
}
```

## 自动修复

### 方法1：运行修复脚本

```bash
~/.openclaw/scripts/fix-config.sh
```

此脚本会：
1. 自动检测无效配置项
2. 备份原配置文件
3. 删除不支持的字段
4. 验证修复后的配置
5. 重启 Gateway 服务

### 方法2：手动修复

```bash
# 删除 contextPruning.enabled 字段
jq 'del(.agents.defaults.contextPruning.enabled)' ~/.openclaw/openclaw.json > ~/.openclaw/openclaw.json.tmp
mv ~/.openclaw/openclaw.json.tmp ~/.openclaw/openclaw.json

# 验证配置
openclaw doctor --fix

# 重启服务
openclaw gateway restart
```

## 预防措施

### 1. 使用正确的配置模板

本项目的 `smart-task-manager.sh` 已修复，只设置支持的字段：

```bash
.agents.defaults.contextPruning.mode = "cache-ttl"
```

### 2. 安装后自动检查

安装脚本 `install.sh` 会自动运行配置修复：

```bash
curl -fsSL https://raw.githubusercontent.com/wansong24/openclaw-smart-task-manager/main/install.sh | bash
```

### 3. 定期验证配置

```bash
# 检查配置是否有效
openclaw doctor

# 如果发现错误，运行修复
openclaw doctor --fix
```

## 其他不支持的字段

除了 `contextPruning.enabled`，以下字段也不被支持：

- `agents.defaults.model.quickModel`
- `agents.defaults.model.tiers`
- `agents.defaults.streaming`
- `agents.defaults.routing`
- `agents.defaults.api`
- `agents.defaults.cache`

修复脚本会自动删除这些字段。

## 支持的配置字段

### contextPruning（上下文修剪）

```json
{
  "agents": {
    "defaults": {
      "contextPruning": {
        "mode": "cache-ttl"  // 支持的值: "cache-ttl", "off"
      }
    }
  }
}
```

### compaction（上下文压缩）

```json
{
  "agents": {
    "defaults": {
      "compaction": {
        "mode": "safeguard"  // 支持的值: "safeguard", "aggressive", "off"
      }
    }
  }
}
```

### 完整的推荐配置

```json
{
  "agents": {
    "defaults": {
      "timeoutSeconds": 1800,
      "maxConcurrent": 2,
      "compaction": {
        "mode": "safeguard"
      },
      "contextPruning": {
        "mode": "cache-ttl"
      },
      "model": {
        "primary": "your-model",
        "fallbacks": ["backup-model"]
      },
      "heartbeat": {
        "every": "30m"
      },
      "subagents": {
        "maxConcurrent": 4
      }
    }
  },
  "session": {
    "reset": {
      "mode": "daily",
      "atHour": 4,
      "idleMinutes": 10080
    }
  }
}
```

## 故障排查

### 问题：Gateway 无法启动

```bash
# 1. 检查日志
tail -50 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log | grep -i error

# 2. 运行配置修复
~/.openclaw/scripts/fix-config.sh

# 3. 验证配置
openclaw doctor --fix

# 4. 重启服务
openclaw gateway restart
```

### 问题：配置修复后仍然报错

```bash
# 1. 检查是否有多个配置文件
ls -la ~/.openclaw*/openclaw.json

# 2. 对每个实例运行修复
OPENCLAW_STATE_DIR=~/.openclaw openclaw doctor --fix
OPENCLAW_STATE_DIR=~/.openclaw-vi openclaw doctor --fix

# 3. 手动检查配置
jq '.agents.defaults.contextPruning' ~/.openclaw/openclaw.json
jq '.agents.defaults.contextPruning' ~/.openclaw-vi/openclaw.json
```

## 联系支持

如果问题仍未解决：

1. 查看完整日志：`cat /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log`
2. 提交 Issue：https://github.com/wansong24/openclaw-smart-task-manager/issues
3. 包含以下信息：
   - OpenClaw 版本：`openclaw --version`
   - 错误日志
   - 配置文件内容（删除敏感信息）

## 更新日志

- 2026-02-16: 修复 `smart-task-manager.sh` 中的 `contextPruning.enabled` 错误
- 2026-02-16: 增强 `fix-config.sh` 自动检测和修复功能
- 2026-02-16: 添加配置验证到安装流程
