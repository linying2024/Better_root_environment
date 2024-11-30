#!/bin/bash

# set -x
echo "Version: 1.0(20241201001315)"
echo "Tip: MT管理器请使用终端扩展包执行"

# 指定目录
directory=${1:-./}

# 命令检查
check_command() {
  local command="$1"
  # 检查命令可执行性
  if ! command -v "$command" &> /dev/null; then
    echo "❌❌❌错误: $command 命令不存在"
    return 127
  fi
}
# 检查 xmlstarlet openssl wget curl 是否安装
if check_command "xmlstarlet"; then
  xmlTool="xmlstarlet"
else
  echo "🚨🚨🚨警告: xmlstarlet 命令不可用,推荐使用 xmlstarlet 以减少错误"
  xmlTool="shell"

  if ! check_command "tr"; then
    echo "❌❌❌错误: 没有 tr 工具,脚本无法继续执行"
    exit 127
  fi
fi
if ! check_command "openssl"; then
  echo "❌❌❌错误: 没有 openssl 证书工具,脚本无法继续执行"
  exit 127
fi
if check_command "wget"; then
  download_type="wget"
else
  echo "🚨🚨🚨警告: wget 命令不可用"
  if ! check_command "curl"; then
    echo "❌❌❌错误: 没有可用的下载工具,脚本无法继续执行"
    echo "您可以安装 wget 或者 curl 命令工具重试"
    exit 127
  fi
fi

# 重命名文件
file_rename() {
  local Mark="$1"
  local remove="${2:-0}"

  # 如果发现本次证书已被标记，则直接返回
  if [ "$error" -eq 1 ] && [[ "$Mark" == "Error_" ]]; then
    return 0
  fi
  if [ "$expired" -eq 1 ] && [[ "$Mark" == "Expired_" ]]; then
    return 0
  fi

  # 是否移除标签
  if [ -n "$remove" ] && [ "$remove" -eq 1 ]; then
    base_name=$(basename -- "$xml_file")
    if [[ "$base_name" == *"$Mark"* ]]; then
      echo "🚨警告: 发现错误的 $Mark 标记"
      # 如果文件名错误地包含字符串标记，则移除
      new_file_name="${base_name//$Mark/}"
      new_file_path="$(dirname -- "$xml_file")/$new_file_name"
      mv -- "$xml_file" "$new_file_path"
      echo "信息: 文件重命名：$xml_file -> $new_file_path"
      xml_file="$new_file_path"
    fi
  else
    base_name=$(basename -- "$xml_file")
    if [[ "$base_name" == *"$Mark"* ]]; then
      # 如果文件名已经有标记，则不添加
      echo "信息: 文件：$xml_file 已有 $Mark 标记"
    else
      # 添加文件名标记
      new_file_name="$Mark$base_name"
      new_file_path="$(dirname -- "$xml_file")/$new_file_name"
      mv -- "$xml_file" "$new_file_path"
      echo "信息: 文件重命名：$xml_file -> $new_file_path"
      xml_file="$new_file_path"
    fi
  fi
}

# 检查证书是否在有效期内
check_certificate_validity() {
  # 定义一个函数，接受一个证书文件路径作为参数
  local certificate="$1"
  # 获取当前的UTC时间戳
  local current_timestamp=$(date -u +%s)
  # 获取当前的UTC时间，格式为年.月.日 时:分:秒 UTC
  local current_time=$(date -u -d @$current_timestamp +%Y.%m.%d\ %H:%M:%S\ UTC)
  # 使用openssl命令获取证书的notBefore和notAfter值
  local not_before_value=$(openssl x509 -noout -dates -in "$certificate" | grep notBefore | cut -d= -f2)
  local not_after_value=$(openssl x509 -noout -dates -in "$certificate" | grep notAfter | cut -d= -f2)
  # 将notBefore和notAfter的值转换为可读的日期格式
  local not_before_time=$(date -d "$not_before_value" +%Y.%m.%d\ %H:%M:%S\ UTC)
  local not_after_time=$(date -d "$not_after_value" +%Y.%m.%d\ %H:%M:%S\ UTC)
  # 检查是否成功获取到了notBefore和notAfter的时间
  if [ "$not_before_time" == "" ] || [ "$not_after_time" == "" ]; then
    echo "❌❌❌错误: 无法从证书中提取有效期信息"
    return 1
  fi
  # 将notBefore和notAfter的时间转换为时间戳
  local not_before_timestamp=$(date -d "$not_before_value" +%s)
  local not_after_timestamp=$(date -d "$not_after_value" +%s)
  # 比较当前时间戳与证书的notBefore和notAfter时间戳
  if [ $current_timestamp -lt $not_before_timestamp ] || [ $current_timestamp -gt $not_after_timestamp ]; then
    echo "🚨🚨🚨警告: 当前时间 $current_time,证书时间为$not_before_time - $not_after_time.不是有效的证书"
    return 1
  fi
  # 如果当前时间在证书的有效期内，输出证书有效信息
  echo "信息: 当前时间 $current_time,证书在有效期内"
  return 0
}
# 检查私钥是否匹配
certKeyCheck() {
  # 示例调用
  # certKeyCheck "ec" "0cert.pem" "0certkey.pem"
  local certType="$1"
  local certFile="$2"
  local certKeyFile="$3"
  local cert_pubkey="./Temp_cert_pubkey.pem"
  local certkey_pubkey="./Temp_certkey_pubkey.pem"

  # 使用私钥生成公钥，忽略控制台输出
  if ! openssl "$certType" -pubout -in "$certKeyFile" -out "$certkey_pubkey" 2>/dev/null; then
    echo "❌❌❌错误: 无法从私钥文件中生成公钥"
    rm -f "$certkey_pubkey"
    return 1
  fi
  # 提取公钥证书中的公钥，忽略控制台输出
  if ! openssl x509 -pubkey -noout -in "$certFile" > "$cert_pubkey" 2>/dev/null; then
    echo "❌❌❌错误: 无法从证书文件中提取公钥"
    rm -f "$certkey_pubkey"
    return 1
  fi
  # 比较两个公钥
  if diff "$cert_pubkey" "$certkey_pubkey"; then
    echo "信息: 私钥中的公钥与证书的公钥匹配"
  else
    echo "🚨🚨🚨警告: 私钥中的公钥与证书的公钥不匹配"
  fi
  # 清理临时文件
  rm -f "$cert_pubkey" "$certkey_pubkey"
}

# 函数统一变量 $1为文件 $2为序数 $3为xml键名 $4为xml键名的属性名
# 提取证书序列号
extract_serial_number() {
  openssl x509 -inform PEM -noout -serial -in "$1" | cut -d'=' -f2
}
# 提取指定证书
extract_certificate_xmlstarlet() {
  xmlstarlet sel -t -v "(CertificateChain/Certificate)[$2]" "$1"
}
# 提取指定项
extract_certificate_custom_xmlstarlet() {
  if [ "$5" -ne 1 ]; then
    local option="-c"
  else
    local option="-v"
  fi
  xmlstarlet sel -t $option "(AndroidAttestation/Keybox/Key/$3)[$2]" "$1"
}
# 提取指定xml项
extract_custom_xml_shell() {
  # 设置局部变量
  local file="$1"
  local index="$2"
  local keyName="$3"
  local attributeName="$4"

  # 获取所有 keyName 开始行的行号
  begin_lines=($(grep -n "<${keyName}${attributeName}>" "$file" | cut -d: -f1))
  # 计算 keyName 结束行的行号
  end_lines=($(grep -n "</${keyName}>" "$file" | cut -d: -f1))
  # 检查个数
  if [ ${#begin_lines[@]} -lt $index ]; then
    echo "❌❌❌错误: 指定的序列号超过了xml元素的数量"
    return 1
  fi
  # 获取指定序数的证书的开始和结束行号
  begin_line=${begin_lines[$((index - 1))]}
  end_line=${end_lines[$((index - 1))]}
  # 提取指定xml内容，并且去掉其他xml内容(删除制表符/t，删除换行符/r，删除空格缩进)
  sed -n "${begin_line},${end_line}p" "$file" | sed "1s/^.*<${keyName}${attributeName}>//; \$s/<\/${keyName}>.*$//" | tr -d '\t\r' | sed 's/  //g'
}
# 提取指定项
extract_certificate_custom_shell() {
  extract_custom_xml_shell "$1" "$2" "$3" "$4"
}
# 提取指定序数的证书
extract_certificate_shell() {
  extract_custom_xml_shell "$1" "$2" "Certificate" ' format="pem"'
}

# 指定证书缓存位置
TempPath="./Temp.pem"
# 遍历指定目录下的所有 .xml 文件
find "$directory" -type f -name "*.xml" | while read -r xml_file; do
  echo "=============================="
  echo "信息: 正在处理文件：$xml_file"
  if [ ! -f "$xml_file" ]; then
    echo "❌❌❌错误: 您的文件 $xml_file 不存在"
    continue
  fi
  # 初始化标记
  error=0
  expired=0

  # 提取所有证书
  echo "信息: 提取所有证书..."
  # 初始化数组
  certificates=()
  serial_numbers=()
  # 循环提取前两个证书链
  for count in $(seq 1 2); do
    # 指定证书链名
    if [ $count -eq 1 ]; then
      certType="ec"
      keyindex="1"
    elif [ $count -eq 2 ]; then
      certType="rsa"
      keyindex="2"
    else
      echo "❌❌❌错误: 异常的证书链数"
    fi
    # 提取指定证书链到临时文件
    extract_certificate_custom_$xmlTool "$xml_file" "$count" "CertificateChain" "" "0" > "$TempPath.chain"
    
    # 循环证书个数
    for i in $(seq 1 $(grep -c "<Certificate format=\"pem\">" "$TempPath.chain")); do
      # 不输出尾换行，并调用函数提取指定证书到临时文件
      cert=$(extract_certificate_$xmlTool "$TempPath.chain" "$i")
      echo -n "$cert" > "$TempPath"
      # 检查是否是第一个证书
      if [ $i -eq 1 ]; then
        # 获取pem私钥
        extract_certificate_custom_$xmlTool "$xml_file" "$keyindex" "PrivateKey" ' format="pem"' > "$TempPath.key"
        # 验证私钥是否匹配
        certKeyCheck "$certType" "$TempPath" "$TempPath.key"
        if [ $? -ne 0 ]; then
          file_rename "Error_" "0"
          error=1
        else
          file_rename "Error_" "1"
        fi
        rm -f "$TempPath.key"
        echo -n "$cert" > "$TempPath.old"
      else
        openssl verify -partial_chain -CAfile "$TempPath" "$TempPath.old" >/dev/null 2>&1
        if [ $? -ne 0 ]; then
          echo "❌❌❌错误: 证书链验证失败"
          file_rename "Error_" "0"
          error=1
        else
          echo "信息: 证书链验证成功"
          file_rename "Error_" "1"
        fi
        # 输出证书链
        echo -n "$cert" > "$TempPath.old"
      fi
      # 获取证书序列号
      cert_sn="$(extract_serial_number "$TempPath")"
      # 将结果加到数组
      certificates+=("$TempPath")
      serial_numbers+=("$cert_sn")
      echo "信息: $certType证书 $i 序列号： $cert_sn"
      # 验证是否在有效期内
      check_certificate_validity "$TempPath"
      if [ $? -ne 0 ]; then
        file_rename "Expired_" "0"
        expired=1
      else
        file_rename "Expired_" "1"
      fi
    done
  done
  rm -f "$TempPath.old"

  # 检查变量是否为空
  if [ -z "${serial_numbers[0]}" ]; then
    echo "❌❌❌错误: 没有获取到序列号,跳过当前文件"
    continue
  fi

  # 指定吊销列表的url(json格式)
  revoke_list_url="https://android.googleapis.com/attestation/status"
  # 指定吊销列表缓存位置
  revokelistTempPath="./revoke_list.json"
  # 检查文件是否是指定时间内的
if [ -f "$revokelistTempPath" ] && [ $(( $(date +%s) - $(date -r "$revokelistTempPath" +%s) )) -lt 900 ]; then
  echo "信息: 吊销文件是15分钟内的,不再次下载"
else
  echo "信息: 吊销文件不是15分钟内的或不存在, 开始下载..."
  # 选择下载工具，获取吊销列表(只尝试一次，并且最大链接时间为3秒)
  if [[ "$download_type" == "wget" ]]; then
    wget --tries=1 --timeout=3 -O "$revokelistTempPath" "$revoke_list_url" &> /dev/null
  else
    curl --connect-timeout 3 --retry 0 --silent --output "$revokelistTempPath" "$revoke_list_url"
  fi

  # 检查下载是否成功
  if [ ! -f "$revokelistTempPath" ] && [ ! -s "$revokelistTempPath" ]; then
    rm -f "$revokelistTempPath"
    echo "❌❌❌错误: 下载吊销列表失败,请检查网络连接,文件权限等"
  else
    # 更新文件时间戳
    touch "$revokelistTempPath"
  fi
fi

  # 检查证书是否在吊销列表中(忽略大小写)
  revoked=0
  for cert_sn in "${serial_numbers[@]}"; do
    if cat "$revokelistTempPath" | grep -i "$cert_sn" > /dev/null; then
      echo "信息: 证书序列号 $cert_sn 已吊销!"
      revoked=1
      break
    fi
  done

  if [ $revoked -eq 1 ]; then
    echo "信息: 没有在吊销列表找到该序列号,您的证书是有效的"
    file_rename "Ban_" "0"
  else 
    file_rename "Ban_" "1"
  fi
  echo "=============================="
done
rm "$TempPath" "$TempPath.chain"
