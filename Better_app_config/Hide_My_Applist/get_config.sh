#!/bin/sh

# 设置终端UTF8支持
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 设置脚本文件夹
MODDIR="${0%/*}"

# 定义结果 JSON 文件的路径
json_file="$MODDIR/../tmp/HMA_Config.json"
# 定义外部配置文件的路径
whitelist="$MODDIR/whitelist.txt"
blacklist="$MODDIR/blacklist.txt"
excludelist="$MODDIR/excludelist.txt"
applist="$MODDIR/../tmp/applist.txt"
temptext="$MODDIR/../tmp/temp.txt"
PackageName="fuck.app.check"

# 强制等待android设备启动完成，防止未知错误
echo "等待设备启动..."
until [ -d "/sdcard/Android" ]; do echo "等待1s中..." && sleep 1; done
echo "设备已启动" | tee Start_Done

# 检查是否以root权限执行
if [ "$(id -u)" -ne 0 ]; then
  echo "警告：未以root权限执行，接下来的操作可能失败"
  # # 尝试读取
  # cat /data/system/hide_my_applist_*/config.json > /dev/null
  # if [ $? -eq 0 ]; then
    # echo "检测到隐藏应用列表的系统服务文件，继续执行"
  # else
    # echo "未检测到隐藏应用列表的系统服务文件，中断执行"
    # exit 173
  # fi
  # 过滤文件字符串
  if [ -z "$(cat $applist | grep "$PackageName")"]; then
    echo "没有安装被修改的隐藏应用列表"
    exit 173
  fi
fi

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
# 调用dex过滤排除名单中的app
filtered_apps=$(dalvikvm -cp "$MODDIR/../lib/FilterText.dex" FilterText -args "$applist" "$temptext")
# 检查是否为空，为空则更换另一个过滤方法
if [[ -z "$filtered_apps" ]]; then
  echo "过滤失败，尝试第二种方法"
  # 用gerp过滤列表保存到变量
  filtered_apps=$(grep -v "^$" "$applist" | grep -vwf "$temptext")
fi
# 检查是否为空，为空则放弃过滤直接全部生效
if [[ -z "$filtered_apps" ]]; then
  echo "过滤失败，直接使用app列表代替"
  filtered_apps=$(cat "$applist" | grep -v '^#' | grep -v '^$')
fi
# 清理临时文件
rm -f "$temptext"

# 使用jq构建JSON数组
blacklist_json=$(echo "$blacklist_apps" | jq -R . | jq -s '. | if length > 0 then . else null end')
whitelist_json=$(echo "$whitelist_apps" | jq -R . | jq -s '. | if length > 0 then . else null end')

# 为每个过滤后的app构建一个JSON对象
# 检测是否使用白名单模式进行隐藏
if [ -f "$MODDIR/whitelist.mode" ]; then
  filtered_apps_json=$(echo "$filtered_apps" | jq -R . | jq -s --argjson blacklist "$blacklist_json" '. as $in | map(. as $app | {($app): {useWhitelist: true, excludeSystemApps: true, applyTemplates: ["可见名单"], extraAppList: []}})')
else
  filtered_apps_json=$(echo "$filtered_apps" | jq -R . | jq -s --argjson blacklist "$blacklist_json" '. as $in | map(. as $app | {($app): {useWhitelist: false, excludeSystemApps: false, applyTemplates: ["不可见名单"], extraAppList: []}})')
fi

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
  echo "json文件格式检查通过, 拉起文件替换脚本"
  sh "$MODDIR/replace.sh" &> "$MODDIR/../tmp/Hide_My_Applist_replace.log" 2>&1 &
fi

return 2>/dev/null
exit 0>/dev/null