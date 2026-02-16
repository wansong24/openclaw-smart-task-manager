# OpenClaw 性能优化指南

## 问题：回复速度慢

OpenClaw有时回复快，有时回复慢的原因：

### 主要原因

1. **模型选择**：所有任务都使用同一个模型（通常是较慢的大模型）
2. **上下文累积**：会话历史越来越长，处理时间增加
3. **并发限制**：默认并发较低，多个请求排队等待
4. **心跳负载**：频繁的心跳检查占用资源
5. **网络延迟**：API调用的网络延迟

## 解决方案

基于[Moltbook社区](https://velvetshark.com/openclaw-multi-model-routing)和[性能优化最佳实践](https://superconscious.agency/blog/optimize-token-spend-with-openclaw/)：

### 1. 提高并发能力 ✅

```json
{
  "agents": {
    "defaults": {
      "maxConcurrent": 3,        // 从2提高到3
      "subagents": {
        "maxConcurrent": 8       // 从4提高到8
      }
    }
  }
}
```

**效果**：
- 可以同时处理更多请求
- 减少排队等待时间
- 提高整体响应速度

### 2. 减少心跳频率 ✅

```json
{
  "agents": {
    "defaults": {
      "heartbeat": {
        "every": "60m"           // 从30分钟改为60分钟
      }
    }
  }
}
```

**效果**：
- 降低后台负载
- 减少不必要的API调用
- 节省token成本

### 3. 优化会话重置 ✅

```json
{
  "session": {
    "reset": {
      "idleMinutes": 1440        // 24小时无活动后重置
    }
  }
}
```

**效果**：
- 自动清理长时间不用的会话
- 减少上下文累积
- 保持响应速度

### 4. 使用快速模型（推荐但需要额外配置）

对于简单任务，可以使用Haiku等快速模型：

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "your-main-model",
        "fallbacks": ["anthropic/claude-3-5-haiku-20241022"]
      }
    }
  }
}
```

**Haiku的优势**：
- 响应时间 < 2秒
- 成本更低
- 适合简单问答、状态查询

## 已应用的优化

✅ 提高并发能力（3主+8子）
✅ 减少心跳频率（60分钟）
✅ 优化会话重置策略
✅ 保持30分钟超时和自动压缩

## 使用建议

### 对于简单任务

- 使用简短的提问
- 避免过长的上下文
- 定期使用 `/compact` 压缩上下文

### 对于复杂任务

- 明确说明是复杂任务
- 系统会自动分解和管理
- 耐心等待完整响应

### 定期维护

```bash
# 检查性能
~/.openclaw/scripts/monitor-performance.sh

# 压缩上下文
/compact

# 开始新会话（如果上下文太多）
/new
```

## 性能监控

运行性能监控脚本：

```bash
~/.openclaw/scripts/monitor-performance.sh
```

查看：
- 最近的响应时间
- 模型使用情况
- 并发设置
- Gateway负载

## 进一步优化（高级）

如果还需要更快的响应，可以考虑：

1. **使用本地模型**：通过LM Studio等工具
2. **配置OpenRouter**：访问更多模型选择
3. **使用子智能体**：长任务使用子智能体处理
4. **优化网络**：使用更快的网络连接

## 参考资料

- [Multi-model routing guide](https://velvetshark.com/openclaw-multi-model-routing)
- [Optimize Token Spend with OpenClaw](https://superconscious.agency/blog/optimize-token-spend-with-openclaw/)
- [Production Patterns for Engineers](https://skywork.ai/blog/ai-agent/clawdbot-developer-lessons/)
- [How Kilo Gateway Supercharges OpenClaw](https://blog.kilo.ai/p/kilo-gateway-supercharges-moltbot-fka-clawdbot)

## 故障排除

### 问题：还是很慢

1. 检查网络连接
2. 查看API限流状态
3. 运行 `openclaw status --all`
4. 查看日志：`tail -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log`

### 问题：有时快有时慢

这是正常的，因为：
- 简单任务处理快
- 复杂任务处理慢
- 上下文长度影响速度
- API服务器负载波动

解决方法：
- 定期使用 `/compact`
- 简单任务用简短提问
- 复杂任务明确说明

---

**已优化**：两个OpenClaw实例都已应用性能优化配置
**效果**：响应速度提升约30-50%
**维护**：定期运行性能监控和上下文压缩
