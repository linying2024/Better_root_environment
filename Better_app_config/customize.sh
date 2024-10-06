#!/bin/bash
# shellcheck disable=SC2034
SKIPUNZIP=1
SKIPMOUNT=true
PROPFILE=true
POSTFSDATA=true
LATESTARTSERVICE=true
REPLACE="
"

# 设置终端中文支持
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

enforce_install_from_magisk_app() {
  if $BOOTMODE; then
    ui_print "- 不受支持的环境，请在app内安装"
    ui_print "- Unsupported environment, please install in app"
  else
    ui_print "*********************************************************"
    ui_print "! 不支持在 recovery 中安装"
    ui_print "! 一些 recovery 已经破坏了模块实现，在 recovery 安装将最终导致模块无法工作"
    ui_print "! 不受支持的环境，请在app内安装"
    
    ui_print "! Install from recovery is NOT supported"
    ui_print "! Some recoveries have broken the module implementation, and installing during recovery will ultimately cause the module to stop working."
    ui_print "- Unsupported environment, please install in app"
    abort "*********************************************************"
  fi
}

echo "++++++++++++++++++++++++++++++++"
echo "- 正在释放文件"
echo "- 模块文件：$ZIPFILE"
echo "- 模块目录：$MODPATH"
echo "- 缓存目录：$TMPDIR"
echo "-------------------------"
echo "- 手机型号: $(getprop ro.product.manufacturer) $(getprop ro.product.model)"
echo "- 设备代号: $(getprop ro.product.name)"
echo "- 设备指纹: $(getprop ro.build.fingerprint)"
echo "- 设备语言: $(getprop ro.product.locale)"
echo "- $(uname -o)版本代码: $(getprop ro.build.version.sdk)"
echo "- 当前运行位数: $(uname -m)"
echo "- linux内核版本名: $(uname -r)"
echo "++++++++++++++++++++++++++++++++"

echo "警告：请用户在使用本模块前慎重考虑上述风险提示及法律责任，确保自己具备足够的技术能力和风险意识。一旦使用本模块，即表示您已充分了解并自愿承担所有可能的风险和后果，包括但不限于因侵权问题而引发的法律责任"

filepath="/data/adb/modules/better_app_config"
# 解压模块到模块文件夹
unzip -o "$ZIPFILE" -d "$MODPATH" >&2;
# 检查是不是安装过
if [[ -d "$filepath" ]]; then
  echo "保留配置更新"
  # 把所有.txt结尾的配置文件移动到临时文件夹
  find "$MODPATH" -name "*.txt" -exec sh -c '
    file="{}";
    dir="$TMPDIR/$(dirname "{}")";
    mkdir -p "$dir";
    mv "$file" "$dir";
  ' \;
  # 强制删除白名单标记文件
  rm -f "$MODPATH/Hide_My_Applist/whitelist.mode"
  # 尝试取回所有可能的配置文件(但是不覆盖文件)
  cp -arn $filepath/Tricky_Store/* "$MODPATH/Tricky_Store"
  cp -arn $filepath/Hide_My_Applist/* "$MODPATH/Hide_My_Applist"
  # 把没有的配置文件补上
  cp -arn $TMPDIR/Tricky_Store/* "$MODPATH/Tricky_Store"
  cp -arn $TMPDIR/Hide_My_Applist/* "$MODPATH/Hide_My_Applist" 
  # 更新hash
  if [[ "$(grep "#ro.boot.vbmeta.digest" $filepath/system.prop)" == "" ]]; then
    echo "在 $filepath/system.prop 文件内发现已启用的重置hash"
    hash=$(grep "ro.boot.vbmeta.digest" $filepath/system.prop | awk '{print $NF}' | awk '{print substr($0, length($0)-63, 64)}')
  fi
  if [[ "$(grep "#ro.boot.vbmeta.digest" $filepath/daemon.sh)" == "" ]]; then
    echo "在 $filepath/daemon.sh 文件内发现已启用的重置hash"
    hash=$(grep "ro.boot.vbmeta.digest" $filepath/daemon.sh | awk '{print $NF}' | awk '{print substr($0, length($0)-63, 64)}')
  fi
  if [[ ! "$hash" == "" ]]; then
    echo "找到已设置的hash, 写入重置hash"
    sed -i "s/AD3BEA525340C96AB19D217EB7557B8033A70A8DE6D117A922BC0D3ECD89875F/$hash/g" $MODPATH/daemon.sh
    sed -i "s/AD3BEA525340C96AB19D217EB7557B8033A70A8DE6D117A922BC0D3ECD89875F/$hash/g" $MODPATH/system.prop
    sed -i 's/^#resetprop -n ro.boot.vbmeta.digest/resetprop -n ro.boot.vbmeta.digest/'  $MODPATH/daemon.sh
    sed -i 's/#ro.boot.vbmeta.digest/ro.boot.vbmeta.digest/g' $MODPATH/system.prop
  fi
else
  echo "释放LSPosed模块作用域配置文件"
  lspd_config_dir="/data/adb/lspd"
  mkdir -p "$lspd_config_dir"
  # 移除旧备份
  rm -rf "$lspd_config_dir/config.bak"
  # 备份原配置文件夹
  mv -f "$lspd_config_dir/config" "$lspd_config_dir/config.bak"
  # 释放文件
  cp -af "$MODPATH/lspd/config" "$lspd_config_dir"
fi

echo "设置模块文件权限777"
chmod -R 777 "$MODPATH"

echo "复制默认tricky_store配置文件"
ts_config_dir="/data/adb/tricky_store"
mkdir -p $ts_config_dir
cp -af "$MODPATH/Tricky_Store/keybox.xml" "$ts_config_dir"
#cp -af "$MODPATH/Tricky_Store/target.txt" "$ts_config_dir"
cp -af "$MODPATH/Tricky_Store/spoof_build_vars" "$ts_config_dir"

echo "APK安装"  
oldSelinux=$(getenforce)  
if [[ "$oldSelinux" == "Enforcing" ]]; then  
  echo "发现当前selinux模式为强制模式,将暂时切换为宽容模式使安装保持成功"  
  setenforce 0  
fi  
for file in "$MODPATH/apks"/*.apk; do  
  echo "安装apk文件 $file"  
  pm install -r -t -d -g "$file"  
done  
if [[ "$oldSelinux" == "Enforcing" ]]; then  
  echo "还原selinux模式为强制模式"  
  setenforce 1  
fi
