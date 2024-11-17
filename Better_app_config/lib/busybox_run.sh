#!/bin/sh

export ASH_STANDALONE=1

# 准备 busybox 环境
alias busybox="sh"
# 检查是否可以切换命名空间
if command -v nsenter >/dev/null 2>&1; then
  workerPath="/data/adb"
  # 设置busybox
  set_busybox() {
    # 检查文件是否存在
    if [ -f $busyboxPath ]; then
      CommandPrefix="$busyboxPath nsenter -m/proc/1/ns/mnt sh -c"
      # 检查是否可以调用
      if [ "$($CommandPrefix "echo 1")" = "1" ]; then
        alias busybox="$CommandPrefix"
      fi
    fi
  }
  # 检查是否有 kernelsu 释放的busybox
  rootType="ksu"
  busyboxPath="$workerPath/$rootType/bin/busybox"
  set_busybox
  # 检查是否有 apatch 释放的busybox
  rootType="ap"
  busyboxPath="$workerPath/$rootType/bin/busybox"
  set_busybox
  # 检查是否有 magisk 释放的busybox
  rootType="magisk"
  busyboxPath="$workerPath/$rootType/busybox"
  set_busybox
fi

# 接受传入的命令并执行
busybox "$1"