#!/bin/bash

# 生成随机深色背景（十六进制）
generate_dark_color() {
    # 生成0-100之间的RGB值，转换为十六进制
    r=$(printf "%02x" $((RANDOM % 101)))
    g=$(printf "%02x" $((RANDOM % 101)))
    b=$(printf "%02x" $((RANDOM % 101)))
    echo "${r}${g}${b}"
}

# 生成随机浅色字体（偏向白色）
generate_light_color() {
    # 生成200-255之间的RGB值，转换为十六进制
    r=$(printf "%02x" $((RANDOM % 56 + 200)))
    g=$(printf "%02x" $((RANDOM % 56 + 200)))
    b=$(printf "%02x" $((RANDOM % 56 + 200)))
    echo "${r}${g}${b}"
}

# 计算颜色亮度（简单的亮度公式）
calculate_brightness() {
    local hex=$1
    # 提取RGB值
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    # 使用标准亮度公式
    echo $(( (r * 299 + g * 587 + b * 114) / 1000 ))
}

# 复制到剪贴板（支持多种系统）
copy_to_clipboard() {
    local text="$1"
    
    # 检测操作系统并选择对应的复制命令
    if command -v pbcopy &> /dev/null; then
        # macOS
        echo -n "$text" | pbcopy
        echo "✅ 已复制到剪贴板 (macOS)"
    elif command -v xclip &> /dev/null; then
        # Linux (X11) - 需要安装 xclip
        echo -n "$text" | xclip -selection clipboard
        echo "✅ 已复制到剪贴板 (xclip)"
    elif command -v xsel &> /dev/null; then
        # Linux (X11) - 需要安装 xsel
        echo -n "$text" | xsel --clipboard --input
        echo "✅ 已复制到剪贴板 (xsel)"
    elif command -v clip.exe &> /dev/null; then
        # Windows (WSL 或 Git Bash)
        echo -n "$text" | clip.exe
        echo "✅ 已复制到剪贴板 (Windows)"
    elif command -v termux-clipboard-set &> /dev/null; then
        # Android Termux
        echo -n "$text" | termux-clipboard-set
        echo "✅ 已复制到剪贴板 (Termux)"
    else
        echo "⚠️  未找到剪贴板工具，请手动复制以下内容："
        return 1
    fi
    return 0
}

# 主函数
generate_image_url() {
    local size_param=$1
    local bg_color=$2
    local fg_color=$3
    local auto_copy=${4:-true}  # 默认自动复制
    
    # 1. 处理尺寸参数：将 * 替换为 x
    local size=$(echo "$size_param" | sed 's/\*/x/g')
    
    # 验证尺寸格式
    if ! echo "$size" | grep -qE '^[0-9]+x[0-9]+$'; then
        echo "❌ 错误：无效的尺寸参数 '$size_param'，请使用类似 '600*300' 或 '600x300' 的格式" >&2
        return 1
    fi
    
    # 2. 生成或验证背景色 (深色)
    if [ -z "$bg_color" ]; then
        # 循环生成直到亮度低于阈值
        local brightness=200
        local attempts=0
        while [ $brightness -gt 150 ] && [ $attempts -lt 100 ]; do
            bg_color=$(generate_dark_color)
            brightness=$(calculate_brightness "$bg_color")
            attempts=$((attempts + 1))
        done
        if [ $attempts -ge 100 ]; then
            bg_color="1a2b3c"  # 保底颜色
        fi
    else
        # 验证提供的背景色
        if ! echo "$bg_color" | grep -qE '^[0-9a-fA-F]{6}$'; then
            echo "❌ 错误：背景色格式无效，请使用6位十六进制（如 1a2b3c）" >&2
            return 1
        fi
    fi
    
    # 3. 生成或验证字体色 (偏向白色)
    if [ -z "$fg_color" ]; then
        # 循环生成直到亮度高于阈值且与背景色有足够对比
        local bg_brightness=$(calculate_brightness "$bg_color")
        local fg_brightness=0
        local attempts=0
        while [ $((fg_brightness - bg_brightness)) -lt 80 ] && [ $attempts -lt 100 ]; do
            fg_color=$(generate_light_color)
            fg_brightness=$(calculate_brightness "$fg_color")
            attempts=$((attempts + 1))
        done
        if [ $attempts -ge 100 ]; then
            fg_color="ffffff"  # 保底白色
        fi
    else
        # 验证提供的字体色
        if ! echo "$fg_color" | grep -qE '^[0-9a-fA-F]{6}$'; then
            echo "❌ 错误：字体色格式无效，请使用6位十六进制（如 ffffff）" >&2
            return 1
        fi
    fi
    
    # 4. 构建URL
    local url="https://dummyimage.com/${size}/${bg_color}/${fg_color}"
    
    # 5. 输出结果
    echo ""
    echo "📸 生成的图片URL："
    echo "$url"
    echo ""
    
    # 6. 复制到剪贴板
    if [ "$auto_copy" = true ]; then
        if copy_to_clipboard "$url"; then
            echo ""
            echo "💡 可以直接粘贴使用 (Ctrl+V / Cmd+V)"
        fi
    else
        echo "💡 如需复制，请手动选中上面的URL复制"
    fi
    
    echo ""
    return 0
}

# 显示帮助信息
show_help() {
    cat << EOF
使用方法：
  $(basename "$0") [尺寸] [背景色] [字体色] [选项]

参数说明：
  尺寸      : 必需，格式如 600*300 或 600x300
  背景色    : 可选，6位十六进制颜色码（如 1a2b3c）
  字体色    : 可选，6位十六进制颜色码（如 ffffff）
  选项      : 可选，--no-copy 表示不自动复制到剪贴板

示例：
  $(basename "$0") 600*300
  $(basename "$0") 800x400 2c3e50
  $(basename "$0") 1024x768 1a2b3c ffffff
  $(basename "$0") 600*300 --no-copy

交互式运行（不传参数）：
  $(basename "$0")

EOF
}

# 解析命令行参数
main() {
    local size=""
    local bg=""
    local fg=""
    local no_copy=false
    local args=()
    
    # 解析参数
    for arg in "$@"; do
        case $arg in
            --no-copy)
                no_copy=true
                ;;
            --help|-h)
                show_help
                return 0
                ;;
            *)
                args+=("$arg")
                ;;
        esac
    done
    
    # 根据参数数量决定行为
    case ${#args[@]} in
        0)
            # 交互式输入
            echo "📷 生成 DummyImage URL"
            echo "========================"
            echo "请输入图片尺寸（如 600*300 或 600x300）："
            read -r size_input
            
            if [ -z "$size_input" ]; then
                echo "❌ 尺寸不能为空"
                return 1
            fi
            
            generate_image_url "$size_input" "" "" "$no_copy"
            ;;
        1)
            # 只有尺寸
            generate_image_url "${args[0]}" "" "" "$no_copy"
            ;;
        2)
            # 尺寸 + 背景色
            generate_image_url "${args[0]}" "${args[1]}" "" "$no_copy"
            ;;
        3)
            # 尺寸 + 背景色 + 字体色
            generate_image_url "${args[0]}" "${args[1]}" "${args[2]}" "$no_copy"
            ;;
        *)
            echo "❌ 参数过多，请查看帮助：$(basename "$0") --help"
            return 1
            ;;
    esac
}

# 执行主函数
main "$@"





# 只传尺寸，背景和字体颜色自动生成
# ./generate_image.sh 600*300

# 指定尺寸和背景色，字体色自动生成
# ./generate_image.sh 800x400 1a2b3c

# 完全指定所有参数
# ./generate_image.sh 1024x768 2c3e50 ffffff
