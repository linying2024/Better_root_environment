#!/bin/sh

# 设置终端中文支持
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

# 设置脚本文件夹和JSON文件路径
MODDIR="${0%/*}"
json_file="$MODDIR/../tmp/HMA_Config.json"

# 检查系统上是否已经安装了可用的 jq 命令
if ! command -v jq >/dev/null 2>&1; then
# 检测当前的系统架构并设置调用自带的jq
case "$(uname -m)" in
  x86_64|i?86)
    alias jq="$MODDIR/../lib/jq-linux-i386"
    ;;
  aarch64|arm64)
    alias jq="$MODDIR/../lib/jq-linux-arm64"
    ;;
  *)
    alias jq="$MODDIR/../lib/jq-linux-armel"
    ;;
esac
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "无法调用 jq 命令"
  exit
fi

# 使用jq解析JSON文件
if ! jq -e . "$json_file" > /dev/null 2>&1; then
  echo "错误: 异常的json文件 '$json_file'"
  echo "中断执行"
  exit 127
fi

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

# 定义HMA配置文件路径和操作函数
PackageName="fuck.app.check"
HMA_FILE_PATH="/data/user/0/$PackageName/files/config.json"
check_and_restart_app() {
  if [ ! -f "$HMA_FILE_PATH" ]; then
    echo "HMA配置文件不存在，尝试启动应用并重新生成配置..."
    restart_app
  else
    check_file_size "$HMA_FILE_PATH"
  fi
}

# 重启应用并检查文件大小
restart_app() {
  echo "尝试打开app"
  # 执行am命令打开app并检查输出中是否包含"Error"字符串，有则尝试下一个方法
  Command="am start -n $PackageName/.MainActivityLauncher"
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
        monkey -p $PackageName 1
        echo "当前重力传感器的状态: $sensor_state"
        # 调整传感器状态
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
  sleep 5
  # 强制停止应用
  kill -9 $(top -b -n 1 | grep $PackageName | grep -v grep | awk '{print $1}')
}

# 检查文件大小并重启应用
check_file_size() {
  local file_path=$1
  if [ $(stat -c%s "$file_path") -le 103 ]; then
    echo "HMA配置文件的大小，小于等于103B，清空应用数据并重新启动..."
    rm -rf /data/user/0/$PackageName/*
    sleep 0.5s
    restart_app
  fi
}

# 等待文件重新生成
wait_for_file() {
  local file_path=$1
  local max_tries=10
  local try_number=0
  while [ ! -f "$file_path" ]; do
    if [ "$try_number" -le "$max_tries" ]; then
      sleep 1
      echo "等待HMA配置文件重新生成..."
      ((try_number++))
    else
      echo "长时间未检测到HMA配置文件，放弃等待配置文件"
      return 1
    fi
  done
  return 0
}

replace_config() {
  echo "准备替换旧的HMA配置文件..."
  sleep 0.5s
  kill -9 $(top -b -n 1 | grep $PackageName | grep -v grep | awk '{print $1}') 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "应用已停止"
  fi
  cp -af $HMA_FILE_PATH $HMA_FILE_PATH.bak
  echo "向应用释放新的配置文件..."
  cat "$json_file" > "$HMA_FILE_PATH"
  chown $(stat -c '%U:%G' "$HMA_FILE_PATH.bak") "$HMA_FILE_PATH"
  chmod $(stat -c '%a' "$HMA_FILE_PATH.bak") "$HMA_FILE_PATH"
  if [ $(stat -c%s "$HMA_FILE_PATH") -le 103 ]; then
    echo "配置文件写入失败，请检查app是否安装成功并运行，且拥有写入权限"
    cp -af $HMA_FILE_PATH.bak $HMA_FILE_PATH
    if [ $? -eq 0 ]; then
      echo "还原原配置文件成功"
    else
      echo "还原原配置文件失败"
    fi
  else
    echo "配置文件成功写入"
    if [ -f "$MODDIR/reload" ]; then
      echo "启动app使新配置生效"
      restart_app
    else
      echo "重载配置文件被关闭，没有执行重载"
    fi
  fi
}

# 主逻辑
check_and_restart_app
wait_for_file "$HMA_FILE_PATH" && replace_config