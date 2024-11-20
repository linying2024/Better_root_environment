#!/bin/sh

# 赋值相关二进制路径到PATH供文件调用
export PATH=/data/adb/ksu/bin/:/data/adb/ap/bin/:/data/adb/magisk/:$PATH

# 启用magisk busybox的独立模式
export ASH_STANDALONE=1

# 检查busybox是否可以调用
if command -v busybox >/dev/null 2>&1; then
  # 检查是否可以切换命名空间
  if command -v nsenter >/dev/null 2>&1; then
    # 使用nsenter切换到root命名空间执行busybox
    alias busybox="busybox nsenter -m/proc/1/ns/mnt sh -c"
  fi
else
  # 如果没有busybox，回退到sh
  alias busybox="sh"
fi

# 接受传入的命令并执行
busybox "$1"