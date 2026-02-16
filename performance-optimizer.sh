#!/bin/bash
# OpenClaw 简化性能优化
# 使用OpenClaw原生支持的配置

set -e

OPENCLAW_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
OPENCLAW_VI_DIR="$HOME/.openclaw-vi"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

optimize_simple() {
    local config_file="$1"
    local instance_name="$2"

    log "优化 $instance_name..."

    if ! command -v jq &> /dev/null; then
        log "错误: 需要jq"
        return 1
    fi

    cp "$config_file" "${config_file}.backup-simple-$(date +%Y%m%d-%H%M%S)"

    # 使用OpenClaw原生支持的配置
    jq '
        # 提高并发（更快处理多个请求）
        .agents.defaults.maxConcurrent = 3 |
        .agents.defaults.subagents.maxConcurrent = 8 |

        # 减少心跳频率（降低后台负载）
        .agents.defaults.heartbeat.every = "60m" |

        # 优化会话重置
        .session.reset.idleMinutes = 1440
    ' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"

    log "✓ $instance_name 优化完成"
}

log "=========================================="
log "OpenClaw 性能优化（简化版）"
log "=========================================="

# 优化两个实例
[ -f "$OPENCLAW_DIR/openclaw.json" ] && optimize_simple "$OPENCLAW_DIR/openclaw.json" "实例1"
[ -f "$OPENCLAW_VI_DIR/openclaw.json" ] && optimize_simple "$OPENCLAW_VI_DIR/openclaw.json" "实例2(Vi)"

log ""
log "优化完成！主要改进："
log "  ✓ 提高并发能力（3主任务+8子任务）"
log "  ✓ 减少心跳频率（60分钟）"
log "  ✓ 优化会话重置策略"
log ""
log "建议重启Gateway服务"
log "=========================================="
