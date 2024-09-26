#!/bin/sh

# 设置终端中文支持
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

# 设置脚本文件夹
moddir="${0%/*}"

# 初始化变量
# 设置已过滤文件的输出位置
target_file_path="$moddir/../tmp/target.txt"

CONFIG_DIR=/data/adb/tricky_store
# 保证文件夹存在
mkdir -p "$CONFIG_DIR"
# 备份并复制配置文件
cp -af "$CONFIG_DIR/target.txt" "$CONFIG_DIR/target.txt.bak"
cp -af "$target_file_path" "$CONFIG_DIR/target.txt"
echo "配置文件已经尝试复制到模块配置文件目录"