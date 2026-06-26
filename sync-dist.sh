#!/bin/bash

# ============================================================
# 脚本功能：从功能分支（*-cdn-feature-opt）将 dist 目录
#           同步到对应的主分支（test/release/main）
# ============================================================

set -e # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

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

# ============================================================
# 1. 获取当前分支
# ============================================================
CURRENT_BRANCH=$(git branch --show-current)

if [ -z "$CURRENT_BRANCH" ]; then
  log_error "无法获取当前分支，请确保您在 Git 仓库中"
  exit 1
fi

log_info "当前分支: $CURRENT_BRANCH"

# ============================================================
# 2. 判断是否匹配功能分支
# ============================================================
TARGET_BRANCH=""

case "$CURRENT_BRANCH" in
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
  log_error "当前分支 '$CURRENT_BRANCH' 不是功能分支！"
  log_error "支持的分支: main-cdn-feature-opt, release-cdn-feature-opt, test-cdn-feature-opt"
  exit 1
  ;;
esac

log_info "匹配到目标分支: $TARGET_BRANCH"

# ============================================================
# 3. 检查当前分支是否干净（无未提交的更改）
# ============================================================
log_info "检查工作区是否干净..."

# 检查是否有未暂存的更改
if ! git diff --quiet; then
  log_error "工作区有未暂存的更改，请先提交或暂存这些更改！"
  git status --short
  exit 1
fi

# 检查是否有未提交的暂存
if ! git diff --cached --quiet; then
  log_error "有已暂存但未提交的更改，请先提交！"
  git status --short
  exit 1
fi

# 检查是否有未跟踪的文件（可选，如果希望严格检查可以取消注释）
if [ -n "$(git ls-files --others --exclude-standard)" ]; then
  log_error "有未跟踪的文件，请先处理！"
  git status --short
  exit 1
fi

log_info "工作区干净"

# ============================================================
# 4. 检查 dist 目录是否存在
# ============================================================
DIST_DIR="./dist"

if [ ! -d "$DIST_DIR" ]; then
  log_error "当前分支根目录下不存在 dist 文件夹！"
  exit 1
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
  exit 1
fi

log_info "备份完成"

# ============================================================
# 6. 切换分支到目标分支
# ============================================================
log_info "正在切换到分支: $TARGET_BRANCH"
git checkout "$TARGET_BRANCH"

if [ $? -ne 0 ]; then
  log_error "切换分支失败！"
  # 清理临时目录
  rm -rf "$TEMP_DIR"
  exit 1
fi

log_info "成功切换到分支: $TARGET_BRANCH"

# ============================================================
# 7. 拉取最新代码
# ============================================================
log_info "正在拉取最新代码..."
git pull

if [ $? -ne 0 ]; then
  log_error "拉取代码失败！"
  # 清理临时目录
  rm -rf "$TEMP_DIR"
  exit 1
fi

log_info "拉取代码成功"

# ============================================================
# 8. 检查是否有冲突
# ============================================================
if git ls-files -u | grep -q .; then
  log_error "拉取代码后存在冲突！请手动解决冲突后重试。"
  # 清理临时目录
  rm -rf "$TEMP_DIR"
  exit 1
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
  rm -rf "$TEMP_DIR"
  exit 1
fi

log_info "复制 dist 成功"

# ============================================================
# 11. 清理临时目录
# ============================================================
rm -rf "$TEMP_DIR"
log_info "临时目录已清理"

# ============================================================
# 12. Git 提交（只提交 dist 目录）
# ============================================================
CURRENT_DATE=$(date "+%Y-%m-%d %H:%M:%S")

log_info "正在添加 dist 目录..."
git add dist/

if [ $? -ne 0 ]; then
  log_error "git add dist/ 失败！"
  exit 1
fi

log_info "正在提交..."
COMMIT_MSG="update dist ${CURRENT_DATE}"
git commit -m "$COMMIT_MSG"

if [ $? -ne 0 ]; then
  log_error "git commit 失败！"
  exit 1
fi

log_info "提交成功: $COMMIT_MSG"

# ============================================================
# 13. Git Push
# ============================================================
log_info "正在推送到远程仓库..."
git push

if [ $? -ne 0 ]; then
  log_error "git push 失败！"
  exit 1
fi

log_info "推送成功"

# ============================================================
# 14. 切回原来的分支
# ============================================================
log_info "正在切换回原分支: $CURRENT_BRANCH"
git checkout "$CURRENT_BRANCH"

if [ $? -ne 0 ]; then
  log_error "切换回原分支失败！"
  exit 1
fi

# ============================================================
# 完成！
# ============================================================
log_info "=========================================="
log_info "✅ 全部完成！"
log_info "   原分支: $CURRENT_BRANCH"
log_info "   目标分支: $TARGET_BRANCH"
log_info "   提交信息: $COMMIT_MSG"
log_info "=========================================="

exit 0
