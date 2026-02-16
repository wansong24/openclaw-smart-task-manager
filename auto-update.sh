#!/bin/bash
# Auto-update script for OpenClaw Smart Task Manager
# 自动更新脚本

set -e

REPO_DIR="$HOME/openclaw-smart-task-manager"
LOG_FILE="$REPO_DIR/update.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

cd "$REPO_DIR"

log "=========================================="
log "开始更新 OpenClaw Smart Task Manager"
log "=========================================="

# 检查是否有未提交的更改
if [[ -n $(git status -s) ]]; then
    log "发现本地更改，准备提交..."

    # 显示更改
    git status -s

    # 添加所有更改
    git add .

    # 生成提交信息
    COMMIT_MSG="Auto-update: $(date '+%Y-%m-%d %H:%M:%S')

Changes:
$(git status -s | head -10)
"

    # 提交
    git commit -m "$COMMIT_MSG"
    log "✓ 本地更改已提交"
else
    log "没有本地更改"
fi

# 拉取远程更新
log "拉取远程更新..."
git pull origin main --rebase || {
    log "⚠️  拉取失败，可能有冲突"
    exit 1
}

# 推送到GitHub
log "推送到GitHub..."
git push origin main || {
    log "⚠️  推送失败"
    exit 1
}

log "✓ 更新完成！"
log "仓库地址: https://github.com/wansong24/openclaw-smart-task-manager"
log "=========================================="
