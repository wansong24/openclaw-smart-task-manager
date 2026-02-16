#!/bin/bash
# OpenClaw 配置验证测试脚本
# 确保配置文件不包含不支持的字段

set -e

OPENCLAW_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
OPENCLAW_VI_DIR="$HOME/.openclaw-vi"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

test_config() {
    local config_file="$1"
    local instance_name="$2"
    local errors=0

    log "测试 $instance_name 配置..."

    if [ ! -f "$config_file" ]; then
        log "❌ 配置文件不存在: $config_file"
        return 1
    fi

    # 检查不支持的字段
    local invalid_fields=(
        ".agents.defaults.contextPruning.enabled"
        ".agents.defaults.model.quickModel"
        ".agents.defaults.model.tiers"
        ".agents.defaults.streaming"
        ".agents.defaults.routing"
        ".agents.defaults.api"
        ".agents.defaults.cache"
    )

    for field in "${invalid_fields[@]}"; do
        if jq -e "$field" "$config_file" > /dev/null 2>&1; then
            log "❌ 发现不支持的字段: $field"
            errors=$((errors + 1))
        fi
    done

    # 检查必需的字段
    local required_fields=(
        ".agents.defaults.timeoutSeconds"
        ".agents.defaults.compaction.mode"
        ".agents.defaults.contextPruning.mode"
    )

    for field in "${required_fields[@]}"; do
        if ! jq -e "$field" "$config_file" > /dev/null 2>&1; then
            log "⚠️  缺少推荐字段: $field"
        fi
    done

    # 验证 contextPruning 配置
    local pruning_type=$(jq -r '.agents.defaults.contextPruning | type' "$config_file" 2>/dev/null)
    if [ "$pruning_type" = "object" ]; then
        local has_enabled=$(jq -e '.agents.defaults.contextPruning.enabled' "$config_file" > /dev/null 2>&1 && echo "yes" || echo "no")
        if [ "$has_enabled" = "yes" ]; then
            log "❌ contextPruning 包含不支持的 enabled 字段"
            errors=$((errors + 1))
        else
            log "✓ contextPruning 配置正确"
        fi
    fi

    if [ $errors -eq 0 ]; then
        log "✅ $instance_name 配置测试通过"
        return 0
    else
        log "❌ $instance_name 配置测试失败，发现 $errors 个错误"
        return 1
    fi
}

validate_with_openclaw() {
    local state_dir="$1"
    local instance_name="$2"

    log "使用 openclaw doctor 验证 $instance_name..."

    if OPENCLAW_STATE_DIR="$state_dir" openclaw doctor 2>&1 | grep -q "Config invalid"; then
        log "❌ $instance_name OpenClaw 配置验证失败"
        return 1
    else
        log "✅ $instance_name OpenClaw 配置验证通过"
        return 0
    fi
}

main() {
    log "=========================================="
    log "OpenClaw 配置验证测试"
    log "=========================================="

    local all_passed=true

    # 测试实例1
    if [ -f "$OPENCLAW_DIR/openclaw.json" ]; then
        if ! test_config "$OPENCLAW_DIR/openclaw.json" "实例1"; then
            all_passed=false
        fi
        if ! validate_with_openclaw "$OPENCLAW_DIR" "实例1"; then
            all_passed=false
        fi
    fi

    # 测试实例2
    if [ -f "$OPENCLAW_VI_DIR/openclaw.json" ]; then
        if ! test_config "$OPENCLAW_VI_DIR/openclaw.json" "实例2(Vi)"; then
            all_passed=false
        fi
        if ! validate_with_openclaw "$OPENCLAW_VI_DIR" "实例2(Vi)"; then
            all_passed=false
        fi
    fi

    log "=========================================="
    if [ "$all_passed" = true ]; then
        log "✅ 所有测试通过！配置正确无误。"
        log "=========================================="
        exit 0
    else
        log "❌ 测试失败！请运行修复脚本："
        log "   ~/.openclaw/scripts/fix-config.sh"
        log "=========================================="
        exit 1
    fi
}

main "$@"
