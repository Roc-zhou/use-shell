#!/bin/bash

#================================================================
#
#   Filename:   download-github-release.sh
#   Creator:    Roc
#   CreateTime: 2025年02月13日
#
#================================================================

#================================================================
# 下载 GitHub release 的脚本
# 使用 curl 下载 GitHub release 的所有 assets
# 下载目录为项目名-版本号
# 需要提供 GitHub release 的 URL

# 使用方法：
# 1. 将脚本保存为 download-github-release.sh
# 2. 在终端中运行 chmod +x download-github-release.sh
# 3. 运行 ./download-github-release.sh <github-release-url> [output-dir]
# 4. 可选地指定输出目录，默认为项目名-版本号
# 5. 脚本会自动下载所有 assets 到指定目录
# 6. 如果没有指定输出目录，则默认为项目名-版本号
# 7. 如果没有找到任何 assets，则脚本会退出并输出错误信息
#
#================================================================

set -e


if [ $# -lt 1 ] || [ $# -gt 2 ]; then
	echo "用法: $0 <github-release-url> [output-dir]"
	exit 1
fi

RELEASE_URL="$1"

# 提取 owner, repo, tag
if [[ "$RELEASE_URL" =~ github.com/([^/]+)/([^/]+)/releases/tag/(.+)$ ]]; then
	OWNER="${BASH_REMATCH[1]}"
	REPO="${BASH_REMATCH[2]}"
	TAG="${BASH_REMATCH[3]}"
else
	echo "无效的 GitHub release 链接: $RELEASE_URL"
	exit 1
fi

# 获取 API 地址
API_URL="https://api.github.com/repos/$OWNER/$REPO/releases/tags/$TAG"

# 获取 release 信息
RELEASE_JSON=$(curl -sL "$API_URL")



# 组装目录名：项目名-版本号
DEFAULT_TITLE="${REPO}-${TAG}"

if [ -n "$2" ]; then
	OUTPUT_DIR="$2"
else
	OUTPUT_DIR="$DEFAULT_TITLE"
fi

# 创建输出目录（如果不存在）
mkdir -p "$OUTPUT_DIR"

# 检查是否有 assets
ASSET_URLS=$(echo "$RELEASE_JSON" | grep '"browser_download_url"' | cut -d '"' -f 4)

if [ -z "$ASSET_URLS" ]; then
	echo "未找到任何 assets."
	exit 1
fi

echo "发现如下 assets:"
echo "$ASSET_URLS"

# 下载所有 assets

for url in $ASSET_URLS; do
	echo "正在下载: $url"
	(cd "$OUTPUT_DIR" && curl -LO "$url")
done

echo "下载完成。"
