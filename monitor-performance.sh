#!/bin/bash
# 性能监控脚本

echo "=========================================="
echo "OpenClaw 性能监控"
echo "=========================================="
echo ""

# 检查响应时间
echo "📊 最近的响应时间："
if [ -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log ]; then
    grep -E "embedded run agent end" /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log | tail -5 | while read line; do
        echo "  $line"
    done
else
    echo "  未找到日志文件"
fi
echo ""

# 检查模型使用情况
echo "🤖 模型使用统计："
if command -v jq &> /dev/null; then
    if [ -f ~/.openclaw/openclaw.json ]; then
        echo "  主模型: $(jq -r '.agents.defaults.model.primary' ~/.openclaw/openclaw.json)"
        echo "  快速模型: $(jq -r '.agents.defaults.model.quickModel // "未配置"' ~/.openclaw/openclaw.json)"
    fi
fi
echo ""

# 检查并发任务
echo "⚡ 并发设置："
if command -v jq &> /dev/null; then
    if [ -f ~/.openclaw/openclaw.json ]; then
        echo "  主任务并发: $(jq -r '.agents.defaults.maxConcurrent' ~/.openclaw/openclaw.json)"
        echo "  子任务并发: $(jq -r '.agents.defaults.subagents.maxConcurrent' ~/.openclaw/openclaw.json)"
    fi
fi
echo ""

# 检查Gateway负载
echo "💻 Gateway进程状态："
ps aux | grep openclaw-gateway | grep -v grep | awk '{print "  PID:", $2, "CPU:", $3"%", "内存:", $6/1024"MB"}'
echo ""

echo "=========================================="
