#!/bin/sh

# 设置终端中文支持
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

# 强制等待android设备启动完成，防止未知错误
echo "等待设备启动..."
until [ -d "/sdcard/Android" ]; do echo "等待1s中..." && sleep 1; done
echo "设备已启动" | tee Start_Done

# 设置脚本文件夹
moddir="${0%/*}"

# 初始化变量
# 设置模块路径参数
MODDIR=/data/adb/modules/tricky_store
CONFIG_DIR=/data/adb/tricky_store
# 设置已过滤文件的输出位置,和缓存文件位置
target_file_path="$moddir/../tmp/target.txt"
temp_file_path="$moddir/../tmp/applist.txt"
# 设置tee是否损坏,设置为"yes"会在包名末尾添加"!"
tee_broken="no"
# 定义黑名单和白名单文件的路径
# 白名单内的app包名无论发生什么逐行都会添加到文件内
# 黑名单内的app包名当发现时会被从文件内删除
# 格式例如:
# com.demo.app1
# com.demo.app2
# 使用 # 作为开头的会被忽略
blacklist_file="$moddir/blacklist.txt"
whitelist_file="$moddir/whitelist.txt"

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

# 检查是否以root权限执行
if [ "$(id -u)" -ne 0 ]; then
  echo "警告：未以root权限执行，接下来的操作可能失败"
else
  # 检查模块是否存在，否则退出该脚本
  if [ ! -d "/data/adb/modules/tricky_store" ] && [ ! -d "/data/adb/modules_update/tricky_store" ]; then
    echo "*********************************************************"
    echo "! 未找到已经安装的 tricky_store !"
    echo "! 请先安装 tricky_store 后执行"
    echo "*********************************************************"
    exit 2
  fi
  
  if [ -f "/data/adb/modules/tricky_store/disable" ]; then
    echo "*********************************************************"
    echo "! tricky_store是关闭的 !"
    echo "! 请先打开 tricky_store 后再执行"
    echo "*********************************************************"
    exit 2
  fi
  
  if [ -f "/data/adb/modules/tricky_store/remove" ]; then
    echo "*********************************************************"
    echo "! tricky_store 即将被移除 !"
    echo "! 请重新安装 tricky_store 后再执行"
    echo "*********************************************************"
    exit 2
  fi
fi

# 封装写入文件的函数
function write {
  local app=$1
  if [[ "$tee_broken" == "yes" ]]; then
    echo "$app!" >> "$target_file_path"
  else
    echo "$app" >> "$target_file_path"
  fi
}

# 检查是否以root权限执行
if [ "$(id -u)" -ne 0 ]; then
  echo "警告：未以root权限执行，接下来的操作可能失败"
fi

# 打印分隔符
echo "#WhiteListStart" > "$target_file_path"

# 读取白名单文件
if [ ! -s "$whitelist_file" ]; then
  echo "白名单文件为空或者不存在，跳过白名单处理"
else
  echo "正在处理白名单..."
  # 逐行读取白名单文件的内容
  while IFS= read -r app || [ -n "$app" ]; do
    # 检查行是否以 '#' 开头,并且不为空
    if [ ! "${app:0:1}" = "#" ] && [ -n "$app" ]; then
      write "$app"
    fi
  done < "$whitelist_file"
fi

# 打印分隔符
echo "#WhiteListDone" >> "$target_file_path"
echo "" >> "$target_file_path"
echo "#BlackListStart" >> "$target_file_path"

# 读取黑名单文件
if [ ! -s "$blacklist_file" ]; then
  echo "黑名单文件为空，跳过黑名单处理。"
  while IFS= read -r app || [ -n "$app" ]; do
    if [ -n "$app" ]; then
      write "$app"
    fi
  done < "$temp_file_path"
else
  echo "正在处理黑名单..."
  # 调用dex过滤排除名单中的app
  filtered_apps=$(dalvikvm -cp "$moddir/../lib/FilterText.dex" FilterText -args "$temp_file_path" "$blacklist_file")
  if [[ -z "$filtered_apps" ]]; then
    echo "dex过滤失败，采用第二种办法"
    while IFS= read -r app || [ -n "$app" ]; do
      # 初始化变量不为黑名单内
      is_blacklisted=false
      while IFS= read -r black_app || [ -n "$black_app" ]; do
        if [ ! "${black_app:0:1}" = "#" ] && [ -n "$black_app" ]; then
          if [ "$app" = "$black_app" ]; then
            # 发现处于黑名单内，设置是黑名单app
            is_blacklisted=true
            break
          fi
        fi
      done < "$blacklist_file"
      if [ "$is_blacklisted" = false ] && [ -n "$app" ]; then
        write "$app"
      fi
    done < "$temp_file_path"
  else
    echo "调用dex过滤成功，检查tee开关状态"
    echo "$filtered_apps" > "$target_file_path.bak"
    if [[ "$tee_broken" == "yes" ]]; then
      while IFS= read -r app || [ -n "$app" ]; do
        if [ -n "$app" ]; then
          write "$app"
        fi
      done < "$target_file_path.bak"
    else
      # 直接写入
      echo "$filtered_apps" >> "$target_file_path"
    fi
    # 删除临时文件
    rm -f "$target_file_path.bak"
  fi
fi

# 打印分隔符
echo "#BlackListDone" >> "$target_file_path"

echo "生成配置文件操作完成"

if [[ -f "$moddir/../tmp/target.txt" ]]; then
  echo "配置文件存在, 拉起文件替换脚本"
  "$moddir/replace.sh" &> "$moddir/../tmp/tricky_store_replace.log" 2>&1 &
fi

return 2>/dev/null
exit 2</dev/null