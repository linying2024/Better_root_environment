#!/bin/bash
# shellcheck disable=SC2034
SKIPUNZIP=1
SKIPMOUNT=true
PROPFILE=true
POSTFSDATA=true
LATESTARTSERVICE=true
REPLACE="
"

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

unzip -o "$ZIPFILE" -d "$MODPATH" >&2;
echo "-------------------------"
echo "文件列表:"
echo "$(ls -R "$MODPATH")"
echo "-------------------------"

echo "设置模块文件权限777"
chmod -R 777 "$MODPATH"

echo "复制默认tricky_store配置文件"
ts_config_dir="/data/adb/tricky_store"
mkdir -p $ts_config_dir
cp -af "$MODPATH/Tricky_Store/keybox.xml" "$ts_config_dir"
cp -af "$MODPATH/Tricky_Store/target.txt" "$ts_config_dir"
cp -af "$MODPATH/Tricky_Store/spoof_build_vars" "$ts_config_dir"

echo "释放LSPosed模块作用域配置文件"
lspd_config_dir="/data/adb/lspd"
mkdir -p "$lspd_config_dir"
# 移除旧备份
rm -rf "$lspd_config_dir/config.bak"
# 备份原配置文件夹
mv -f "$lspd_config_dir/config" "$lspd_config_dir/config.bak"
# 释放文件
cp -af "$MODPATH/lspd/config" "$lspd_config_dir"