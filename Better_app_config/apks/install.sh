#!/bin/sh

MODDIR="${0%/*}"
TMP="data/local/tmp"
# 检查当前脚本是否在/$TMP目录下执行
if [[ "$MODDIR" != /*$TMP* ]]; then
  # 将当前脚本所在的整个文件夹复制到/$TMP
  cp -arf "$MODDIR" "/$TMP"
  # 切换到/$TMP目录
  cd /$TMP/$(basename "$MODDIR")
  # 重新执行脚本
  exec /bin/sh /$TMP/$(basename "$MODDIR")/$(basename "$0")
fi

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

# 历遍当前文件夹里面的apk
for file in "$MODDIR"/*.apk; do  
  echo "安装apk文件 $file"
  log="$(busybox "pm install -r -t -d -g $file")"
  echo "$log"
  if [[ ! "$log" == *"Success"* ]]; then
    echo "安装失败"
    log="$(busybox "pm install -r -t -d -g $file </dev/null 2>/dev/null | cat")"
    if [[ ! "$log" == *"Success"* ]]; then
      echo "安装失败"
      log="$(busybox "pm install -r -t -d -g $file </dev/null 2>/dev/null")"
      if [[ ! "$log" == *"Success"* ]]; then
        echo "安装失败"
      else
        # 设置一个变量表示成功
        Success=0
      fi
    else
      # 设置一个变量表示成功
      Success=0
    fi
  else
    # 设置一个变量表示成功
    Success=0
  fi
  # 如果成功则打印尝试安装成功
  if [ $Success -eq 0 ]; then
    echo "安装成功"
  fi
  echo ""
done

# 安装完成后删除自己所在的整个文件夹
rm -rf "$MODDIR"