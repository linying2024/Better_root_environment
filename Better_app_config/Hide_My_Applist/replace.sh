#!/bin/sh

# 设置终端中文支持
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

# 设置脚本文件夹
moddir="${0%/*}"
# 定义结果 JSON 文件的路径
json_file="$moddir/../tmp/HMA_Config.json"

# 使用jq尝试解析JSON文件，并检查其退出状态码
# 如果jq解析失败，它将返回一个非零退出状态码
if ! jq -e . "$json_file" > /dev/null 2>&1; then
  echo "错误: 异常的json文件 '$json_file'"
  echo "中断执行"
  exit 127
else
  echo "释放新的配置文件..."
  # 隐藏应用列表注入配置文件
  HMAPackageName="fuck.app.check"
  HMA_FILE_PATH="/data/user/0/$HMAPackageName/files/config.json"
  # 检查配置文件是否存在
  if [ ! -f "$HMA_FILE_PATH" ]; then
    echo "HMA配置文件不存在，尝试启动应用并重新生成配置..."
    # 记录当前传感器状态
    sensor_state=$(settings get system accelerometer_rotation 2>&1 </dev/null | cat)
    # 调用sdk自带的测试工具启动APP
    monkey -p $HMAPackageName 1
    echo "当前重力传感器的状态: $sensor_state"
    if [[ "$sensor_state" == "0" ]]; then
      echo "已关闭自动旋转"
      settings put system accelerometer_rotation 0 </dev/null 2>&1 | cat
    elif [[ "$sensor_state" == "1" ]]; then
      echo "已开启自动旋转"
      settings put system accelerometer_rotation 1 </dev/null 2>&1 | cat
    elif [[ "$sensor_state" == "null" ]]; then
      echo "值不存在"
      settings delete system accelerometer_rotation </dev/null 2>&1 | cat
    else
      echo "未知的值"
    fi
    sleep 5
    # 强制停止应用
    kill -9 $(top -b -n 1 | grep $HMAPackageName | grep -v grep | awk '{print $1}')
  else
    # 文件存在，检查文件大小
    if [ $(stat -c%s "$HMA_FILE_PATH") -le 103 ]; then
      echo "HMA配置文件的大小，小于等于103B，清空应用数据并重新启动..."
      rm -rf /data/user/0/$HMAPackageName/*
      sleep 0.5s
      # 记录当前传感器状态
      sensor_state=$(settings get system accelerometer_rotation 2>&1 </dev/null | cat)
      # 调用sdk自带的测试工具启动APP
      monkey -p $HMAPackageName 1
      echo "当前重力传感器的状态: $sensor_state"
      if [[ "$sensor_state" == "0" ]]; then
        echo "已关闭自动旋转"
        settings put system accelerometer_rotation 0 </dev/null 2>&1 | cat
      elif [[ "$sensor_state" == "1" ]]; then
        echo "已开启自动旋转"
        settings put system accelerometer_rotation 1 </dev/null 2>&1 | cat
      elif [[ "$sensor_state" == "null" ]]; then
        echo "值不存在"
        settings delete system accelerometer_rotation </dev/null 2>&1 | cat
      else
        echo "未知的值"
      fi
      sleep 5
      # 强制停止应用
      kill -9 $(top -b -n 1 | grep $HMAPackageName | grep -v grep | awk '{print $1}')
    fi
  fi
  TryNumber=0
  # 等待文件重新生成
  while [ ! -f "$HMA_FILE_PATH" ]; do
  if [ "$TryNumber" -le 10 ]; then
    sleep 1
    if [ ! -f "$HMA_FILE_PATH" ]; then
      TryNumber=$(( $TryNumber + 1 ))
      echo "等待HMA配置文件重新生成..."
    fi
  else
    echo "长时间未检测到HMA配置文件，放弃等待配置文件"
    break
  fi
  done
  echo "准备替换旧的HMA配置文件..."
  sleep 0.5s
  # 停止应用，防止出错
  kill -9 $(top -b -n 1 | grep $HMAPackageName | grep -v grep | awk '{print $1}') 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "应用已停止"
  fi
  # 备份原配置文件
  cp -af $HMA_FILE_PATH $HMA_FILE_PATH.bak
  # 释放新的配置文件到应用目录
  echo "向应用释放新的配置文件..."
  cat "$json_file" > "$HMA_FILE_PATH"
  # 清除系统服务缓存，保留代码。正常不需要
  #rm -rf /data/system/hide_my_applist_*/config.json
  sleep 0.5s
  # 设置权限
  chown $(stat -c '%U:%G' "$HMA_FILE_PATH.bak") "$HMA_FILE_PATH"
  chmod $(stat -c '%a' "$HMA_FILE_PATH.bak") "$HMA_FILE_PATH"
  # 检查文件是否成功写入
  if [ $(stat -c%s "$HMA_FILE_PATH") -le 103 ]; then
    echo "配置文件写入失败，请检查app是否安装成功并运行，且拥有写入权限"
    # 还原原配置文件
    cp -af $HMA_FILE_PATH.bak $HMA_FILE_PATH
    if [ $? -eq 0 ]; then
      echo "还原原配置文件成功"
    else
      echo "还原原配置文件失败"
    fi
  else
    echo "配置文件成功写入"
    if [ -f "$moddir/reload" ]; then
      echo "启动app使新配置生效"
      # 记录当前传感器状态
      sensor_state=$(settings get system accelerometer_rotation 2>&1 </dev/null | cat)
      # 调用sdk自带的测试工具启动APP
      monkey -p $HMAPackageName 1
      echo "当前重力传感器的状态: $sensor_state"
      if [[ "$sensor_state" == "0" ]]; then
        echo "已关闭自动旋转"
        settings put system accelerometer_rotation 0 </dev/null 2>&1 | cat
      elif [[ "$sensor_state" == "1" ]]; then
        echo "已开启自动旋转"
        settings put system accelerometer_rotation 1 </dev/null 2>&1 | cat
      elif [[ "$sensor_state" == "null" ]]; then
        echo "值不存在"
        settings delete system accelerometer_rotation </dev/null 2>&1 | cat
      else
        echo "未知的值"
      fi
      sleep 5
      # 强制停止应用
      kill -9 $(top -b -n 1 | grep $HMAPackageName | grep -v grep | awk '{print $1}')
    else
      echo "重载配置文件被关闭，没有执行重载"
    fi
  fi
fi