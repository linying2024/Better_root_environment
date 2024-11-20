#!/bin/sh
echo "尝试打开lsposed寄生管理器"
if echo "$(am start -c org.lsposed.manager.LAUNCH_MANAGER com.android.shell/.BugreportWarningActivity 2>&1)" | grep -q "Error"; then
  echo "直接打开失败,尝试使用广播方法启动"
  am broadcast -a "android.provider.Telephony.SECRET_CODE" -a "android.telephony.action.SECRET_CODE" -d "android_secret_code://5776733" "android"
fi