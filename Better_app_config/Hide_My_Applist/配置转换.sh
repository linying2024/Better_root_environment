#!/bin/sh
#set -x
# 设置终端中文支持
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

# 设置脚本文件夹
moddir="${0%/*}"

# 定义 JSON 文件的路径
json_file="$moddir/HMA_Config.json"
# 定义外部配置文件的路径
whitelist="$moddir/whitelist.txt"
blacklist="$moddir/blacklist.txt"
excludelist="$moddir/excludelist.txt"
applist="$moddir/../tmp/applist.txt"
temptext="$moddir/../tmp/temp.txt"
# 反悔时间(秒)
waittime=3

# 强制等待android设备启动完成，防止未知错误
echo "等待设备启动..."
until [ -d "/sdcard/Android" ]; do echo "等待1s中..." && sleep 1; done
echo "设备已启动"

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
if ! command -v jq >/dev/null 2>&1; then
  echo "jq工具不存在，终止执行"
  exit 173
fi

if [[ -f "$json_file" ]]; then
# 解析 JSON 获取 templates 键的值
templates=$(jq -r '.templates | keys[]' $json_file)
# 显示菜单
echo "请选择一个您需要导入的配置："
select configname in $templates; do
  if [ -n "$configname" ]; then
    break
  else
    echo "无效的输入，请重新选择："
  fi
done
# 检查选择的配置项的 isWhitelist 是否为 true
is_whitelist=$(jq -r ".templates[\"$configname\"].isWhitelist" $json_file)
if [ "$is_whitelist" = "true" ]; then
  echo "您选择的配置模板 '$configname' 是白名单模板"
  echo "将在 ${waittime}s 后开始生成，使用 Ctrl+C 退出执行"
  sleep ${waittime}
  echo "# 这里是只想被看到app名单，每行一个不允许其他字符" > whitelist.txt
  jq -r ".templates.[\"$configname\"].appList[]" $json_file >> "$whitelist"
  touch whitelist.mode
else
  echo "您选择的配置模板 '$configname' 是黑名单模板"
  echo "将在 ${waittime}s 后开始生成，使用 Ctrl+C 退出执行"
  sleep ${waittime}
  echo "# 这里是不想被看到app名单，每行一个不允许其他字符" > blacklist.txt
  jq -r ".templates.[\"$configname\"].appList[]" $json_file >> "$blacklist"
  rm -f whitelist.mode
fi
echo ""
# 菜单询问用户是否要生成当前生效列表
echo "是否要生成当前生效的列表？"
options=("是" "否")
select opt in "${options[@]}"; do
  if [ -n "$opt" ]; then
    echo "生成当前不生效列表..."
    echo "# 不希望生效隐藏的app名单，每行一个不允许其他字符" > "$excludelist"
    jq -r '.scope | keys[]' $json_file > "$temptext"
    grep -v "^$" "$applist" | grep -vwf "$temptext" >> "$excludelist"
    break
  else
    echo "未生成配置"
    break
  fi
done

else
  echo "未在 $json_file 发现配置文件，执行结束"
fi