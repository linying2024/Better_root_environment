#!/bin/bash

# shellcheck disable=SC2034
SKIPUNZIP=1
SKIPMOUNT=true
PROPFILE=true
POSTFSDATA=true
LATESTARTSERVICE=true
REPLACE="
"

# 设置当前命令别名
KernelSUpath="/data/adb/ksud"
APatchpath="/data/adb/apd"
Magiskpath="magisk"

# 设置终端UTF8支持
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

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

if [[ "$(getprop ro.build.version.sdk)" -lt 27 ]]; then
  echo " %%%%%%%%%%%%%%%%%%%% "
  echo "本安装器只支持 SDK 27 (Android 8.1)以上, 您的Anroid安卓版本太低"
  echo " %%%%%%%%%%%%%%%%%%%% "
  exit 2
fi

echo "警告：请用户在使用本模块前慎重考虑上述风险提示及法律责任"
echo "确保自己具备足够的技术能力和风险意识。一旦使用本模块，"
echo "即表示您已充分了解并自愿承担所有可能的风险和后果，"
echo "包括但不限于因侵权问题而引发的法律责任，以及设备工作异常等问题"
sleep 3s

# 备份变量
oldMODPATH=$MODPATH
oldZIPFILE=$ZIPFILE

# 检测是否是干净的模块环境
echo " **************************************** "
# 使用find命令检查除'.'和'..'之外的任何内容
if [ "$(find "${oldMODPATH}/../../modules" -maxdepth 1 | wc -l)" -gt 2 ]; then
  echo "环境不是干净的，因为 ${oldMODPATH}/../../modules 目录内存在文件夹"
fi
# 遍历目录中的所有项目
for item in "${oldMODPATH}/.."*/; do
  # 去除尾部的斜杠和目录名，得到文件夹名
  DIR_NAME="${item%/}"
  DIR_NAME="${DIR_NAME##*/}"

  # 检查是否应该忽略的目录（比如'.'和'..'）
  if [ "$DIR_NAME" = "." ] || [ "$DIR_NAME" = ".." ]; then
    continue  # 跳过当前循环迭代
  fi

  # 检查文件夹名是否不为fast_config_root_environment
  if [ "$DIR_NAME" != "$(grep_prop id "${oldMODPATH}/module.prop")" ]; then
    echo "环境不是干净的，发现非期望的文件夹: $DIR_NAME"
    break
  fi
done
echo "如果环境不是干净的, 推荐改名/data下的adb文件夹重启手机可达到最佳效果"
echo " **************************************** "

echo "开始检测您的Root类型，如果出现多个请检查您的Root是否卸载干净"
ManagerNumber=0

# 检查 $KernelSUpath 是否可用
if command -v "$KernelSUpath" &> /dev/null; then
  ManagerType="KernelSU"
  echo "发现了KernelSU命令行文件可用"
  ManagerNumber=$(( $ManagerNumber + 1 ))
fi

# 检查 $APatchpath 是否可用
if command -v "$APatchpath" &> /dev/null; then
  ManagerType="APatch"
  echo "发现了APatch命令行文件可用"
  ManagerNumber=$(( $ManagerNumber + 1 ))
fi

# 检查 $Magiskpath 是否可用
if command -v "$Magiskpath" &> /dev/null; then
  ManagerType="Magisk"
  echo "发现了Magisk命令行文件可用"
  ManagerNumber=$(( $ManagerNumber + 1 ))
fi

# 如果没有找到任何支持的命令
if [ $ManagerNumber -eq 0 ]; then
  abort "未找到任何的命令行文件可用"
  exit 2
fi

# 构造完整的变量名
path_var_name="${ManagerType}path"
# 使用间接扩展来获取对应的路径变量
eval manager_path=\$$path_var_name
# 打印结果
echo "后续操作尝试使用 $manager_path 命令"

# 生成对应管理器的命令行安装命令
if [ $ManagerNumber -eq 1 ]; then
  if [ "$ManagerType" = "KernelSU" ] || [ "$ManagerType" = "APatch" ]; then
    cliCommand="$manager_path module install"
  elif [ "$ManagerType" = "Magisk" ]; then
    cliCommand="$manager_path --install-module"
  else
    abort "未找到任何的命令行文件可用"
    exit 2
  fi
else
  abort "⚠⚠⚠由于Root管理器命令行工具数量不唯一已退出安装"
  exit 2
fi

if [ -f "/sdcard/nomenu" ]; then
  echo "在/sdcard/发现文件nomenu，跳过音量键菜单"
else
  # 获取当前运行的应用包名,并根据包名输出不同的提示信息
  case "$(dumpsys window | grep -o 'mCurrentFocus=[^;]*' | sed -n 's/.*{\(.*\)}.*/\1/p' | sed 's/.* \(.*\)/\1/' | cut -d'/' -f1 | awk '{print $NF}')" in
    io.github.huskydg.magisk)
      echo "您正在使用 Magisk Delta 或 Kitsune Mask"
      echo "该版本已不受支持,建议更换其他root方式"
      # 音量键菜单
      echo ""
      echo " **************************************** "
      echo ""
      echo " ★请选择您希望的操作："
      echo ""
      echo " △按键无反应请更新管理器版本或联系作者"
      echo ""
      echo " ☞音量加 (音量 +)：无视警告继续安装"
      echo ""
      echo " ☞音量减 (音量 -)：退出安装"
      echo ""
      echo " ↕请根据提示按音量键进行选择"
      echo ""
      # 主循环
      while true; do
        # 使用 getevent 捕获按键事件
        action=$(getevent -lqc 1 2>/dev/null) ;
        # 检查是否捕获到按键事件
        if [[ -n "${action}" ]]; then
          # 判断按键事件
          if [[ "${action}" == *"KEY_VOLUMEUP"* ]]; then
            echo " ✔已选择：无视警告继续安装"
            echo ""
            echo "警告!!!: 作者将不会受理该操作产生的后果, 请自行承担"
            sleep 0.5s
            break
          elif [[ "${action}" == *"KEY_VOLUMEDOWN"* ]]; then
            echo " ✔已选择：退出安装"
            exit 127
          fi
        fi
      done
      echo ""
      echo " **************************************** "
      ;;
    io.github.vvb2060.magisk)
      echo "您正在使用 Magisk Alpha"
      ;;
    com.topjohnwu.magisk)
      echo "您正在使用 Magisk"
      ;;
    me.weishu.kernelsu)
      echo "您正在使用 KernelSU"
      ;;
    me.bmax.apatch)
      echo "您正在使用 APatch"
      ;;
    *)
      echo "无法识别您的获取root的类型. 您可能使用了Magisk的隐藏Magisk应用, 如果是这样您应该先还原Magisk应用再进行安装"
      # 音量键菜单
      echo ""
      echo " **************************************** "
      echo ""
      echo " ★请选择您希望的操作："
      echo ""
      echo " △按键无反应请更新管理器版本或联系作者"
      echo ""
      echo " ☞音量加 (音量 +)：无视警告继续安装"
      echo ""
      echo " ☞音量减 (音量 -)：退出安装"
      echo ""
      echo " ↕请根据提示按音量键进行选择"
      echo ""
      # 主循环
      while true; do
        # 使用 getevent 捕获按键事件
        action=$(getevent -lqc 1 2>/dev/null) ;
        # 检查是否捕获到按键事件
        if [[ -n "${action}" ]]; then
          # 判断按键事件
          if [[ "${action}" == *"KEY_VOLUMEUP"* ]]; then
            echo " ✔已选择：无视警告继续安装"
            echo ""
            echo "警告!!!: 作者将不会受理该操作产生的后果, 请自行承担"
            sleep 0.5s
            break
          elif [[ "${action}" == *"KEY_VOLUMEDOWN"* ]]; then
            echo " ✔已选择：退出安装"
            exit 127
          fi
        fi
      done
      echo ""
      echo " **************************************** "
      ;;
  esac
fi

unzip -o "$ZIPFILE" -d "$oldMODPATH" >&2;
echo "-------------------------"
echo "文件列表:"
echo "$(ls -R "$oldMODPATH")"
echo "-------------------------"

# 检查文件是否sha256错误
echo "@@@@@@@@@@@@@@@@@@@"
. "$oldMODPATH/test_sha256.sh" "$oldMODPATH"
echo "@@@@@@@@@@@@@@@@@@@"
# 验证完成删除验证文件
find "$oldMODPATH" -type f -name "*.sha256" -exec rm -f {} +

chmod -R 777 "$oldMODPATH"

# 设置解压路径
unzippath="/sdcard"
if [ "$ManagerType" = "APatch" ]; then
  echo "解压APatch内核模块到 $unzippath"
  cp -af "$oldMODPATH/KPM" "$unzippath"
  echo "已完成复制操作, APatch用户请手动安装kpm内核模块"
  sleep 3
fi

# 检查是否在Apatch或者KernelSU中安装
if [ -z "${KSU+set}" ] && [ -z "${APATCH+set}" ]; then
  if [[ "$MAGISK_VER_CODE" -lt "26402" ]]; then
    # 查找并检查是否有zygisk next 1.1.0+
    NoSupportZip=$(find "$oldMODPATH/modules" -type f -regex ".*/Zygisk-Next-[1-9]\+\.[1-9]+\+\.[0-9]+.*\.zip")
    # 检查变量是否非空
    if [ -n "$NoSupportZip" ]; then
      # 删除找到的文件
      rm -f $NoSupportZip
      echo "*********************************************************"
      echo "发现Zygisk Next,您的面具版本不支持,已为您移除"
      if [[ "$ZYGISK_ENABLED" == "0" ]]; then
        echo "发现您的面具Zygisk未开启,请注意开启您的面具自带的Zygisk"
      fi
      echo "*********************************************************"
    fi
  else
    if [[ "$ZYGISK_ENABLED" == "1" ]]; then
      echo "*********************************************************"
      echo "发现您的面具Zygisk已启用，请关闭它否则将工作异常"
      echo "*********************************************************"
      if [ -f "/sdcard/nomenu" ]; then
        echo "5秒后强制安装"
        sleep 5s
      else
        abort "安装失败"
        exit 2
      fi
    fi
  fi

  ui_print "- Magisk 版本号: $MAGISK_VER_CODE"
  if [ "$MAGISK_VER_CODE" -lt "27005" ]; then
    # 查找并检查是否有符合要求的文件
    NoSupportZip=$(find "$oldMODPATH/modules" -type f -name "*Shamiko*.zip")
    # 检查变量是否非空
    if [ -n "$NoSupportZip" ]; then
      # 删除找到的文件
      rm -f $NoSupportZip
      ui_print "*********************************************************"
      ui_print "! 发现安装程序内可能含有Shamiko模块, 已为您移除。因为您的面具版本不支持"
      ui_print "*********************************************************"
    fi
  else
    # 查找并检查是否有符合要求的文件
    NoSupportZip=$(find "$oldMODPATH/modules" -type f -name "*Shamiko*.zip")
    # 检查变量是否非空
    if [ -n "$NoSupportZip" ]; then
      # 使用for命令查找指定目录下的所有.zip文件
      for ZIPFILE in "$oldMODPATH/modules/magisk27005+"/*.zip; do
        echo "安装模块文件 $ZIPFILE"
        # 调用管理器install_module
        install_module
        if [ $? -eq 0 ]; then
          echo "安装完成"
        else
          echo "使用 默认 安装失败，尝试拉起命令行安装"
          $cliCommand "$ZIPFILE"
          if [ $? -eq 0 ]; then
            echo "安装完成"
          else
            echo "使用 $manager_path 安装失败"
          fi
        fi
      done
    fi
  fi
fi

if [ "$ManagerType" = "APatch" ]; then
  # 查找并检查是否有符合要求的文件
  NoSupportZip=$(find "$oldMODPATH/modules" -type f -name "*Shamiko*.zip")
  # 检查变量是否非空
  if [ -n "$NoSupportZip" ]; then
    # 删除找到的文件
    rm -f $NoSupportZip
    echo "*********************************************************"
    echo "发现安装程序内可能含有Shamiko模块, 已为您移除, APatch不支持Shamiko模块.请改用KP内核模块Cherish Peekaboo"
    echo "*********************************************************"
  fi
fi
 
# APK安装  
echo "APK安装环节(1/3)"
echo "正在将操作放到后台执行..."
# 用子shell的方式并行处理并且将日志输出到临时文件
TMP2="/data/local/tmp"
mkdir -p "$TMP2"
# 创建标记,表示apk安装还没完成
touch "$TMP2/waitInstall"
echo 'oldSelinux=$(getenforce)  
if [[ "$oldSelinux" == "Enforcing" ]]; then  
  echo "发现当前selinux模式为强制模式,将暂时切换为宽容模式使安装保持成功"  
  setenforce 0  
fi' > "$TMP2/installApk.sh"
echo "for file in \"$oldMODPATH/apks\"/*.apk; do" >> "$TMP2/installApk.sh"
echo '  echo "安装apk文件 $file"  
  pm install -r -t -d -g "$file"  
done  
if [[ "$oldSelinux" == "Enforcing" ]]; then  
  echo "还原selinux模式为强制模式"  
  setenforce 1  
fi' >> "$TMP2/installApk.sh"
echo "rm $TMP2/waitInstall" >> "$TMP2/installApk.sh"
chmod 777 -R -f "$TMP2"
sh "$TMP2/installApk.sh" > "$TMP2/installApk.log" 2>&1 &

# 模块安装
echo "模块安装环节(2/3)"
# 使用for命令查找指定目录下的所有.zip文件
for ZIPFILE in "$oldMODPATH/modules"/*.zip; do
  echo "安装模块文件 $ZIPFILE"
  # 调用管理器install_module
  install_module
  if [ $? -eq 0 ]; then
    echo "安装完成"
  else
    echo "使用 默认 安装失败，尝试拉起命令行安装"
    $cliCommand "$ZIPFILE"
    if [ $? -eq 0 ]; then
      echo "安装完成"
    else
      echo "使用 $manager_path 安装失败"
    fi
  fi
done

echo "进阶模块安装环节(3/3)"
if [[ "$(getprop ro.build.version.sdk)" -lt 29 ]]; then
  echo "! 不支持的安卓 SDK 版本代码: $API"
  echo "! 最小支持 SDK 29 (Android 10)"
  echo "跳过安装有该需求的相关模块"
else
  ui_print "- 您的安卓 SDK 版本代码为: $API"
  for ZIPFILE in "$oldMODPATH/modules/android10+"/*.zip; do
    echo "安装模块文件 $ZIPFILE"
    install_module
    if [ $? -eq 0 ]; then
      echo "安装完成"
    else
      echo "使用 默认 安装失败，尝试拉起命令行安装"
      $cliCommand "$ZIPFILE"
      if [ $? -eq 0 ]; then
        echo "安装完成"
      else
        echo "使用 $manager_path 安装失败"
      fi
    fi
  done
fi

echo "进入收尾工作"
# 进行默认配置
if [[ "$(getprop ro.build.version.sdk)" -lt 29 ]] && [ -d "$oldMODPATH/../safetynet-fix" ] || [ -d "$MODPATH/../../modules/safetynet-fix" ] ; then
  echo "由于您为安卓10+,默认禁用safetynet-fix, 需要请自行开启"
  touch "$oldMODPATH/../safetynet-fix/disable"
  touch "$oldMODPATH/../../modules/safetynet-fix/disable"
fi
if [ -d "$oldMODPATH/../zygisk_shamiko" ] || [ -d "$oldMODPATH/../../modules/zygisk_shamiko" ] ; then
  echo "默认开启shamiko白名单模式, 需要授权root请自行关闭"
  mkdir -p "$oldMODPATH/../../shamiko"
  touch "$oldMODPATH/../../shamiko/whitelist"
fi
if [ -d "$oldMODPATH/../selinuxHide" ] || [ -d "$oldMODPATH/../../modules/selinuxHide" ] ; then
  echo "默认禁用selinux隐藏, 需要请自行开启"
  touch "$oldMODPATH/../selinuxHide/disable"
  touch "$oldMODPATH/../../modules/selinuxHide/disable"
fi
if [ -d "$oldMODPATH/../zygisk-sui" ] || [ -d "$oldMODPATH/../../modules/zygisk-sui" ] ; then
  echo "默认禁用sui, 需要请自行开启"
  touch "$oldMODPATH/../zygisk-sui/disable"
  touch "$oldMODPATH/../../modules/zygisk-sui/disable"
fi

echo "复制免责声明"
cp -af $oldMODPATH/*.md "$unzippath"
echo "等待apk安装结束"
until [ ! -f "$TMP2/waitInstall" ]; do sleep 1; done
echo "打印apk安装日志"
echo "$(cat "$TMP2/installApk.log")" && rm -f $TMP2/installApk.log $TMP2/installApk.sh
echo "尝试为其他模块添加action.sh脚本"
cp -arn "$oldMODPATH/action/zygisk_lsposed/action.sh" "$oldMODPATH/../zygisk_lsposed/"
echo "安装操作完成，您可以准备重启了"

# 检查文件是否存在
if [ -f "/sdcard/nomenu" ]; then
  echo "在/sdcard/发现文件nomenu，跳过音量键菜单"
else
  # 音量键超时菜单
  echo ""
  echo " **************************************** "
  echo ""
  echo " ★请选择您希望的操作："
  echo ""
  echo " △按键无反应请更新管理器版本或联系作者"
  echo ""
  echo " ☞音量加 (音量 +)：复制模块(含KP模块),安装包,HMA配置文件到$unzippath"
  echo ""
  echo " ☞音量减 (音量 -)：跳过"
  echo ""
  echo " ↕请根据提示按音量键进行选择"
  echo ""
  # 主循环
  while true; do
    # 使用 getevent 捕获按键事件
    action=$(getevent -lqc 1 2>/dev/null) ;
    # 检查是否捕获到按键事件
    if [[ -n "${action}" ]]; then
      # 判断按键事件
      if [[ "${action}" == *"KEY_VOLUMEUP"* ]]; then
        echo " ✔已选择：复制模块,安装包,HMA配置文件到$unzippath"
        cp -af "$oldMODPATH/apks" "$unzippath"
        cp -af "$oldMODPATH/modules" "$unzippath"
        sleep 0.5s
        break
      elif [[ "${action}" == *"KEY_VOLUMEDOWN"* ]]; then
        echo " ✔已选择：跳过"
        break
      fi
    fi
  done
  echo ""
  echo " **************************************** "
fi