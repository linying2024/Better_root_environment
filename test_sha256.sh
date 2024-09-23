#!/bin/bash

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
  exit 2
fi

# 进入指定的目录
cd "$sha256path" || exit

# 使用 find 查找所有的 .sha256 文件
while IFS= read -r -d $'\0' sha256file; do
  # 获取对应的文件名
  file="${sha256file%.*}"

  echo ""
  # 检查文件是否存在
  if [ ! -f "$file" ]; then
    echo "警告: 找不到与 '$sha256file' 对应的文件 '$file'"
    echo "您可能未按照要求配置文件,请重新配置后安装"
    exit 1
  fi

  # 读取 .sha256 文件中的哈希值
  expected_hash=$(cat "$sha256file")

  # 计算当前文件的哈希值
  actual_hash=$(sha256sum "$file" | awk '{print $1}')

  # 校验哈希值
  if [ "$expected_hash" == "$actual_hash" ]; then
    echo "校验成功: '$file' 的 SHA256 哈希值与 '$sha256file' 中的一致"
  else
    echo "校验失败: '$file' 的 SHA256 哈希值与 '$sha256file' 中的不一致"
    echo "您的文件可能已经损坏，请重新下载"
    exit 1
  fi
done < <(find . -type f -name '*.sha256' -print0)

# 返回到原始目录（可选）
cd - > /dev/null