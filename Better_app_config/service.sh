#!/bin/sh

# 设置终端中文支持
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

# 设置当前文件夹
moddir="${0%/*}"

echo "拉起守护脚本,并输出日志"
"$moddir/daemon.sh" &> "$moddir/daemon.log" 2>&1 &

# 强制等待android设备启动完成，防止未知错误
echo "等待设备启动..."
until [ -d "/sdcard/Android" ]; do echo "等待1s中..." && sleep 1; done
echo "设备已启动"
sleep 15
sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ ✓模块已载入 ] /g' "$moddir/module.prop"

return 2>/dev/null
exit 0>/dev/null