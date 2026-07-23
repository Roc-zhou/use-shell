#!/bin/bash

# 显示帮助信息
show_help() {
    echo "用法: $0 <源窗口编号> <目标位置>"
    echo ""
    echo "功能：将 tmux 窗口从源位置移动到目标位置"
    echo ""
    echo "示例："
    echo "  $0 15 3      # 将窗口 15 移动到位置 3"
    echo "  $0 3 1       # 将窗口 3 移动到位置 1"
    echo "  $0 -h        # 显示此帮助信息"
    echo ""
    echo "注意："
    echo "  - 窗口编号从 1 开始（如果设置了 base-index 1）"
    echo "  - 移动后其他窗口的编号会自动重新排列"
}

# 检查是否请求帮助
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# 检查参数数量
if [ $# -ne 2 ]; then
    echo "❌ 错误：需要提供源窗口编号和目标位置两个参数"
    echo ""
    show_help
    exit 1
fi

# 获取参数
SOURCE_WINDOW="$1"
TARGET_POSITION="$2"

# 验证参数是否为数字
if ! [[ "$SOURCE_WINDOW" =~ ^[0-9]+$ ]]; then
    echo "❌ 错误：源窗口编号必须是数字"
    exit 1
fi

if ! [[ "$TARGET_POSITION" =~ ^[0-9]+$ ]]; then
    echo "❌ 错误：目标位置必须是数字"
    exit 1
fi

# 获取当前会话名称
SESSION_NAME=$(tmux display-message -p '#S')

# 检查源窗口是否存在
if ! tmux list-windows -t "$SESSION_NAME" -F "#I" | grep -q "^$SOURCE_WINDOW$"; then
    echo "❌ 错误：窗口 $SOURCE_WINDOW 不存在"
    echo "当前窗口列表："
    tmux list-windows -t "$SESSION_NAME" -F "窗口 #I: #W"
    exit 1
fi

# 获取源窗口名称（用于显示）
WINDOW_NAME=$(tmux display-message -t "$SESSION_NAME:$SOURCE_WINDOW" -p '#W')

# 执行窗口移动
echo "📦 正在将窗口 \"$WINDOW_NAME\" (#$SOURCE_WINDOW) 移动到位置 #$TARGET_POSITION ..."

# 使用 move-window 命令移动窗口
tmux move-window -t "$SESSION_NAME:$TARGET_POSITION"

# 检查是否成功
if [ $? -eq 0 ]; then
    echo "✅ 窗口已成功移动！"
    echo ""
    echo "📋 当前窗口列表："
    tmux list-windows -t "$SESSION_NAME" -F "窗口 #I: #W"
else
    echo "❌ 窗口移动失败"
    exit 1
fi
