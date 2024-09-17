#!/bin/sh

# 设置脚本文件夹
moddir="${0%/*}"

# 定义结果 JSON 文件的路径
json_file="$moddir/../tmp/HMA_config.json"
# 定义外部配置文件的路径
whitelist="$moddir/whitelist.txt"
blacklist="$moddir/blacklist.txt"
excludelist="$moddir/excludelist.txt"
filtered_apps="$moddir/../tmp/applist.txt"

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
blacklist_apps=$(cat "$blacklist" | grep -v "^#" | grep -v "^$")
whitelist_apps=$(cat "$whitelist" | grep -v "^#" | grep -v "^$")
excludelist_apps=$(cat "$excludelist" | grep -v "^#" | grep -v "^$")

# 过滤排除名单中的app
filtered_apps=$(grep -v "^$" "$moddir/../tmp/applist.txt" | while read app; do
    if ! echo "$excludelist_apps" | grep -q "$app"; then
        echo "$app"
    fi
done)

# 使用jq构建JSON数组
blacklist_json=$(echo "$blacklist_apps" | jq -R . | jq -s .)
whitelist_json=$(echo "$whitelist_apps" | jq -R . | jq -s .)
filtered_apps_json=$(cat "$filtered_apps" | jq -R . | jq -s .)

# 构建 JSON 结构
cat > "$json_file" <<EOF
{"configVersion": 90,"detailLog": false,"maxLogSize": 512,"forceMountData": true,"templates": {"不可见名单": {"isWhitelist": false,"appList": $blacklist_json},"可见名单": {"isWhitelist": true,"appList": $whitelist_json}},"scope": {
EOF

# 将过滤后的app添加到scope中
echo -n "$filtered_apps" | tr ' ' '\n' | while read app; do
cat >> "$json_file" <<EOF
"$app": {"useWhitelist": false,"excludeSystemApps": false,"applyTemplates": ["不可见名单"],"extraAppList": []},
EOF
done

echo "}}" >> "$json_file"
# 去除换行符
last_line=$(tr -d '\n\r' < $json_file)
# 重新输出文件
echo -n "$last_line" > $json_file
# 修复 json文件
# 获取最后三个字符
last_three_chars=${last_line: -3}
# 检查最后三个字符是否为 ,}}
if [ "$last_three_chars" == ",}}" ]; then
    # 如果是，则替换为 }}
    sed -i '$s/,}}/}}/' "$json_file"
    echo "已将文件的最后三个字符替换为 }}"
fi

echo "JSON 文件已创建：$json_file"

# 隐藏应用列表注入配置文件
HMAPackageName="fuck.app.check"
HMA_FILE_PATH="/data/user/0/$HMAPackageName/files/config.json"
# 检查配置文件是否存在
if [ ! -f "$HMA_FILE_PATH" ]; then
    echo "HMA配置文件不存在，尝试启动应用并重新生成配置..."
    am start -n $HMAPackageName/.MainActivityLauncher </dev/null 2>&1 | cat
else
    # 文件存在，检查文件大小
    if [ $(stat -c%s "$HMA_FILE_PATH") -le 103 ]; then
        echo "HMA配置文件的大小，小于等于103B，清空应用数据并重新启动..."
        rm -rf /data/user/0/$HMAPackageName/*
        sleep 0.5s
        am start -n $HMAPackageName/.MainActivityLauncher </dev/null 2>&1 | cat
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
sleep 2s
# 停止应用，防止出错
am force-stop $HMAPackage </dev/null 2>&1 | cat
if [ $? -eq 0 ]; then
    echo "应用已停止"
fi
#mv -f $HMA_FILE_PATH $HMA_FILE_PATH.bak
# 释放新的配置文件到应用目录
echo "向应用释放新的配置文件..."
cat "$json_file" > "/sdcard/hma.json"
rm -rf /data/system/hide_my_applist_*/config.json
sleep 1s
# 设置权限
chown $(stat -c '%U:%G' "$HMA_FILE_PATH.bak") "$HMA_FILE_PATH"
chmod $(stat -c '%a' "$HMA_FILE_PATH.bak") "$HMA_FILE_PATH"
# 检查文件是否成功写入
if [ $(stat -c%s "$HMA_FILE_PATH") -le 103 ]; then
    echo "配置文件写入失败，请检查app是否安装成功并运行，且拥有写入权限"
else
    echo "配置文件成功写入"
fi

return 2>/dev/null
exit 0>/dev/null