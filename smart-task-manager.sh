#!/bin/bash
# Smart Task Manager for OpenClaw
# 智能任务管理器 - 解决大任务超时问题
#
# 策略：
# 1. 任务分解：将大任务分解为小任务
# 2. 自动压缩：在任务执行前主动压缩上下文
# 3. 故障转移：配置模型回退机制
# 4. 进度跟踪：记录任务执行状态

set -e

OPENCLAW_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
OPENCLAW_VI_DIR="$HOME/.openclaw-vi"
LOG_FILE="$OPENCLAW_DIR/logs/smart-task-manager.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# 检查配置文件
check_config() {
    local config_file="$1"
    if [ ! -f "$config_file" ]; then
        log "错误: 配置文件不存在: $config_file"
        return 1
    fi
    log "检查配置: $config_file"
}

# 优化配置 - 添加智能超时和故障转移
optimize_config() {
    local config_file="$1"
    local instance_name="$2"

    log "优化 $instance_name 配置..."

    # 备份原配置
    cp "$config_file" "${config_file}.backup-$(date +%Y%m%d-%H%M%S)"

    # 使用 jq 更新配置（如果没有jq，提示安装）
    if ! command -v jq &> /dev/null; then
        log "警告: 需要安装 jq 来自动优化配置"
        log "请运行: brew install jq"
        return 1
    fi

    # 读取当前配置
    local current_config=$(cat "$config_file")

    # 优化配置
    echo "$current_config" | jq '
        # 设置合理的超时时间（30分钟）
        .agents.defaults.timeoutSeconds = 1800 |

        # 启用自动压缩（safeguard模式）
        .agents.defaults.compaction.mode = "safeguard" |

        # 配置上下文修剪
        .agents.defaults.contextPruning = {
            "mode": "cache-ttl",
            "enabled": true
        } |

        # 配置会话重置策略
        .session.reset = {
            "mode": "daily",
            "atHour": 4,
            "idleMinutes": 10080
        } |

        # 配置并发限制
        .agents.defaults.maxConcurrent = 2 |
        .agents.defaults.subagents.maxConcurrent = 4 |

        # 配置心跳（主动检查）
        .agents.defaults.heartbeat = {
            "every": "30m"
        }
    ' > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"

    log "✓ $instance_name 配置已优化"
}

# 配置模型故障转移
setup_failover() {
    local config_file="$1"
    local instance_name="$2"

    log "配置 $instance_name 模型故障转移..."

    if ! command -v jq &> /dev/null; then
        return 1
    fi

    local current_config=$(cat "$config_file")
    local primary_model=$(echo "$current_config" | jq -r '.agents.defaults.model.primary // empty')

    if [ -z "$primary_model" ]; then
        log "警告: 未找到主模型配置"
        return 1
    fi

    # 根据主模型配置回退模型
    local fallback_models='[]'

    if [[ "$primary_model" == *"minimax"* ]]; then
        # MiniMax 主模型，回退到智谱AI
        fallback_models='["zai/glm-5"]'
    elif [[ "$primary_model" == *"zai"* ]] || [[ "$primary_model" == *"glm"* ]]; then
        # 智谱AI 主模型，回退到MiniMax
        fallback_models='["minimax/MiniMax-M2.5"]'
    fi

    echo "$current_config" | jq --argjson fallbacks "$fallback_models" '
        .agents.defaults.model.fallbacks = $fallbacks
    ' > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"

    log "✓ $instance_name 故障转移已配置"
}

# 创建任务分解提示文件
create_task_breakdown_prompt() {
    local workspace="$1"
    local prompt_file="$workspace/TASK_BREAKDOWN.md"

    cat > "$prompt_file" << 'EOF'
# 任务分解策略

当收到大型任务时，请遵循以下策略：

## 1. 任务评估
- 评估任务复杂度和预计执行时间
- 如果任务预计超过15分钟，主动分解

## 2. 分解原则
- 将大任务分解为多个独立的小任务
- 每个小任务应该在10-15分钟内完成
- 确保任务之间有明确的依赖关系

## 3. 执行策略
- 逐个执行小任务
- 每个任务完成后，使用 `/compact` 压缩上下文
- 记录进度到 PROGRESS.md

## 4. 错误处理
- 如果遇到超时，立即压缩上下文并重试
- 如果模型API失败，会自动切换到备用模型
- 记录所有错误到日志

## 5. 进度跟踪
在 PROGRESS.md 中记录：
- 任务列表
- 当前进度
- 遇到的问题
- 下一步计划
EOF

    log "✓ 创建任务分解提示: $prompt_file"
}

# 主函数
main() {
    log "=========================================="
    log "OpenClaw 智能任务管理器"
    log "=========================================="

    # 检查并优化第一个实例
    if [ -f "$OPENCLAW_DIR/openclaw.json" ]; then
        check_config "$OPENCLAW_DIR/openclaw.json"
        optimize_config "$OPENCLAW_DIR/openclaw.json" "实例1"
        setup_failover "$OPENCLAW_DIR/openclaw.json" "实例1"
        create_task_breakdown_prompt "$OPENCLAW_DIR/workspace"
    fi

    # 检查并优化第二个实例（Vi）
    if [ -f "$OPENCLAW_VI_DIR/openclaw.json" ]; then
        check_config "$OPENCLAW_VI_DIR/openclaw.json"
        optimize_config "$OPENCLAW_VI_DIR/openclaw.json" "实例2(Vi)"
        setup_failover "$OPENCLAW_VI_DIR/openclaw.json" "实例2(Vi)"
        create_task_breakdown_prompt "$OPENCLAW_VI_DIR/workspace"
    fi

    log "=========================================="
    log "优化完成！建议重启 gateway 服务："
    log "launchctl bootout gui/\$(id -u)/ai.openclaw.gateway"
    log "launchctl bootout gui/\$(id -u)/ai.openclaw-vi.gateway"
    log "launchctl bootstrap gui/\$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist"
    log "launchctl bootstrap gui/\$(id -u) ~/Library/LaunchAgents/ai.openclaw-vi.gateway.plist"
    log "=========================================="
}

main "$@"
