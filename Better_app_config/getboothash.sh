#!/bin/sh

# 设置终端中文支持
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

# 设置当前文件夹
MODDIR="${0%/*}"
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
# 创建启动app用的函数
start_app() {
  # 启动隐藏应用列表app
  PackageNamePrefix="io.github.vvb2060.keyattestation"
  echo "尝试打开app"
  # 执行am命令打开app并检查输出中是否包含"Error"字符串，有则尝试下一个方法
  Command="am start -n $PackageNamePrefix.local/$PackageNamePrefix.home.HomeActivity"
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
        monkey -p $PackageNamePrefix.local 1
        echo "当前重力传感器的状态: $sensor_state"
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
}
echo "~~~~~~~~~~~密钥hash获取开始~~~~~~~~~~~"
# 检测标记是不是不存在
if [[ ! -f "$MODDIR/gethash.done" ]]; then
  #!/bin/bash
  # 只支持被修改版的 io.github.vvb2060.keyattestation.local

  until [ -d "/sdcard/Android" ]; do echo "wait 1s" && sleep 1; done
  # 启动app
  start_app
  # 等待一段时间，确保日志已经生成
  sleep 6
  # 再次启动app，防止有设备开机过慢未打开
  start_app
  sleep 6
  # 快速打印一次历史日志
  logcat=$(logcat -d | grep "KeyAttestationAPP")
  # 停止应用
  kill -9 $(top -b -n 1 | grep $PackageNamePrefix.local | grep -v grep | awk '{print $1}') 2>/dev/null

  # 从日志中提取需要的值
  hash=$(echo "$logcat" | awk '/verifiedBootHash:/ {line=$0} END {print line}' | awk '{print $NF}')
  lockstate=$(echo "$logcat" | awk '/deviceLocked:/ {line=$0} END {print line}' | awk '{print $NF}')
  
  echo "您的设备boot hash为 $hash"
  echo "您的设备bootloader已锁定值为 $lockstate"
  
  # 检查是否获取到hash
  if [[ ! "$hash" == "" ]]; then
    # 检查hash是否只包含大小写字母和数字，并且长度为64
    if echo "$hash" | grep -Eq '^[a-zA-Z0-9]{64}$' > /dev/null; then
      if [ ! "$hash" = $(printf '%064d' 0) ]; then
        echo "找到有效hash, 写入重置hash"
        sed -i "s/^.*ro.boot.vbmeta.digest.*$/ro.boot.vbmeta.digest\=$hash/" "$MODDIR/system.prop"
        # 检查是否是有效的锁定密钥
        if [[ "$lockstate" == "true" ]]; then
          sed -i "s/^.*ro.boot.vbmeta.digest.*$/resetprop -n ro.boot.vbmeta.digest $hash/" "$MODDIR/daemon.sh"
          # 立即重置一次hash
          resetprop -n ro.boot.vbmeta.digest $hash
          # 操作完成了，创建一个标记阻止下一次自动启动
          touch "$MODDIR/gethash.done"
        else
          echo "发现设备未锁定，您的keybox密钥可能不是有效的"
        fi
      else
        echo "您的hash是64个0，这是无效的hash"
      fi
    else
      echo "无效的hash，您的hash必须是64位大小写字母和数字"
    fi
  else
    echo "未找到hash"
  fi
else
  echo "发现hash获取成功标记，跳过该操作"
fi
echo "~~~~~~~~~~~密钥hash获取结束~~~~~~~~~~~"

# 尝试还原一部分bl参数
resetprop ro.boot.flash.locked 1
resetprop ro.boot.verifiedbootstate green
resetprop ro.secureboot.lockstate locked
resetprop ro.boot.vbmeta.device_state locked
# 解决vab哈希值问题 by南方的南鸭@Coolapk
resetprop -n ro.boot.vbmeta.digest $hash