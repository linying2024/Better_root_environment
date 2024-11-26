#!/bin/bash

# set -x
echo "Version: 0.3(2024234049)"
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
  get_cert="extract_certificate_xmlstarlet"
else
  echo "⚠⚠⚠警告: xmlstarlet 命令不可用,推荐使用 xmlstarlet 以减少错误"
  get_cert="extract_certificate"

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
  local serial_number="$2"
  xmlstarlet sel -t -v "(AndroidAttestation/Keybox/Key/CertificateChain/
  Certificate)[$serial_number]" "$xml_file"
}

# 提取指定序数的证书 shell方法
extract_certificate() {
  local file="$1"
  local serial_number="$2"

  # 获取所有 BEGIN CERTIFICATE 行的行号
  begin_lines=($(grep -n "<Certificate format=\"pem\">" "$file" | cut -d: -f1))
  # 计算 END CERTIFICATE 行的行号
  end_lines=($(grep -n "</Certificate>" "$file" | cut -d: -f1))

  if [ ${#begin_lines[@]} -lt $serial_number ]; then
    echo "错误: 指定的序列号超过了证书的数量"
    return 1
  fi

  # 获取指定序数的证书的开始和结束行号
  begin_line=${begin_lines[$((serial_number - 1))]}
  end_line=${end_lines[$((serial_number - 1))]}

  # 提取证书内容，并且去掉可能的头尾，和换行空格等
  cert_code="$(sed -n "${begin_line},${end_line}p" "$file" | sed -n '2,$p' | sed '$d' | sed 's/-----BEGIN CERTIFICATE-----//' | sed 's/-----END CERTIFICATE-----//' | tr -d ' \n\t\r')"
  # 重新写出文件
  echo "-----BEGIN CERTIFICATE-----
$cert_code
-----END CERTIFICATE-----"
}

# 遍历指定目录下的所有 .xml 文件
find "$directory" -type f -name "*.xml" | while read -r xml_file; do
  echo "=============================="
  echo "信息: 正在处理文件：$xml_file"
  if [ ! -f "$xml_file" ]; then
    echo "错误: 您的文件 $xml_file 不存在"
    continue
  fi

  # 指定证书缓存位置
  certTempPath="./certTemp.pem"
  # 提取第一个证书（EC）和第四个证书（RSA）
  echo "$($get_cert "$xml_file" "1")" > "$certTempPath"
  # 获取序列号
  ec_cert_sn="$(extract_serial_number "$certTempPath")"
  echo "$($get_cert "$xml_file" "4")"  > "$certTempPath"
  rsa_cert_sn="$(extract_serial_number "$certTempPath")"

  echo "信息: EC 证书序列号： $ec_cert_sn"
  echo "信息: RSA 证书序列号： $rsa_cert_sn"

  # 检查变量是否为空
  if [ -z $ec_cert_sn ] && [ -z $rsa_cert_sn ]; then
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
  if cat "$revokelistTempPath" | grep -i "$ec_cert_sn" > /dev/null || cat "$revokelistTempPath" | grep -i "$rsa_cert_sn" > /dev/null; then
    echo "信息: 您的 Keybox 已吊销!"
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
