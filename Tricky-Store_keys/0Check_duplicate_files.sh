#!/bin/bash
# 指定的文件夹路径
directory=${0%/*}

# 创建一个临时文件来存储哈希值和文件路径
temp_file=$(mktemp)

# 遍历文件夹中的所有文件
find "$directory" -type f | while read -r file; do
    # 计算文件的SHA256哈希值
    sha256=$(sha256sum "$file" | awk '{print $1}')
    
    # 检查哈希值是否已经存在于临时文件中
    if grep -q "^$sha256 " "$temp_file"; then
        # 如果存在，打印重复文件的路径
        echo "Duplicate file found:"
        echo " - $file"
        grep "^$sha256 " "$temp_file" | cut -d' ' -f2
    else
        # 如果不存在，将哈希值和文件路径添加到临时文件中
        echo "$sha256 $file" >> "$temp_file"
    fi
done

# 清理临时文件
rm "$temp_file"

echo "SHA256 verification complete."
