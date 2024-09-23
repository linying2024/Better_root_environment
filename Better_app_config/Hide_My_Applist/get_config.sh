#!/bin/sh

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
blacklist_apps=$(cat "$blacklist" | grep -v '^#' | grep -v '^$')
whitelist_apps=$(cat "$whitelist" | grep -v '^#' | grep -v '^$')
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

echo "释放新的配置文件..."
cat "$json_file" > "/sdcard/hma.json"

return 2>/dev/null
exit 0>/dev/null