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

# 主函数
generate_image_url() {
    local size_param=$1
    local bg_color=$2
    local fg_color=$3
    
    # 1. 处理尺寸参数：将 * 替换为 x
    local size=$(echo "$size_param" | sed 's/\*/x/g')
    
    # 验证尺寸格式
    if ! echo "$size" | grep -qE '^[0-9]+x[0-9]+$'; then
        echo "错误：无效的尺寸参数 '$size_param'，请使用类似 '600*300' 或 '600x300' 的格式" >&2
        return 1
    fi
    
    # 2. 生成或验证背景色 (深色)
    if [ -z "$bg_color" ]; then
        # 循环生成直到亮度低于阈值
        local brightness=200
        while [ $brightness -gt 150 ]; do
            bg_color=$(generate_dark_color)
            brightness=$(calculate_brightness "$bg_color")
        done
    else
        # 验证提供的背景色
        if ! echo "$bg_color" | grep -qE '^[0-9a-fA-F]{6}$'; then
            echo "错误：背景色格式无效，请使用6位十六进制（如 1a2b3c）" >&2
            return 1
        fi
    fi
    
    # 3. 生成或验证字体色 (偏向白色)
    if [ -z "$fg_color" ]; then
        # 循环生成直到亮度高于阈值且与背景色有足够对比
        local bg_brightness=$(calculate_brightness "$bg_color")
        local fg_brightness=0
        local attempts=0
        while [ $((fg_brightness - bg_brightness)) -lt 100 ] && [ $attempts -lt 50 ]; do
            fg_color=$(generate_light_color)
            fg_brightness=$(calculate_brightness "$fg_color")
            attempts=$((attempts + 1))
        done
    else
        # 验证提供的字体色
        if ! echo "$fg_color" | grep -qE '^[0-9a-fA-F]{6}$'; then
            echo "错误：字体色格式无效，请使用6位十六进制（如 ffffff）" >&2
            return 1
        fi
    fi
    
    # 4. 构建并输出URL
    echo "https://dummyimage.com/${size}/${bg_color}/${fg_color}"
}

# 使用示例
main() {
    # 如果提供了命令行参数，使用第一个参数作为尺寸
    if [ $# -ge 1 ]; then
        generate_image_url "$1" "$2" "$3"
    else
        # 交互式输入
        echo "请输入图片尺寸（如 600*300 或 600x300）："
        read -r size_input
        generate_image_url "$size_input"
    fi
}

# 执行主函数
main "$@"






# 只传尺寸，背景和字体颜色自动生成
# ./generate_image.sh 600*300

# 指定尺寸和背景色，字体色自动生成
# ./generate_image.sh 800x400 1a2b3c

# 完全指定所有参数
# ./generate_image.sh 1024x768 2c3e50 ffffff
