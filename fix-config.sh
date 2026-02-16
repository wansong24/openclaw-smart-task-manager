#!/bin/bash
# OpenClaw 配置自动修复脚本
# 自动检测并修复常见的配置错误

set -e

OPENCLAW_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
OPENCLAW_VI_DIR="$HOME/.openclaw-vi"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

fix_config() {
    local config_file="$1"
    local instance_name="$2"

    if [ ! -f "$config_file" ]; then
        log "⚠️  配置文件不存在: $config_file"
        return 1
    fi

    log "检查 $instance_name 配置..."

    # 备份配置
    cp "$config_file" "${config_file}.backup-fix-$(date +%Y%m%d-%H%M%S)"

    # 检查并修复已知的无效配置项
    local fixed=0

    # 1. 删除 contextPruning.enabled（不支持的字段）
    if jq -e '.agents.defaults.contextPruning.enabled' "$config_file" > /dev/null 2>&1; then
        log "  修复: 删除 contextPruning.enabled"
        jq 'del(.agents.defaults.contextPruning.enabled)' "$config_file" > "${config_file}.tmp"
        mv "${config_file}.tmp" "$config_file"
        fixed=1
    fi

    # 2. 如果 contextPruning 是对象且包含 enabled，转换为只保留 mode
    if jq -e '.agents.defaults.contextPruning | type == "object" and has("enabled")' "$config_file" > /dev/null 2>&1; then
        log "  修复: 重构 contextPruning 配置"
        local mode=$(jq -r '.agents.defaults.contextPruning.mode // "cache-ttl"' "$config_file")
        jq --arg mode "$mode" '.agents.defaults.contextPruning = {"mode": $mode}' "$config_file" > "${config_file}.tmp"
        mv "${config_file}.tmp" "$config_file"
        fixed=1
    fi

    # 3. 删除其他不支持的字段
    local invalid_keys=(
        ".agents.defaults.model.quickModel"
        ".agents.defaults.model.tiers"
        ".agents.defaults.streaming"
        ".agents.defaults.routing"
        ".agents.defaults.api"
        ".agents.defaults.cache"
    )

    for key in "${invalid_keys[@]}"; do
        if jq -e "$key" "$config_file" > /dev/null 2>&1; then
            log "  修复: 删除 $key"
            jq "del($key)" "$config_file" > "${config_file}.tmp"
            mv "${config_file}.tmp" "$config_file"
            fixed=1
        fi
    done

    if [ $fixed -eq 1 ]; then
        log "✓ $instance_name 配置已修复"
    else
        log "✓ $instance_name 配置正常，无需修复"
    fi

    return 0
}

validate_config() {
    local config_file="$1"
    local instance_name="$2"
    local state_dir="$3"

    log "验证 $instance_name 配置..."

    if command -v openclaw &> /dev/null; then
        if OPENCLAW_STATE_DIR="$state_dir" openclaw doctor --fix > /dev/null 2>&1; then
            log "✓ $instance_name 配置验证通过"
            return 0
        else
            log "⚠️  $instance_name 配置验证失败"
            return 1
        fi
    else
        log "⚠️  openclaw命令不可用，跳过验证"
        return 0
    fi
}

restart_gateway() {
    local instance_name="$1"
    local state_dir="$2"

    log "重启 $instance_name Gateway..."

    if [ "$state_dir" = "$HOME/.openclaw" ]; then
        launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway 2>/dev/null || \
        OPENCLAW_STATE_DIR="$state_dir" openclaw gateway restart 2>/dev/null || true
    else
        launchctl kickstart -k gui/$(id -u)/ai.openclaw-vi.gateway 2>/dev/null || \
        OPENCLAW_STATE_DIR="$state_dir" openclaw gateway restart 2>/dev/null || true
    fi

    sleep 2
    log "✓ $instance_name Gateway已重启"
}

main() {
    log "=========================================="
    log "OpenClaw 配置自动修复"
    log "=========================================="

    local need_restart=0

    # 修复实例1
    if [ -f "$OPENCLAW_DIR/openclaw.json" ]; then
        if fix_config "$OPENCLAW_DIR/openclaw.json" "实例1"; then
            validate_config "$OPENCLAW_DIR/openclaw.json" "实例1" "$OPENCLAW_DIR"
            need_restart=1
        fi
    fi

    # 修复实例2(Vi)
    if [ -f "$OPENCLAW_VI_DIR/openclaw.json" ]; then
        if fix_config "$OPENCLAW_VI_DIR/openclaw.json" "实例2(Vi)"; then
            validate_config "$OPENCLAW_VI_DIR/openclaw.json" "实例2(Vi)" "$OPENCLAW_VI_DIR"
            need_restart=1
        fi
    fi

    # 重启服务
    if [ $need_restart -eq 1 ]; then
        log ""
        log "重启Gateway服务..."
        [ -f "$OPENCLAW_DIR/openclaw.json" ] && restart_gateway "实例1" "$OPENCLAW_DIR"
        [ -f "$OPENCLAW_VI_DIR/openclaw.json" ] && restart_gateway "实例2(Vi)" "$OPENCLAW_VI_DIR"
    fi

    log ""
    log "=========================================="
    log "配置修复完成！"
    log "=========================================="
}

main "$@"
