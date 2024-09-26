import requests
import sys
import os
import xml.etree.ElementTree as ET
from cryptography import x509

def check_certificates_in_folder(folder_path):
    for root, dirs, files in os.walk(folder_path):
        for file in files:
            if file.endswith('.xml'):
                file_path = os.path.join(root, file)
                print('\n==============================')
                print(f"正在处理文件：{file_path}")  # 打印当前处理的文件
                check_certificates(file_path)

def check_certificates(file_path):
    try:
        crl = requests.get('https://android.googleapis.com/attestation/status', headers={'Cache-Control': 'max-age=0'}).json()

        certs = [elem.text for elem in ET.parse(file_path).getroot().iter() if elem.tag == 'Certificate']

        def parse_cert(cert):
            cert = "\n".join(line.strip() for line in cert.strip().split("\n"))
            parsed = x509.load_pem_x509_certificate(cert.encode())
            return f'{parsed.serial_number:x}'

        ec_cert_sn, rsa_cert_sn = parse_cert(certs[0]), parse_cert(certs[3])

        print(f'\nEC 证书序列号： {ec_cert_sn}\nRSA 证书序列号： {rsa_cert_sn}')

        if any(sn in crl["entries"].keys() for sn in (ec_cert_sn, rsa_cert_sn)):
            print('Keybox 已吊销！\n')
            new_file_name = "Ban_" + os.path.basename(file_path)
            new_file_path = os.path.join(os.path.dirname(file_path), new_file_name)
            os.rename(file_path, new_file_path)
            print(f"文件重命名：{file_path} -> {new_file_path}")
        else:
            print('Keybox 仍然有效！\n')
            if os.path.basename(file_path).startswith("Ban_"):
                new_file_name = os.path.basename(file_path)[4:]
                new_file_path = os.path.join(os.path.dirname(file_path), new_file_name)
                os.rename(file_path, new_file_path)
                print(f"文件重命名：{file_path} -> {new_file_path}")
    except Exception as e:
        print(f'处理文件 {file_path} 时出错: {e}')

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("用法: [filename].py <文件或文件夹路径> \n请输入文件或文件夹的路径:")
        input_path = input()  # 等待用户输入
    else:
        input_path = sys.argv[1]
    
    if os.path.isdir(input_path):
        check_certificates_in_folder(input_path)
    else:
        check_certificates(input_path)

    # 等待用户输入 'y' 以退出程序
    print("\n处理完成。按 'y' 退出程序：")
    exit_command = input().lower()
    if exit_command == 'y':
        print("程序已退出。")
        sys.exit()