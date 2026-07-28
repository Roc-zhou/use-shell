#!/bin/bash

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项] <窗口编号>"
    echo "      $0 <源窗口编号> <目标窗口编号>"
    echo ""
    echo "功能：交换 tmux 窗口位置"
    echo ""
    echo "选项："
    echo "  <源> <目标>       交换两个指定窗口的位置"
    echo "  -t <窗口编号>     将指定窗口与下一个窗口交换（与 +1 交换）"
    echo "  -d <窗口编号>     将指定窗口与上一个窗口交换（与 -1 交换）"
    echo "  -h, --help        显示此帮助信息"
    echo ""
    echo "示例："
    echo "  $0 15 3           # 交换窗口 15 和窗口 3 的位置"
    echo "  $0 -t 15          # 将窗口 15 与窗口 16 交换位置"
    echo "  $0 -d 15          # 将窗口 15 与窗口 14 交换位置"
    echo "  $0 3 1            # 交换窗口 3 和窗口 1 的位置"
    echo ""
    echo "注意："
    echo "  - 窗口编号从 1 开始（如果设置了 base-index 1）"
    echo "  - 交换后两个窗口的编号会互换"
    echo "  - 使用 -t 时目标窗口必须存在（窗口编号 +1）"
    echo "  - 使用 -d 时目标窗口必须存在（窗口编号 -1）"
}

# 检查是否请求帮助
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# 获取当前会话名称
SESSION_NAME=$(tmux display-message -p '#S')

# 检查窗口是否存在的函数
check_window_exists() {
    local win_num="$1"
    if ! tmux list-windows -t "$SESSION_NAME" -F "#I" | grep -q "^$win_num$"; then
        echo "❌ 错误：窗口 $win_num 不存在"
        echo "当前窗口列表："
        tmux list-windows -t "$SESSION_NAME" -F "窗口 #I: #W"
        return 1
    fi
    return 0
}

# 获取窗口名称的函数
get_window_name() {
    local win_num="$1"
    tmux display-message -t "$SESSION_NAME:$win_num" -p '#W' 2>/dev/null
}

# 显示窗口列表的函数
show_window_list() {
    echo "📋 当前窗口列表："
    tmux list-windows -t "$SESSION_NAME" -F "窗口 #I: #W"
}

# 执行交换操作的函数
do_swap() {
    local src="$1"
    local tgt="$2"
    
    # 检查源窗口是否存在
    if ! check_window_exists "$src"; then
        return 1
    fi
    
    # 检查目标窗口是否存在
    if ! check_window_exists "$tgt"; then
        return 1
    fi
    
    # 获取窗口名称
    local src_name=$(get_window_name "$src")
    local tgt_name=$(get_window_name "$tgt")
    
    # 如果源和目标相同，提示并退出
    if [ "$src" -eq "$tgt" ]; then
        echo "⚠️  源窗口和目标窗口相同，无需交换"
        return 0
    fi
    
    echo "🔄 正在交换窗口 \"$src_name\" (#$src) 和 \"$tgt_name\" (#$tgt) ..."
    
    # 执行窗口交换
    tmux swap-window -s "$src" -t "$tgt"
    
    # 检查是否成功
    if [ $? -eq 0 ]; then
        echo "✅ 窗口交换成功！"
        echo ""
        show_window_list
        return 0
    else
        echo "❌ 窗口交换失败"
        return 1
    fi
}

# 主逻辑
case "$1" in
    -t)
        # 处理 -t 选项：与下一个窗口交换
        if [ $# -ne 2 ]; then
            echo "❌ 错误：-t 选项需要一个参数"
            echo ""
            show_help
            exit 1
        fi
        
        WINDOW_NUM="$2"
        
        # 验证参数是否为数字
        if ! [[ "$WINDOW_NUM" =~ ^[0-9]+$ ]]; then
            echo "❌ 错误：窗口编号必须是数字"
            exit 1
        fi
        
        # 计算目标窗口编号（+1）
        TARGET_NUM=$((WINDOW_NUM + 1))
        
        # 执行交换
        do_swap "$WINDOW_NUM" "$TARGET_NUM"
        ;;
    
    -d)
        # 处理 -d 选项：与上一个窗口交换
        if [ $# -ne 2 ]; then
            echo "❌ 错误：-d 选项需要一个参数"
            echo ""
            show_help
            exit 1
        fi
        
        WINDOW_NUM="$2"
        
        # 验证参数是否为数字
        if ! [[ "$WINDOW_NUM" =~ ^[0-9]+$ ]]; then
            echo "❌ 错误：窗口编号必须是数字"
            exit 1
        fi
        
        # 计算目标窗口编号（-1）
        TARGET_NUM=$((WINDOW_NUM - 1))
        
        # 执行交换
        do_swap "$WINDOW_NUM" "$TARGET_NUM"
        ;;
    
    *)
        # 处理两个参数的普通模式：交换两个窗口
        if [ $# -ne 2 ]; then
            echo "❌ 错误：需要提供源窗口编号和目标窗口编号两个参数"
            echo ""
            show_help
            exit 1
        fi
        
        SOURCE_WINDOW="$1"
        TARGET_WINDOW="$2"
        
        # 验证参数是否为数字
        if ! [[ "$SOURCE_WINDOW" =~ ^[0-9]+$ ]]; then
            echo "❌ 错误：源窗口编号必须是数字"
            exit 1
        fi
        
        if ! [[ "$TARGET_WINDOW" =~ ^[0-9]+$ ]]; then
            echo "❌ 错误：目标窗口编号必须是数字"
            exit 1
        fi
        
        # 执行交换
        do_swap "$SOURCE_WINDOW" "$TARGET_WINDOW"
        ;;
esac
