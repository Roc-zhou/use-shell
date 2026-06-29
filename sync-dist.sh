#!/bin/bash

# ============================================================
# 脚本功能：从功能分支（*-new-feature-master）将 dist 目录
#           同步到对应的主分支（test/release/master）
# ============================================================

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 记录当前分支（用于错误恢复）
ORIGINAL_BRANCH=""

# 打印带颜色的信息
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 错误处理函数：切回原分支并退出
cleanup_and_exit() {
    local exit_code=$1
    if [ -n "$ORIGINAL_BRANCH" ]; then
        local current_branch=$(git branch --show-current 2>/dev/null)
        if [ "$current_branch" != "$ORIGINAL_BRANCH" ]; then
            log_warn "正在切换回原分支: $ORIGINAL_BRANCH"
            git checkout "$ORIGINAL_BRANCH" 2>/dev/null || true
        fi
    fi
    # 清理临时目录
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
    exit $exit_code
}

# 捕获错误信号
trap 'cleanup_and_exit 1' INT TERM ERR

# ============================================================
# 1. 获取当前分支
# ============================================================
ORIGINAL_BRANCH=$(git branch --show-current)

if [ -z "$ORIGINAL_BRANCH" ]; then
    log_error "无法获取当前分支，请确保您在 Git 仓库中"
    exit 1
fi

log_info "当前分支: $ORIGINAL_BRANCH"

# ============================================================
# 2. 判断是否匹配功能分支（支持两种模式）
# ============================================================
TARGET_BRANCH=""
FEATURE_PATTERN=""

# 检测当前分支属于哪种模式
case "$ORIGINAL_BRANCH" in
    *-cdn-feature-opt)
        FEATURE_PATTERN="cdn-feature-opt"
        ;;
    *-new-feature-master)
        FEATURE_PATTERN="new-feature-master"
        ;;
    *)
        log_error "当前分支 '$ORIGINAL_BRANCH' 不是有效的功能分支！"
        log_error "支持的分支模式:"
        log_error "  - *-cdn-feature-opt"
        log_error "  - *-new-feature-master"
        cleanup_and_exit 1
        ;;
esac

log_info "匹配到功能分支模式: $FEATURE_PATTERN"

# 根据分支模式确定目标分支
case "$FEATURE_PATTERN" in
    cdn-feature-opt)
        case "$ORIGINAL_BRANCH" in
            main-cdn-feature-opt)
                TARGET_BRANCH="main"
                ;;
            release-cdn-feature-opt)
                TARGET_BRANCH="release"
                ;;
            test-cdn-feature-opt)
                TARGET_BRANCH="test"
                ;;
            *)
                log_error "无法识别的功能分支: $ORIGINAL_BRANCH"
                cleanup_and_exit 1
                ;;
        esac
        ;;
    new-feature-master)
        case "$ORIGINAL_BRANCH" in
            master-new-feature-master)
                TARGET_BRANCH="master"
                ;;
            release-new-feature-master)
                TARGET_BRANCH="release"
                ;;
            test-new-feature-master)
                TARGET_BRANCH="test"
                ;;
            *)
                log_error "无法识别的功能分支: $ORIGINAL_BRANCH"
                cleanup_and_exit 1
                ;;
        esac
        ;;
esac

log_info "匹配到目标分支: $TARGET_BRANCH"

# ============================================================
# 3. 检查当前分支是否干净（无未提交的更改）
# ============================================================
log_info "检查工作区是否干净..."

if ! git diff --quiet; then
    log_error "工作区有未暂存的更改，请先提交或暂存这些更改！"
    git status --short
    cleanup_and_exit 1
fi

if ! git diff --cached --quiet; then
    log_error "有已暂存但未提交的更改，请先提交！"
    git status --short
    cleanup_and_exit 1
fi

log_info "工作区干净"

# ============================================================
# 4. 检查 dist 目录是否存在
# ============================================================
DIST_DIR="./dist"

if [ ! -d "$DIST_DIR" ]; then
    log_error "当前分支根目录下不存在 dist 文件夹！"
    cleanup_and_exit 1
fi

log_info "找到 dist 目录"

# ============================================================
# 5. 复制 dist 到临时目录
# ============================================================
TEMP_DIR="/tmp/dist_backup_$$"

log_info "正在备份 dist 到临时目录: $TEMP_DIR"
cp -r "$DIST_DIR" "$TEMP_DIR"

if [ ! -d "$TEMP_DIR" ]; then
    log_error "备份 dist 失败！"
    cleanup_and_exit 1
fi

log_info "备份完成"

# ============================================================
# 6. 切换分支到目标分支
# ============================================================
log_info "正在切换到分支: $TARGET_BRANCH"
git checkout "$TARGET_BRANCH"

if [ $? -ne 0 ]; then
    log_error "切换分支失败！"
    cleanup_and_exit 1
fi

log_info "成功切换到分支: $TARGET_BRANCH"

# ============================================================
# 7. 拉取最新代码
# ============================================================
log_info "正在拉取最新代码..."
git pull

if [ $? -ne 0 ]; then
    log_error "拉取代码失败！"
    cleanup_and_exit 1
fi

log_info "拉取代码成功"

# ============================================================
# 8. 检查是否有冲突
# ============================================================
if git ls-files -u | grep -q .; then
    log_error "拉取代码后存在冲突！请手动解决冲突后重试。"
    cleanup_and_exit 1
fi

log_info "没有冲突"

# ============================================================
# 9. 删除当前分支的 dist 目录
# ============================================================
if [ -d "$DIST_DIR" ]; then
    log_info "正在删除旧的 dist 目录..."
    rm -rf "$DIST_DIR"
fi

# ============================================================
# 10. 从临时目录复制 dist 到当前分支
# ============================================================
log_info "正在从临时目录复制 dist..."
cp -r "$TEMP_DIR" "$DIST_DIR"

if [ ! -d "$DIST_DIR" ]; then
    log_error "复制 dist 失败！"
    cleanup_and_exit 1
fi

log_info "复制 dist 成功"

# ============================================================
# 11. 清理临时目录
# ============================================================
rm -rf "$TEMP_DIR"
log_info "临时目录已清理"
unset TEMP_DIR

# ============================================================
# 12. Git 提交（只提交 dist 目录）
# ============================================================
CURRENT_DATE=$(date "+%Y-%m-%d %H:%M:%S")

log_info "正在添加 dist 目录..."
git add dist/

if [ $? -ne 0 ]; then
    log_error "git add dist/ 失败！"
    cleanup_and_exit 1
fi

log_info "正在提交..."
COMMIT_MSG="update dist ${CURRENT_DATE}"
git commit -m "$COMMIT_MSG"

if [ $? -ne 0 ]; then
    log_error "git commit 失败！"
    cleanup_and_exit 1
fi

log_info "提交成功: $COMMIT_MSG"

# ============================================================
# 13. Git Push
# ============================================================
log_info "正在推送到远程仓库..."
git push

if [ $? -ne 0 ]; then
    log_error "git push 失败！"
    cleanup_and_exit 1
fi

log_info "推送成功"

# ============================================================
# 14. 切回原来的分支
# ============================================================
log_info "正在切换回原分支: $ORIGINAL_BRANCH"
git checkout "$ORIGINAL_BRANCH"

if [ $? -ne 0 ]; then
    log_error "切换回原分支失败！"
    cleanup_and_exit 1
fi

# ============================================================
# 完成！取消错误捕获，正常退出
# ============================================================
trap - INT TERM ERR

log_info "=========================================="
log_info "✅ 全部完成！"
log_info "   原分支: $ORIGINAL_BRANCH"
log_info "   目标分支: $TARGET_BRANCH"
log_info "   分支模式: $FEATURE_PATTERN"
log_info "   提交信息: $COMMIT_MSG"
log_info "=========================================="

exit 0
