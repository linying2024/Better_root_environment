#!/bin/bash

# 设置终端UTF8支持
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 获取当前目录并进入
MODDIR=${0%/*}
cd "$MODDIR"

echo "删除标记文件，获取新hash"
"$MODDIR/lib/busybox_run.sh" "rm -f "$MODDIR/gethash.done""
echo "删除日志缓存"
"$MODDIR/lib/busybox_run.sh" "rm -rf "$MODDIR/tmp""
"$MODDIR/lib/busybox_run.sh" "rm -rf "$MODDIR/tmp_old""

# 拉起一次获取
"$MODDIR/lib/busybox_run.sh" "sh "$MODDIR/daemon.sh" "noService""