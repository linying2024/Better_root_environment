#!/bin/sh

# 设置终端中文支持
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

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
echo "设备已启动"
sleep 15
# 启动隐藏应用列表app
HMAPackageName="fuck.app.check"
# 记录当前传感器状态
sensor_state=$(settings get system accelerometer_rotation 2>&1 </dev/null | cat)
# 调用sdk自带的测试工具启动APP
monkey -p $HMAPackageName 1 &> "$MODDIR/apprunning.log" 2>&1 &
echo "当前重力传感器的状态: $sensor_state"
if [[ "$sensor_state" == "0" ]]; then
  echo "已关闭自动旋转"
  settings put system accelerometer_rotation 0 </dev/null 2>&1 | cat
  content insert --uri content://settings/system --bind name:s:accelerometer_rotation --bind value:i:0 </dev/null 2>&1 | cat
elif [[ "$sensor_state" == "1" ]]; then
  echo "已开启自动旋转"
elif [[ "$sensor_state" == "null" ]]; then
  echo "值不存在"
else
  echo "未知的值"
fi

# 创建空json让辅助模块正常运行(如果不使用隐藏应用列表报错为正常)
filepath=/data/system/hide_my_applist_*
cd $filepath
mv -f config.json config.json.bak
echo "{}" > config.json
chown 9997:9997 config.json
chmod 7777 config.json

exit 0
