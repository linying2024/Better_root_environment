#!/bin/sh

# 设置终端中文支持
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

# 设置脚本文件夹
moddir="${0%/*}"

# 定义结果 JSON 文件的路径
json_file="$moddir/../tmp/HMA_config.json"
# 定义外部配置文件的路径
whitelist="$moddir/whitelist.txt"
blacklist="$moddir/blacklist.txt"
excludelist="$moddir/excludelist.txt"
applist="$moddir/../tmp/applist.txt"
temptext="$moddir/../tmp/temp.txt"

# 强制等待android设备启动完成，防止未知错误
echo "等待设备启动..."
until [ -d "/sdcard/Android" ]; do echo "等待1s中..." && sleep 1; done
echo "设备已启动" | tee Start_Done

# 检查是否以root权限执行
if [ "$(id -u)" -ne 0 ]; then
  echo "警告：未以root权限执行，接下来的操作可能失败"
fi

# 尝试读取
if [ "$(id -u)" == "0" ]; then
    cat /data/system/hide_my_applist_*/config.json > /dev/null
    if [ $? -eq 0 ]; then
      echo "检测到隐藏应用列表的系统服务文件，继续执行"
    else
      echo "未检测到隐藏应用列表的系统服务文件，中断执行"
      exit 173
    fi
fi

# 检查系统上是否已经安装了可用的 jq 命令
if ! command -v jq >/dev/null 2>&1; then
# 检测当前的系统架构并设置调用自带的jq
case "$(uname -m)" in
    x86_64|i?86)
        alias jq="$moddir/../lib/jq_i386"
        ;;
    *)
        alias jq="$moddir/../lib/jq_armel"
        ;;
esac
fi

# 读取外部文件中的包名列表，忽略以#开头的行和空行
if [ ! -f "$blacklist" ]; then
  echo "黑名单模板文件不存在，退出执行"
  exit 163
fi
blacklist_apps=$(cat "$blacklist" | grep -v '^#' | grep -v '^$')
if [ ! -f "$whitelist" ]; then
  echo "白名单模板文件不存在，退出执行"
  exit 163
fi
whitelist_apps=$(cat "$whitelist" | grep -v '^#' | grep -v '^$')
if [ ! -f "$excludelist" ]; then
  echo "排除注入名单文件不存在，退出执行"
  exit 163
fi
excludelist_apps=$(cat "$excludelist" | grep -v '^#' | grep -v '^$')

# 输出过滤后的文本
echo "$excludelist_apps" > "$temptext"
# 过滤排除名单中的app
filtered_apps=$(grep -v "^$" "$applist" | grep -vwf "$temptext")
# 清理临时文件
rm -f "$temptext"

# 使用jq构建JSON数组
blacklist_json=$(echo "$blacklist_apps" | jq -R . | jq -s '. | if length > 0 then . else null end')
whitelist_json=$(echo "$whitelist_apps" | jq -R . | jq -s '. | if length > 0 then . else null end')

# 为每个过滤后的app构建一个JSON对象
filtered_apps_json=$(echo "$filtered_apps" | jq -R . | jq -s --argjson blacklist "$blacklist_json" '. as $in | map(. as $app | {($app): {useWhitelist: false, excludeSystemApps: false, applyTemplates: ["不可见名单"], extraAppList: []}})')

# 构建 JSON 结构
jq -n --argjson blacklist "$blacklist_json" \
              --argjson whitelist "$whitelist_json" \
              --argjson filtered "$filtered_apps_json" '
  {
    configVersion: 90,
    detailLog: false,
    maxLogSize: 512,
    forceMountData: true,
    templates: {
      "不可见名单": { isWhitelist: false, appList: ($blacklist // []) },
      "可见名单": { isWhitelist: true, appList: ($whitelist // []) }
    },
    scope: ($filtered | to_entries | map({key: .key, value: .value}))
  }
' > "$json_file"

# 修复文件
echo "$(jq '.scope |= (map(.value) | add)' "$json_file")"  > "$json_file"
# 压缩json文件
echo "$(jq -c '.' "$json_file")" > "$json_file"

echo "JSON 文件已创建：$json_file"

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
        am start -n $HMAPackageName/.MainActivityLauncher </dev/null 2>&1
    else
        # 文件存在，检查文件大小
        if [ $(stat -c%s "$HMA_FILE_PATH") -le 103 ]; then
            echo "HMA配置文件的大小，小于等于103B，清空应用数据并重新启动..."
            rm -rf /data/user/0/$HMAPackageName/*
            sleep 0.5s
            am start -n $HMAPackageName/.MainActivityLauncher </dev/null 2>&1
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
            # 调用sdk自带的测试工具启动APP
            monkey -p fuck.app.check 1
            sleep 5
            # 停止应用，直接退出
            kill -9 $(top -b -n 1 | grep $HMAPackageName | grep -v grep | awk '{print $1}')
        else
            echo "重载配置文件被关闭，没有执行重载"
        fi
    fi
fi

return 2>/dev/null
exit 0>/dev/null