#!/bin/bash

# ============================================================
# Git 分支部署脚本
# 用法: ./deploy.sh <目标分支>
# 示例: ./deploy.sh bbb
# ============================================================

set -e  # 遇到错误立即退出

# ---------- 颜色 ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ---------- 参数检查 ----------
if [ $# -ne 1 ]; then
    echo -e "${RED}❌ 错误: 请指定目标分支${NC}"
    echo "用法: $0 <目标分支>"
    echo "示例: $0 bbb"
    exit 1
fi

TARGET_BRANCH="$1"
TEMP_DIR="/tmp/deploy_dist_$$"  # $$ 是当前 shell PID，避免冲突

# ---------- 1. 记录当前分支 ----------
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
if [ -z "$CURRENT_BRANCH" ]; then
    echo -e "${RED}❌ 错误: 不在 Git 仓库中${NC}"
    exit 1
fi

echo -e "${BLUE}🚀 开始部署: ${CURRENT_BRANCH} → ${TARGET_BRANCH}${NC}"

# ---------- 2. 检查工作区是否干净 ----------
if ! git diff --quiet && ! git diff --cached --quiet; then
    echo -e "${RED}❌ 错误: 工作区有未提交的变更，请先提交或暂存${NC}"
    exit 1
fi

# ---------- 3. 检查 dist 是否存在 ----------
if [ ! -d "dist" ]; then
    echo -e "${RED}❌ 错误: dist 目录不存在${NC}"
    exit 1
fi

# ---------- 4. 备份 dist 到临时目录 ----------
echo -e "${BLUE}📦 备份 dist 到临时目录...${NC}"
rm -rf "$TEMP_DIR"
cp -r dist "$TEMP_DIR"

# ---------- 5. 切换目标分支 ----------
echo -e "${BLUE}🔀 切换到分支: ${TARGET_BRANCH}...${NC}"

# 检查目标分支是否存在
if git show-ref --verify --quiet refs/heads/"$TARGET_BRANCH"; then
    git checkout "$TARGET_BRANCH"
else
    echo -e "${RED}❌ 错误: 分支 ${TARGET_BRANCH} 不存在${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# ---------- 6. 拉取最新代码 ----------
echo -e "${BLUE}⬇️  拉取最新代码...${NC}"
git pull --ff-only || {
    echo -e "${RED}❌ git pull 失败${NC}"
    git checkout "$CURRENT_BRANCH"
    rm -rf "$TEMP_DIR"
    exit 1
}

# ---------- 7. 删除旧 dist ----------
echo -e "${BLUE}🗑️  删除旧 dist...${NC}"
rm -rf dist

# ---------- 8. 复制新 dist ----------
echo -e "${BLUE}📁 复制文件到 dist...${NC}"
cp -r "$TEMP_DIR" dist

# ---------- 9. 提交变更 ----------
echo -e "${BLUE}📝 提交变更...${NC}"
git add dist
git commit -m "Deploy: $(date '+%Y-%m-%d %H:%M:%S')"

# ---------- 10. 推送到远程 ----------
echo -e "${BLUE}⬆️  推送到远程...${NC}"
git push origin "$TARGET_BRANCH"

# ---------- 11. 清理临时目录 ----------
echo -e "${BLUE}🧹 清理临时文件...${NC}"
rm -rf "$TEMP_DIR"

# ---------- 12. 切回原分支 ----------
echo -e "${BLUE}🔙 切回分支: ${CURRENT_BRANCH}...${NC}"
git checkout "$CURRENT_BRANCH"

# ---------- 完成 ----------
echo -e "${GREEN}✅ 部署完成！${NC}"
