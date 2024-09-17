#!/system/bin/sh
# 设置当前文件夹
moddir="${0%/*}"

echo "拉起守护脚本,并输出日志"
"$moddir/daemon.sh" &> "$moddir/daemon.log" 2>&1 &

return 2>/dev/null
exit 0>/dev/null