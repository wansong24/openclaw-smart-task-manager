#!/bin/bash
# 快速检查openclaw智能任务管理系统状态

echo "=========================================="
echo "OpenClaw 智能任务管理系统 - 状态检查"
echo "=========================================="
echo ""

# 检查进程
echo "📊 进程状态:"
if ps aux | grep -E "openclaw-gateway" | grep -v grep > /dev/null; then
    echo "  ✓ Gateway进程运行中"
    ps aux | grep openclaw-gateway | grep -v grep | awk '{print "    PID:", $2, "内存:", $6/1024"MB"}'
else
    echo "  ✗ Gateway进程未运行"
fi
echo ""

# 检查端口
echo "🔌 端口监听:"
lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | grep -E "18789|18790" | awk '{print "  ", $1, $9}' || echo "  未找到监听端口"
echo ""

# 检查配置
echo "⚙️  实例1配置:"
if [ -f ~/.openclaw/openclaw.json ]; then
    jq -r '.agents.defaults | "  超时: \(.timeoutSeconds)秒, 压缩: \(.compaction.mode), 并发: \(.maxConcurrent), 主模型: \(.model.primary)"' ~/.openclaw/openclaw.json 2>/dev/null || echo "  配置读取失败"
    jq -r '.agents.defaults.model.fallbacks | if . then "  故障转移: \(.[0])" else "  故障转移: 未配置" end' ~/.openclaw/openclaw.json 2>/dev/null
else
    echo "  配置文件不存在"
fi
echo ""

echo "⚙️  实例2(Vi)配置:"
if [ -f ~/.openclaw-vi/openclaw.json ]; then
    jq -r '.agents.defaults | "  超时: \(.timeoutSeconds)秒, 压缩: \(.compaction.mode), 并发: \(.maxConcurrent), 主模型: \(.model.primary)"' ~/.openclaw-vi/openclaw.json 2>/dev/null || echo "  配置读取失败"
    jq -r '.agents.defaults.model.fallbacks | if . then "  故障转移: \(.[0])" else "  故障转移: 未配置" end' ~/.openclaw-vi/openclaw.json 2>/dev/null
else
    echo "  配置文件不存在"
fi
echo ""

# 检查最近的错误
echo "⚠️  最近的错误（最近10条）:"
if [ -f ~/.openclaw/logs/gateway.err.log ]; then
    tail -10 ~/.openclaw/logs/gateway.err.log | grep -E "error|timeout|fail" | tail -3 || echo "  无错误"
else
    echo "  日志文件不存在"
fi
echo ""

# 检查任务分解提示文件
echo "📝 任务分解提示:"
if [ -f ~/.openclaw/workspace/TASK_BREAKDOWN.md ]; then
    echo "  ✓ 实例1: ~/.openclaw/workspace/TASK_BREAKDOWN.md"
else
    echo "  ✗ 实例1: 未找到"
fi
if [ -f ~/.openclaw-vi/workspace/TASK_BREAKDOWN.md ]; then
    echo "  ✓ 实例2(Vi): ~/.openclaw-vi/workspace/TASK_BREAKDOWN.md"
else
    echo "  ✗ 实例2(Vi): 未找到"
fi
echo ""

echo "=========================================="
echo "💡 提示:"
echo "  - 查看完整文档: cat ~/.openclaw/scripts/SMART_TASK_README.md"
echo "  - 重新优化: ~/.openclaw/scripts/smart-task-manager.sh"
echo "  - 查看日志: tail -f /tmp/openclaw/openclaw-\$(date +%Y-%m-%d).log"
echo "=========================================="
