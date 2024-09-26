#!/bin/bash

check_certificates() {
    local file_path="$1"
    local crl=$(curl -s 'https://android.googleapis.com/attestation/status' -H 'Cache-Control: max-age=0')
    local ec_cert_sn=$(grep -A 3 "BEGIN CERTIFICATE" "$file_path" | grep -A 1 "EC CERT" | tail -n 1 | od -An -vtu1 | awk '{print $1}')
    local rsa_cert_sn=$(grep -A 3 "BEGIN CERTIFICATE" "$file_path" | grep -A 1 "RSA CERT" | tail -n 1 | od -An -vtu1 | awk '{print $1}')

    echo "EC 证书序列号： $ec_cert_sn"
    echo "RSA 证书序列号： $rsa_cert_sn"

    if echo "$crl" | grep -q "$ec_cert_sn" || echo "$crl" | grep -q "$rsa_cert_sn"; then
        echo 'Keybox 已吊销！'
        local new_file_name="Ban_$(basename "$file_path")"
        local new_file_path="$(dirname "$file_path")/$new_file_name"
        mv "$file_path" "$new_file_path"
        echo "文件重命名：$file_path -> $new_file_path"
    else
        echo 'Keybox 仍然有效！'
        local base_name=$(basename "$file_path")
        if [[ $base_name == Ban_* ]]; then
            local new_file_name="${base_name:4}"
            local new_file_path="$(dirname "$file_path")/$new_file_name"
            mv "$file_path" "$new_file_path"
            echo "文件重命名：$file_path -> $new_file_path"
        fi
    fi
}

check_certificates_in_folder() {
    local folder_path="$1"
    for file in "$folder_path"/*.xml; do
        echo "=============================="
        echo "正在处理文件：$file"
        check_certificates "$file"
    done
}

# 主程序
if [ "$#" -ne 1 ]; then
    echo "用法: $0 <文件或文件夹路径>"
    read -p "请输入文件或文件夹的路径: " input_path
else
    input_path="$1"
fi

if [ -d "$input_path" ]; then
    check_certificates_in_folder "$input_path"
else
    check_certificates "$input_path"
fi

read -p "\n处理完成。按 'y' 退出程序: " exit_command
if [[ "$exit_command" == "y" ]]; then
    echo "程序已退出。"
    exit
fi