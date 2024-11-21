#!/bin/sh
#set -x
# 设置终端UTF8支持
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 设置脚本文件夹
MODDIR="${0%/*}"

# 定义 JSON 文件的路径
# 查找命令行参数是否为空，为空才默认值
if [ -n "$1" ]; then
  json_file="$1"
  echo "传入json文件路径: $1"
else
  json_file="$MODDIR/HMA_Config.json"
fi
# 定义外部配置文件的路径
whitelist="$MODDIR/whitelist.txt"
blacklist="$MODDIR/blacklist.txt"
excludelist="$MODDIR/excludelist.txt"
applist="$MODDIR/../tmp/applist.txt"
temptext="$MODDIR/../tmp/temp.txt"
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
# 检查文件是否存在
if [[ -f "$json_file" ]]; then
  # 查找命令行参数是否为空，为空才解析菜单
  if [ -n "$2" ]; then
    configname="$2"
    echo "选择的模板名: $2"
  else
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
  fi

# 检查选择的配置项的 isWhitelist 是否为 true
is_whitelist=$(jq -r ".templates[\"$configname\"].isWhitelist" $json_file)
if [ "$is_whitelist" = "true" ]; then
  echo "您选择的配置模板 '$configname' 是白名单模板"
  if [ -z "$2" ]; then
    echo "将在 ${waittime}s 后开始生成，使用 Ctrl+C 退出执行"
    sleep ${waittime}
  fi
  echo "# 这里是只想被看到app名单，每行一个不允许其他字符" > "$whitelist"
  jq -r ".templates.[\"$configname\"].appList[]" $json_file >> "$whitelist"
  touch "$MODDIR/whitelist.mode"
fi
if [ "$is_whitelist" = "false" ]; then
  echo "您选择的配置模板 '$configname' 是黑名单模板"
  if [ -z "$2" ]; then
    echo "将在 ${waittime}s 后开始生成，使用 Ctrl+C 退出执行"
    sleep ${waittime}
  fi
  echo "# 这里是不想被看到app名单，每行一个不允许其他字符" > "$blacklist"
  jq -r ".templates.[\"$configname\"].appList[]" $json_file >> "$blacklist"
  rm -f "$MODDIR/whitelist.mode"
fi
echo ""

# 定义函数
get_excludelist() {
  echo "生成当前不生效列表..."
  echo "# 不希望生效隐藏的app名单，每行一个不允许其他字符" > "$excludelist"
  jq -r '.scope | keys[]' $json_file > "$temptext"
  # 调用dex过滤排除名单中的app
  filtered_apps=$(dalvikvm -cp "$MODDIR/../lib/FilterText.dex" FilterText -args "$applist" "$temptext")
  # 调用失败则
  if [[ -z "$filtered_apps" ]]; then
    grep -v "^$" "$applist" | grep -vwf "$temptext" >> "$excludelist"
  else
    echo "$filtered_apps" >> "$excludelist"
  fi
}
# 查找命令行参数是否为空
if [ -n "$3" ]; then
  echo "是否获取排除名单: $3"
  if [[ "$3" == "true" ]]; then
    get_excludelist
  fi
else
  # 菜单询问用户是否要生成当前生效列表
  echo "是否要以当前生效app来生成一个不生效列表？"
  options=("是" "否")
  select opt in "${options[@]}"; do
    if [ -n "$opt" ]; then
      # 拉起生成
      get_excludelist
      break
    else
      echo "未生成配置"
      break
    fi
  done
fi

else
  echo "未在 $json_file 发现配置文件，执行结束"
fi