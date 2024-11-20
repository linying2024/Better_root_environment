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