#!/system/bin/sh

# 强制等待android设备启动完成，防止未知错误
echo "等待设备启动..."
until [ -d "/sdcard/Android" ]; do echo "等待1s中..." && sleep 1; done
echo "设备已启动" | tee Start_Done

# 尝试还原一部分参数
resetprop ro.boot.flash.locked 1
resetprop ro.boot.verifiedbootstate green
resetprop ro.secureboot.lockstate locked
resetprop ro.boot.vbmeta.device_state locked
# 解决官改包秘钥哈希值问题 by南方的南鸭@Coolapk
#resetprop -n ro.boot.vbmeta.digest 12ADA0F9EE76BB134F96ECB4FF5E882C92FC011C861584BB2AFD62AAF42C1C57
# LSPosed属性移除 by上官兮唐@Coolapk
#resetprop --delete persist.logd.size
#resetprop --delete persist.logd.size.crash
#resetprop --delete persist.logd.size.main
#resetprop -p --delete ro.dalvik.vm.native.bridge

# 设置当前文件夹
moddir="${0%/*}"
# 监控的目录
dir="/data/app"

# 检查是否以root权限执行
if [ "$(id -u)" -ne 0 ]; then
  echo "警告：未以root权限执行，接下来的操作可能失败"
fi

main_code() {
  # 检查日志大小是否超过上限
  if [ $(stat -c%s "$moddir/daemon.log") -le 500000 ]; then
    echo "已经达到文件大小上限，清空文件"
    echo "# file size max! fill none" > "$moddir/daemon.log"
  fi

  # 删除旧文件
  rm -rf "$moddir/tmp_old"
  # 移动文件,以备份原文件
  mv -f "$moddir/tmp" "$moddir/tmp_old"

  if [ ! -d "$moddir/tmp" ]; then
    echo "目标文件夹不存在了，创建新文件夹：$moddir/tmp"
  fi
  mkdir -p "$moddir/tmp"
  mkdir -p "$(pwd)/tmp"

  echo "触发操作: $action" > "$moddir/tmp/check.update.log"
  echo "路径: $path" >> "$moddir/tmp/check.update.log"
  echo "文件： $file" >> "$moddir/tmp/check.update.log"

# 获取所有第三方应用的包名，并捕获可能的错误。然后保存到临时文件 
echo "正在获取第三方应用包名..."
pm_list_packages_output=$(pm list packages -3 2>&1)

if ! echo "$pm_list_packages_output" | grep -qE "^package:[a-zA-Z]"; then
  echo "错误：直接获取失败，尝试用root切换shell用户执行"
  echo "正在获取第三方应用包名..."
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
  echo "正在获取第三方应用包名..."
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
  echo "$pm_list_packages_output" | awk -F':' '{print $2}' | grep -E "^[a-zA-Z]" > "$moddir/tmp/applist.txt"
fi

echo "app列表获取操作完成"

echo "拉起其他依赖脚本"
"$moddir/Hide_App_List/get_config.sh" &> "$moddir/tmp/hma.log" 2>&1 &
"$moddir/Tricky_Store/get_config.sh" &> "$moddir/tmp/ts.log" 2>&1 &

  # 这里可以根据需要添加更多逻辑
}

action="power on! first running"
main_code

# 使用inotifywait持续监听指定文件夹创建和删除事件
"$moddir/lib/inotifywait_arm" -m -e create -e delete --format '%w%f %e %f' "$dir" | while read path action file; do

  main_code

done

return 2>/dev/null
exit 0>/dev/null