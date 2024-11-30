#!/bin/bash

# set -x
echo "Version: 0.6(20241130131209)"
echo "Tip: MT管理器请使用终端扩展包执行"

# 指定目录
directory=${1:-./}

# 命令检查
check_command() {
  local command="$1"
  # 检查命令可执行性
  if ! command -v "$command" &> /dev/null; then
    echo "错误: $command 命令不存在"
    return 127
  fi
}
# 检查 xmlstarlet openssl wget curl 是否安装
if check_command "xmlstarlet"; then
  xmlTool="xmlstarlet"
else
  echo "⚠⚠⚠警告: xmlstarlet 命令不可用,推荐使用 xmlstarlet 以减少错误"
  xmlTool="shell"

  if ! check_command "tr"; then
    echo "错误: 没有 tr 工具,脚本无法继续执行"
    exit 127
  fi
fi
if ! check_command "openssl"; then
  echo "错误: 没有 openssl 证书工具,脚本无法继续执行"
  exit 127
fi
if check_command "wget"; then
  download_type="wget"
else
  echo "⚠⚠⚠警告: wget 命令不可用"
  if ! check_command "curl"; then
    echo "错误: 没有可用的下载工具,脚本无法继续执行"
    echo "您可以安装 wget 或者 curl 命令工具重试"
    exit 127
  fi
fi

# 函数用于提取证书序列号
extract_serial_number() {
  local cert_pem=$1
  echo "$(openssl x509 -inform PEM -noout -serial -in $cert_pem | cut -d'=' -f2)"
}

# 提取指定证书 xmlstarlet方法
extract_certificate_xmlstarlet() {
  local xml_file="$1"
  local index="$2"
  xmlstarlet sel -t -v "(AndroidAttestation/Keybox/Key/CertificateChain/
  Certificate)[$index]" "$xml_file"
}

# 提取指定序数的证书 shell方法
extract_certificate_shell() {
  local file="$1"
  local index="$2"

  # 获取所有 BEGIN CERTIFICATE 行的行号
  begin_lines=($(grep -n "<Certificate format=\"pem\">" "$file" | cut -d: -f1))
  # 计算 END CERTIFICATE 行的行号
  end_lines=($(grep -n "</Certificate>" "$file" | cut -d: -f1))

  if [ ${#begin_lines[@]} -lt $index ]; then
    echo "错误: 指定的序列号超过了证书的数量"
    return 1
  fi

  # 获取指定序数的证书的开始和结束行号
  begin_line=${begin_lines[$((index - 1))]}
  end_line=${end_lines[$((index - 1))]}

  # 提取证书内容，并且去掉可能的头尾，和换行空格等
  cert_code="$(sed -n "${begin_line},${end_line}p" "$file" | sed -n '2,$p' | sed '$d' | sed 's/-----BEGIN CERTIFICATE-----//' | sed 's/-----END CERTIFICATE-----//' | tr -d ' \n\t\r')"
  # 重新写出文件
  echo "-----BEGIN CERTIFICATE-----
$cert_code
-----END CERTIFICATE-----"
}

# 定义一个函数来提取指定项 xmlstarlet方法
extract_certificate_custom_xmlstarlet() {
  local index="$1"
  local file="$2"
  local keyName="$3"
  # 提取字符串
  xmlstarlet sel -t -c "(AndroidAttestation/Keybox/Key/$keyName)[$index]" "$file"
}

# 定义一个函数来提取指定项 shell方法
extract_certificate_custom_shell() {
  local index="$1"
  local file="$2"
  local keyName="$3"
  # 提取字符串
  cat $file | awk "
    /<${keyName}>/ {if (++count == ${index}) flag=1}
    {if (flag) print}
    /<\/${keyName}>/ {if (flag && count == ${index}) flag=0}
  " | sed "1s/^.*<${keyName}>//; \$s/<\/${keyName}>.*$//"
}

# 指定证书缓存位置
TempPath="./Temp.pem"

# 遍历指定目录下的所有 .xml 文件
find "$directory" -type f -name "*.xml" | while read -r xml_file; do
  echo "=============================="
  echo "信息: 正在处理文件：$xml_file"
  if [ ! -f "$xml_file" ]; then
    echo "错误: 您的文件 $xml_file 不存在"
    continue
  fi

  # 提取所有证书
  echo "信息: 提取所有证书..."
  certificates=()
  serial_numbers=()
# 循环提取前两个证书链
for i in $(seq 1 2); do
  if [ $i -eq 1 ]; then
    certType="EC"
  elif [ $i -eq 2 ]; then
    certType="RSA"
  else
    echo "错误: 异常的证书链数"
  fi
  extract_certificate_custom_$xmlTool "$i" "$xml_file" "CertificateChain" > "$TempPath.chain"

  for i in $(seq 1 $(grep -c "<Certificate format=\"pem\">" "$TempPath.chain")); do
    echo "$(extract_certificate_$xmlTool "$TempPath.chain" "$i")" > "$TempPath"
    cert_sn="$(extract_serial_number "$TempPath")"
    certificates+=("$TempPath")
    serial_numbers+=("$cert_sn")
    echo "信息: $certType证书 $i 序列号： $cert_sn"
  done
done

  # 检查变量是否为空
  if [ -z "${serial_numbers[0]}" ]; then
    echo "错误: 没有获取到序列号,跳过当前文件"
    continue
  fi

  # 指定吊销列表的url(json格式)
  revoke_list_url="https://android.googleapis.com/attestation/status"

  # 指定吊销列表缓存位置
  revokelistTempPath="./revoke_list.json"
  # 检查文件是否是5分钟内的
  if [ -f "$revokelistTempPath" ] && [ "$(($(date -r "$revokelistTempPath" +%s) + 300))" -lt "$(date +%s)" ]; then
    echo "信息: 吊销文件是5分钟内的,不再次下载"
  else
    # 选择下载工具，获取吊销列表(只尝试一次，并且最大链接时间为3秒)
    if [[ "$download_type" == "wget" ]]; then
      wget --tries=1 --timeout=3 -O "$revokelistTempPath" "$revoke_list_url" &> /dev/null
    else
      curl --connect-timeout 3 --retry 0 --silent --output "$revokelistTempPath" "$revoke_list_url"
    fi
    if [ ! -f "$revokelistTempPath" ]; then
      echo "错误: 下载吊销列表失败,请检查网络连接,文件权限等"
      continue
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
    base_name=$(basename "$xml_file")
    if [[ $base_name == Ban_* ]]; then
      # 如果文件名已经有Ban_前缀，则不添加
      echo "信息: 文件：$xml_file 已有 Ban_ 前缀"
    else
      # 添加Ban_前缀
      new_file_name="Ban_$(basename "$xml_file")"
      new_file_path="$(dirname "$xml_file")/$new_file_name"
      mv "$xml_file" "$new_file_path"
      echo "信息: 文件重命名：$xml_file -> $new_file_path"
    fi
  else
    echo "信息: 没有在吊销列表找到该序列号,您的证书是有效的"
    base_name=$(basename "$xml_file")
    if [[ $base_name == Ban_* ]]; then
      echo "警告: 发现错误的 Ban_ 标记"
      # 如果证书有效但文件名错误地包含Ban_前缀，则移除
      new_file_name="${base_name:4}"
      new_file_path="$(dirname "$xml_file")/$new_file_name"
      mv "$xml_file" "$new_file_path"
      echo "信息: 文件重命名：$xml_file -> $new_file_path"
    fi
  fi
  echo "=============================="
done
rm "$TempPath" "$TempPath.chain"
