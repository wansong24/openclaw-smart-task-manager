#!/bin/bash
# OpenClaw Smart Task Manager - One-Click Installer
# 一键安装脚本
#
# 使用方法：
# curl -fsSL https://raw.githubusercontent.com/wansong24/openclaw-smart-task-manager/main/install.sh | bash
# 或者：
# wget -qO- https://raw.githubusercontent.com/wansong24/openclaw-smart-task-manager/main/install.sh | bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示欢迎信息
show_welcome() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     OpenClaw Smart Task Manager - 一键安装                   ║
║                                                              ║
║     智能任务管理系统，解决大任务超时问题                      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

EOF
}

# 检测OpenClaw安装
detect_openclaw() {
    log_info "检测OpenClaw安装..."

    OPENCLAW_INSTANCES=()

    # 检测主实例
    if [ -d "$HOME/.openclaw" ] && [ -f "$HOME/.openclaw/openclaw.json" ]; then
        OPENCLAW_INSTANCES+=("$HOME/.openclaw")
        log_success "发现OpenClaw实例: ~/.openclaw"
    fi

    # 检测Vi实例
    if [ -d "$HOME/.openclaw-vi" ] && [ -f "$HOME/.openclaw-vi/openclaw.json" ]; then
        OPENCLAW_INSTANCES+=("$HOME/.openclaw-vi")
        log_success "发现OpenClaw实例: ~/.openclaw-vi"
    fi

    # 检测其他可能的实例
    for dir in "$HOME"/.openclaw-*; do
        if [ -d "$dir" ] && [ -f "$dir/openclaw.json" ]; then
            if [[ "$dir" != "$HOME/.openclaw-vi" ]]; then
                OPENCLAW_INSTANCES+=("$dir")
                log_success "发现OpenClaw实例: $dir"
            fi
        fi
    done

    if [ ${#OPENCLAW_INSTANCES[@]} -eq 0 ]; then
        log_error "未找到OpenClaw安装！"
        log_info "请先安装OpenClaw: npm install -g openclaw@latest"
        exit 1
    fi

    log_success "共发现 ${#OPENCLAW_INSTANCES[@]} 个OpenClaw实例"
}

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."

    # 检查jq
    if ! command -v jq &> /dev/null; then
        log_warning "未安装jq，正在安装..."
        if command -v brew &> /dev/null; then
            brew install jq
        elif command -v apt-get &> /dev/null; then
            sudo apt-get install -y jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
        else
            log_error "无法自动安装jq，请手动安装"
            exit 1
        fi
    fi
    log_success "依赖检查完成"
}

# 下载文件
download_files() {
    local instance_dir="$1"
    local scripts_dir="$instance_dir/scripts"
    local workspace_dir="$instance_dir/workspace"

    log_info "下载文件到 $instance_dir..."

    # 创建目录
    mkdir -p "$scripts_dir"
    mkdir -p "$workspace_dir"

    # GitHub raw URL
    local base_url="https://raw.githubusercontent.com/wansong24/openclaw-smart-task-manager/main"

    # 下载脚本
    curl -fsSL "$base_url/smart-task-manager.sh" -o "$scripts_dir/smart-task-manager.sh"
    curl -fsSL "$base_url/check-status.sh" -o "$scripts_dir/check-status.sh"
    curl -fsSL "$base_url/smart-task.skill.json" -o "$scripts_dir/smart-task.skill.json"

    # 下载文档
    curl -fsSL "$base_url/TASK_BREAKDOWN.md" -o "$workspace_dir/TASK_BREAKDOWN.md"
    curl -fsSL "$base_url/DOCUMENTATION.md" -o "$scripts_dir/SMART_TASK_README.md"

    # 添加执行权限
    chmod +x "$scripts_dir/smart-task-manager.sh"
    chmod +x "$scripts_dir/check-status.sh"

    log_success "文件下载完成"
}

# 优化配置
optimize_config() {
    local instance_dir="$1"
    local scripts_dir="$instance_dir/scripts"

    log_info "优化配置 $instance_dir..."

    # 运行优化脚本
    OPENCLAW_STATE_DIR="$instance_dir" bash "$scripts_dir/smart-task-manager.sh"

    log_success "配置优化完成"
}

# 重启Gateway
restart_gateway() {
    log_info "重启OpenClaw Gateway服务..."

    # 检测操作系统
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        log_info "检测到macOS系统"

        # 查找所有openclaw gateway服务
        local services=$(launchctl list | grep openclaw.gateway | awk '{print $3}')

        if [ -n "$services" ]; then
            for service in $services; do
                log_info "重启服务: $service"
                launchctl bootout "gui/$(id -u)/$service" 2>/dev/null || true
                sleep 1

                # 查找对应的plist文件
                local plist="$HOME/Library/LaunchAgents/$service.plist"
                if [ -f "$plist" ]; then
                    launchctl bootstrap "gui/$(id -u)" "$plist"
                fi
            done

            sleep 3
            log_success "Gateway服务已重启"
        else
            log_warning "未找到运行中的Gateway服务"
        fi
    else
        # Linux
        log_info "检测到Linux系统"
        log_warning "请手动重启OpenClaw Gateway服务"
    fi
}

# 验证安装
verify_installation() {
    log_info "验证安装..."

    local all_success=true

    for instance_dir in "${OPENCLAW_INSTANCES[@]}"; do
        log_info "验证 $instance_dir..."

        # 检查文件
        local files=(
            "$instance_dir/scripts/smart-task-manager.sh"
            "$instance_dir/scripts/check-status.sh"
            "$instance_dir/scripts/smart-task.skill.json"
            "$instance_dir/workspace/TASK_BREAKDOWN.md"
        )

        for file in "${files[@]}"; do
            if [ ! -f "$file" ]; then
                log_error "文件缺失: $file"
                all_success=false
            fi
        done

        # 检查配置
        if command -v jq &> /dev/null; then
            local timeout=$(jq -r '.agents.defaults.timeoutSeconds // empty' "$instance_dir/openclaw.json" 2>/dev/null)
            if [ "$timeout" = "1800" ]; then
                log_success "配置验证通过: $instance_dir"
            else
                log_warning "配置可能未完全优化: $instance_dir"
            fi
        fi
    done

    if [ "$all_success" = true ]; then
        log_success "安装验证通过！"
        return 0
    else
        log_error "安装验证失败"
        return 1
    fi
}

# 显示完成信息
show_completion() {
    cat << 'EOF'

╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     ✅ 安装完成！                                             ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

📋 已安装的实例：
EOF

    for instance_dir in "${OPENCLAW_INSTANCES[@]}"; do
        echo "   ✓ $instance_dir"
    done

    cat << 'EOF'

🎯 快速开始：

1. 检查系统状态：
   ~/.openclaw/scripts/check-status.sh

2. 查看使用指南：
   cat ~/.openclaw/scripts/SMART_TASK_README.md

3. 在OpenClaw聊天中测试：
   直接给AI一个大任务，它会自动分解和管理！

📚 更多信息：
   GitHub: https://github.com/wansong24/openclaw-smart-task-manager

💡 提示：
   - AI会自动处理大任务，无需手动干预
   - 系统已配置30分钟超时和自动故障转移
   - 所有操作都有日志记录

EOF
}

# 主函数
main() {
    show_welcome

    # 检测OpenClaw
    detect_openclaw

    # 检查依赖
    check_dependencies

    # 为每个实例安装
    for instance_dir in "${OPENCLAW_INSTANCES[@]}"; do
        echo ""
        log_info "=========================================="
        log_info "处理实例: $instance_dir"
        log_info "=========================================="

        # 下载文件
        download_files "$instance_dir"

        # 优化配置
        optimize_config "$instance_dir"
    done

    # 重启Gateway
    echo ""
    restart_gateway

    # 验证安装
    echo ""
    verify_installation

    # 显示完成信息
    show_completion
}

# 运行主函数
main "$@"
