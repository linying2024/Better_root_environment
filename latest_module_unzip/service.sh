#!/system/bin/sh
MODDIR=${0%/*}

RebootCount=$(sed -n 's/^RebootCount=//p' $MODDIR/config.prop)
# 使用sed替换参数
sed -i "s/^description=.*/description=[需要重启的次数\/Number of reboots required: $RebootCount 次\/Times]/" $MODDIR/module.prop
NeedRebootCount=$(( $RebootCount - 1 ))
sed -i "s/^RebootCount=.*/RebootCount=$NeedRebootCount/" $MODDIR/config.prop

# 检查RebootCount是否小于等于0，如果是则在下一次重启移除自己
if [ "$RebootCount" -le 0 ]; then
    touch $MODDIR/remove
fi

sleep 40
# 隐藏应用列表包名
HMAPackageName="com.tsng.dyhhvf"
am start -n $HMAPackageName/.MainActivityLauncher

exit 0
