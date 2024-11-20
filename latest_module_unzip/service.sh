#!/bin/sh

# 设置终端中文支持
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

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
PackageName="fuck.app.check"
# 封装一个含有绕过尝试的函数
tryCommand () {
  local Command="$1"

  $Command
  if [ $? -eq 0 ]; then
    $Command </dev/null 2>&1 | cat
    if [ $? -eq 0 ]; then
      $Command </dev/null 2>&1
      if [ $? -eq 0 ]; then
        return 1
      fi
    fi
  fi
}
echo "尝试打开app"
# 执行am命令打开app并检查输出中是否包含"Error"字符串，有则尝试下一个方法
Command="am start -n $PackageName/.MainActivityLauncher"
if echo "$($Command 2>&1)" | grep -q "Error"; then
  if echo "$($Command </dev/null 2>&1 | cat)" | grep -q "Error"; then
    if echo "$($Command </dev/null 2>&1)" | grep -q "Error"; then
      echo "直接打开失败，使用测试api打开"
      # 记录当前传感器状态
      Command="settings get system accelerometer_rotation"
      sensor_state=$($Command 2>/dev/null | tr -d '[:space:]' 2>/dev/null)
      if ! echo "$sensor_state" | grep -E '^[0-9]+$' > /dev/null; then
        sensor_state=$($Command </dev/null 2>/dev/null | tr -d '[:space:]' 2>/dev/null)
        if ! echo "$sensor_state" | grep -E '^[0-9]+$' > /dev/null; then
          sensor_state=$($Command </dev/null 2>/dev/null | cat | tr -d '[:space:]' 2>/dev/null)
        fi
      fi
      monkey -p $PackageName 1
      echo "当前重力传感器的状态: $sensor_state"
      # 调整传感器状态
      case "$sensor_state" in
      "0")
        echo "已关闭自动旋转"
        tryCommand "settings put system accelerometer_rotation 0"
        tryCommand "content insert --uri content://settings/system --bind name:s:accelerometer_rotation --bind value:i:0"
        ;;
      "1")
        echo "已开启自动旋转"
        ;;
      "null")
        echo "值不存在"
        ;;
      *)
        echo "未知的值"
        ;;
      esac
    fi
  fi
fi

# 创建空json让辅助模块正常运行(如果不使用隐藏应用列表报错为正常)
filepath=/data/system/hide_my_applist_*
cd $filepath
if [[ ! -f config.json ]]; then
  echo "{}" > config.json
  chown 9997:9997 config.json
  chmod 7777 config.json
fi

exit 0
