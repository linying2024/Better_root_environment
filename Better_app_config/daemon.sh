#!/bin/sh

# 忽略默认的正常退出信号 15
trap '' SIGTERM
# 忽略Ctrl+C的中断退出信号 2
#trap '' SIGINT

# 设置终端UTF8支持
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 赋值相关二进制路径到PATH供文件调用
export PATH=/data/adb/ksu/bin/:/data/adb/ap/bin/:/data/adb/magisk/:$PATH

# 强制等待android设备启动完成，防止未知错误
echo "等待设备启动..."
until [ -d "/sdcard/Android" ]; do echo "等待1s中..." && sleep 1; done
echo "设备已启动" | tee Start_Done

echo "强制等待 5s 后接着运行"
sleep 5s
# 尝试还原一部分参数
resetprop ro.boot.flash.locked 1
resetprop ro.boot.verifiedbootstate green
resetprop ro.secureboot.lockstate locked
resetprop ro.boot.vbmeta.device_state locked
# 解决官改包秘钥哈希值问题 by南方的南鸭@Coolapk
#resetprop -n ro.boot.vbmeta.digest AD3BEA525340C96AB19D217EB7557B8033A70A8DE6D117A922BC0D3ECD89875F
# LSPosed属性移除 by上官兮唐@Coolapk
#resetprop --delete persist.logd.size
#resetprop --delete persist.logd.size.crash
#resetprop --delete persist.logd.size.main
#resetprop -p --delete ro.dalvik.vm.native.bridge
# 解决hunter检测到9.0版本隐藏api调用已开启和momo非SDK接口限制失效 by 漾焐泷@Coolapk
# 常见由Fake Location导致
settings delete global hidden_api_policy
settings delete global hidden_api_policy_p_apps
settings delete global hidden_api_policy_pre_p_apps
settings delete global hidden_api_blacklist_exemptions
# momo隐藏项
# 隐藏数据未加密挂载参数被修改
resetprop ro.crypto.state encrypted
# 隐藏init.rc被修改
#resetprop init.svc.flash_recovery stopped
# 隐藏处于全局调试模式
resetprop ro.debuggable 0
# 解决发现twrp文件夹
rm -rf /data/media/0/rec
rm -rf /data/media/rec
mv -f /data/media/0/TWRP /data/media/0/rec
mv -f /data/media/TWRP /data/media/rec
mv -f /data/media/0/Fox /data/media/0/rec
mv -f /data/media/Fox /data/media/rec

# 设置当前文件夹
MODDIR="${0%/*}"
# 监控的目录
dir="/data/app"

# 检查是否以root权限执行
if [ "$(id -u)" -ne 0 ]; then
  echo "警告：未以root权限执行，接下来的操作可能失败"
fi

main_code() {
  echo ""
  # 检查日志大小是否超过上限
  if [ $(stat -c%s "$MODDIR/daemon.log") -ge 500000 ]; then
    echo "已经达到文件大小上限，清空文件"
    echo "# file size max! fill none" > "$MODDIR/daemon.log"
  fi

  # 删除旧文件
  rm -rf "$MODDIR/tmp_old"
  # 移动文件,以备份原文件
  mv -f "$MODDIR/tmp" "$MODDIR/tmp_old"

  if [ ! -d "$MODDIR/tmp" ]; then
    echo "目标文件夹不存在了，创建新文件夹：$MODDIR/tmp"
  fi
  mkdir -p "$MODDIR/tmp"
  mkdir -p "$(pwd)/tmp"

  echo "触发操作: $action" > "$MODDIR/tmp/check.update.log"
  echo "路径: $path" >> "$MODDIR/tmp/check.update.log"
  echo "文件： $file" >> "$MODDIR/tmp/check.update.log"

  # 获取所有第三方应用的包名，并捕获可能的错误。然后保存到临时文件 
  echo "正在直接获取第三方应用包名..."
  pm_list_packages_output=$(pm list packages -3 2>&1)

  if ! echo "$pm_list_packages_output" | grep -qE "^package:[a-zA-Z]"; then
    echo "错误：直接获取失败，二次尝试免root"
    echo "正在获取,第三方应用包名..."
    pm_list_packages_output="$(pm list packages -3 </dev/null 2>&1)"
  fi

  if ! echo "$pm_list_packages_output" | grep -qE "^package:[a-zA-Z]"; then
    echo "错误：直接获取失败，三次尝试免root"
    echo "正在获取,第三方应用包名..."
    pm_list_packages_output="$(pm list packages -3 </dev/null 2>&1 | cat)"
  fi

  if ! echo "$pm_list_packages_output" | grep -qE "^package:[a-zA-Z]"; then
    echo "错误：免root直接获取失败，尝试用root切换用户执行"
    echo "正在获取,第三方应用包名..."
    pm_list_packages_output="$(su 2000 -c 'pm list packages -3' 2>&1)"
  fi

  if ! echo "$pm_list_packages_output" | grep -qE "^package:[a-zA-Z]"; then
    echo "错误：获取失败，尝试用root更改selinux规则"
    # 获取当前的SELinux状态
    oldselinux=$(getenforce)
    # 判断是否是强制模式
    if [ "$oldselinux" = "Enforcing" ]; then
      echo "SELinux当前为强制模式，将暂时更改为宽容模式，防止获取包名失败"
      setenforce 0
    fi
    # 获取所有第三方应用的包名，并捕获可能的错误。然后保存到临时文件
    echo "正在selinux宽容模式获取,第三方应用包名..."
    pm_list_packages_output=$(pm list packages -3 2>&1)
    # 如果之前是强制模式，现在还原
    if [ "$oldselinux" = "Enforcing" ]; then
      echo "恢复SELinux至强制模式"
      setenforce 1
    fi
  fi
  
  # 使用正则表达式匹配以 'package:' 开头的行并且后面跟着任意数量的字母
  if ! echo "$pm_list_packages_output" | grep -qE "^package:[a-zA-Z]"; then
    echo "错误：无法获取第三方应用包名，请使用shizuku或者sui模块以root手动执行绕过此android限制"
    exit 1
  else
    # 将匹配到的包名写入临时文件
    echo "$pm_list_packages_output" | awk -F':' '{print $2}' | grep -E "^[a-zA-Z]" > "$MODDIR/tmp/applist.txt"
  fi
  
  echo "app列表获取操作完成"
  
  # 当上一次的列表文件存在时判断内容是否一致
  if [[ -f "$MODDIR/tmp_old/applist.txt" ]]; then
    if diff "$MODDIR/tmp_old/applist.txt" "$MODDIR/tmp/applist.txt" > /dev/null; then
      echo "文件内容一致，退出本次调用"
      return 1
    else
      echo "文件内容不一致，执行函数剩余代码"
    fi
  fi

  echo "拉起其他依赖脚本"
  sh "$MODDIR/Hide_My_Applist/get_config.sh" &> "$MODDIR/tmp/Hide_My_Applist.log" 2>&1 &
  sh "$MODDIR/Tricky_Store/get_config.sh" &> "$MODDIR/tmp/Tricky_Store.log" 2>&1 &

  # 这里可以根据需要添加更多逻辑
}

# 尝试获取hash
sh "$MODDIR/getboothash.sh" &> "$MODDIR/getboothash.log" 2>&1 &

# 设置初始描述
action="power on! first running"
path="$MODDIR"
file="$MODDIR/daemon.sh"
# 执行主代码
main_code

if [[ "$1" == "noService" ]]; then
  echo "接受到非服务开关，退出执行"
  exit 0
fi

# 检查系统上是否已经安装了可用的工具
if ! command -v inotifywait >/dev/null 2>&1; then
# 检测当前的系统架构并设置调用自带的工具
case "$(uname -m)" in
  aarch64|arm64)
    alias inotifywait="$MODDIR/lib/inotifywait_arm64"
    ;;
  *)
    alias inotifywait="$MODDIR/lib/inotifywait_arm"
    ;;
esac
fi
if ! command -v inotifywait >/dev/null 2>&1; then
  echo "无法调用 inotifywait，退出执行"
  return 2>/dev/null
  exit 0>/dev/null
fi

rmshizuku() {
# 删掉shizuku的app释放的库文件(检测这种东西也是无语住了)
# 初始化循环次数
local runCount=0
# 无限循环，确保脚本在inotifywait命令意外退出时能够重启
while true; do
  # 设置循环上限，防止出现意外时无限启动监听进程
  [ 100 -le "$runCount" ] && break
  # 运行次数递增
  runCount=$(( $runCount + 1 ))
  # 定义临时目录变量
  TMP="/data/local/tmp"
  # 创建临时目录，如果不存在的话
  mkdir -p "$TMP"
  # 定义一个函数，用于删除特定的文件和目录
  rmfile() {
    # 删除/shizuku/目录及其内容
    rm -rf "$TMP/shizuku/"
    # 删除/shizuku_starter文件
    rm -f "$TMP/shizuku_starter"
  }
  # 调用函数，立即删除一次特定的文件和目录
  rmfile
  # 使用inotifywait监控TMP目录下的创建事件
  inotifywait -m -e create -e delete --format '%w%f %e %f' "$TMP" | while read path action file; do
    # 检查创建的文件或目录是否是/shizuku/或/shizuku_starter
    if [ "$file" == "shizuku" ] || [ "$file" == "shizuku_starter" ]; then
      # 如果是，则打印消息并删除这些文件和目录
      echo "发现shizuku文件,开始删除"
      sleep 5
      rmfile
    fi
  done
done
}
#rmshizuku &

# 初始化循环次数
local runCount=0
# 无限循环以保持脚本运行
while true; do
  # 设置循环上限，防止出现意外时无限启动监听进程
  [ 100 -le "$runCount" ] && break
  # 运行次数递增
  runCount=$(( $runCount + 1 ))
  # 启动inotifywait命令，并将其PID输出到PID文件
  inotifywait -m -e create -e delete --format '%w%f %e %f' "$dir" | while read path action file; do
    # 执行主代码
    main_code
  done &
  # 获取最后一个后台进程的pid
  pid="$!"
  # 打印PID写入文件
  echo "inotifywait的进程pid预计为: $(( $pid - 1 ))"
  # 等待inotifywait进程结束
  wait $pid
  # 如果inotifywait进程结束，则可能是由于某些错误，提示一下
  echo "inotifywait未启动,尝试重新启动它..."
done

return 2>/dev/null
exit 0>/dev/null