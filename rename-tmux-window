#!/bin/bash

# 检查是否提供了参数
if [ -z "$1" ]; then
  echo "❌ 请提供参数"
  echo "用法: $0 <参数>"
  echo "示例: $0 后台系统"
  exit 1
fi

# 获取当前文件夹名称
CURRENT_DIR=$(basename "$PWD")

# 构建新窗口名称
NEW_NAME="${CURRENT_DIR}【$1】"

# 重命名当前 tmux 窗口
tmux rename-window "$NEW_NAME"

# 输出提示
echo "✅ 窗口已重命名为: $NEW_NAME"
