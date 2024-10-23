#!/bin/bash

# 获取当前目录并进入
MODDIR=${0%/*}
cd "$MODDIR"

# 获取所有第三方应用的包名，并捕获可能的错误。然后保存到临时文件 
echo "正在免root获取主用户第三方应用包名..."
pm_list_packages_output=$(pm list packages --user 0 -3 </dev/null 2>&1)

if ! echo "$pm_list_packages_output" | grep -qE "^package:[a-zA-Z]"; then
  echo "错误：直接获取失败，尝试用root切换shell用户执行"
  echo "正在获取主用户第三方应用包名..."
  pm_list_packages_output="$(su 2000 -c 'pm list packages --user 0 -3' 2>&1)"
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
  echo "正在selinux宽容模式获取主用户第三方应用包名..."
  pm_list_packages_output=$(pm list packages --user 0 -3 2>&1)
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

echo "获取新hash"
rm -f "$MODDIR/gethash.done"
# 尝试获取hash
"$MODDIR/getboothash.sh" &> "$MODDIR/getboothash.log" 2>&1 &

echo "拉起更新密钥注入列表脚本"
"$MODDIR/Tricky_Store/get_config.sh" &> "$MODDIR/tmp/Tricky_Store.log" 2>&1
echo "拉起隐藏应用列表配置更新脚本"
"$MODDIR/Hide_My_Applist/get_config.sh" &> "$MODDIR/tmp/Hide_My_Applist.log" 2>&1 &