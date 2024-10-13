#!/bin/sh

# 设置终端中文支持
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

# 设置当前文件夹
moddir="${0%/*}"
# 创建启动app用的函数
start_app() {
  # 启动隐藏应用列表app
  PackageName="io.github.vvb2060.keyattestation.local"
  # 记录当前传感器状态
  sensor_state=$(settings get system accelerometer_rotation 2>&1 </dev/null | cat)
  # 调用sdk自带的测试工具启动APP
  monkey -p $PackageName 1 &
  echo "当前重力传感器的状态: $sensor_state"
  if [[ "$sensor_state" == "0" ]]; then
    echo "已关闭自动旋转"
    settings put system accelerometer_rotation 0 </dev/null 2>&1 | cat
    settings put system accelerometer_rotation 0
  elif [[ "$sensor_state" == "1" ]]; then
    echo "已开启自动旋转"
    settings put system accelerometer_rotation 1 </dev/null 2>&1 | cat
    settings put system accelerometer_rotation 1
  elif [[ "$sensor_state" == "null" ]]; then
    echo "值不存在"
    settings delete system accelerometer_rotation </dev/null 2>&1 | cat
    settings delete system accelerometer_rotation
  else
    echo "未知的值"
  fi
}
echo "~~~~~~~~~~~密钥hash获取开始~~~~~~~~~~~"
# 检测标记是不是不存在
if [[ ! -f "$moddir/gethash.done" ]]; then
  #!/bin/bash
  # 只支持被修改版的 io.github.vvb2060.keyattestation.local

  until [ -d "/sdcard/Android" ]; do echo "wait 1s" && sleep 1; done
  # 启动app
  start_app

  # 等待一段时间，确保日志已经生成
  sleep 6
  # 补一次启动
  start_app
  sleep 6
  # 快速打印一次历史日志
  logcat=$(logcat -d | grep "KeyAttestationAPP")
  # 停止应用
  kill -9 $(top -b -n 1 | grep $PackageName | grep -v grep | awk '{print $1}') 2>/dev/null

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
        sed -i "s/^.*ro.boot.vbmeta.digest.*$/ro.boot.vbmeta.digest\=$hash/" "$moddir/system.prop"
        # 检查是否是有效的锁定密钥
        if [[ "$lockstate" == "true" ]]; then
          sed -i "s/^.*ro.boot.vbmeta.digest.*$/resetprop -n ro.boot.vbmeta.digest $hash/" "$moddir/daemon.sh"
          # 操作完成了，创建一个标记阻止下一次自动启动
          touch "$moddir/gethash.done"
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