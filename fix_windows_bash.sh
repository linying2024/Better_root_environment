#!/bin/bash  
  
# 检查是否提供了目录作为参数  
if [ "$#" -eq 0 ]; then  
    # 如果没有提供参数，则使用当前目录  
    DIRECTORY="."  
else  
    # 如果提供了参数，则使用提供的目录  
    DIRECTORY=$1  
    # 检查目录是否存在  
    if [ ! -d "$DIRECTORY" ]; then  
        echo "错误: '$DIRECTORY' 不是一个有效的目录。"  
        exit 1  
    fi  
fi  
  
# 使用 find 命令查找所有 .sh 文件，并通过 -exec 调用 dos2unix 修复它们  
echo "正在查找并修复 $DIRECTORY 及其子目录下的所有 .sh 文件..."  
find "$DIRECTORY" -type f -name "*.sh" -exec dos2unix {} +  
  
# 输出完成消息  
read -p "修复完成, 回车退出"