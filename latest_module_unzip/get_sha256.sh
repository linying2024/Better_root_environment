#!/bin/sh

# 设置终端中文支持
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

# 检查是否提供了一个目录作为参数,如果没有提供则使用当前目录
if [ "$#" -eq 0 ]; then
  sha256path="."
  echo "正确用法: $0 <目录>"
else
  sha256path="$1"
fi

# 验证提供的参数是否为一个目录
if [ ! -d "$sha256path" ]; then
  echo "错误: '$sha256path' 不是一个目录"
  exit 1
fi

# 使用 find 查找所有非目录文件
while IFS= read -r -d $'\0' file; do
  # 检查文件名是否以 .sha256 结尾
  if [[ "$file" == *.sha256 ]]; then
    continue
  fi

  echo ""
  # 为每个文件生成 SHA256 哈希值
  hash=$(sha256sum "$file" | awk '{print $1}')

  # 检查 sha256sum 是否成功执行
  if [ $? -ne 0 ]; then
    echo "生成 $file 的 SHA256 哈希值时出错"
    continue
  fi

  # 将哈希值写入对应的 .sha256 文件
  sha256file="${file}.sha256"
  echo -n "$hash" > "$sha256file"

  # 输出一条消息表示已完成
  echo "已将 $file 的 SHA256 哈希值保存到 $sha256file"
done < <(find "$sha256path" -type f -print0)