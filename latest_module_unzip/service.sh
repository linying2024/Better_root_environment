#!/system/bin/sh
MODDIR=${0%/*}

RebootCount=$(sed -n 's/^RebootCount=//p' $MODDIR/config.prop)
# 使用sed替换参数
sed -Ei "s/^description=(\[.*][[:space:]]*)?/description=[ ✘还需要重启 $RebootCount 次 ] /g" "$MODDIR/module.prop"
NeedRebootCount=$(( $RebootCount - 1 ))
sed -i "s/^RebootCount=.*/RebootCount=$NeedRebootCount/" $MODDIR/config.prop

# 检查RebootCount是否小于等于0，如果是则在下一次重启移除自己
if [ "$RebootCount" -le 0 ]; then
    sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ ✔配置完成,将在下一次删除安装器 ] /g' "$MODDIR/module.prop"
    touch $MODDIR/remove
fi


# 强制等待android设备启动完成，防止未知错误
echo "等待设备启动..."
until [ -d "/sdcard/Android" ]; do echo "等待1s中..." && sleep 1; done
echo "设备已启动" | tee Start_Done
sleep 20
# 隐藏应用列表包名
HMAPackageName="fuck.app.check"
am start -n $HMAPackageName/.MainActivityLauncher

exit 0
