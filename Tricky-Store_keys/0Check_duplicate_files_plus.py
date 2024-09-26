import os
import sys

def is_utf8(file_path):
    try:
        with open(file_path, 'rb') as file:
            file.read().decode('utf-8')
        return True
    except UnicodeDecodeError:
        return False

def normalize_text(text):
    return ' '.join(text.lower().split())

def file_key(filename):
    with open(filename, 'r', encoding='utf-8') as file:
        text = file.read()
        return normalize_text(text)

def find_duplicate_files(directory, search_subdirectories):
    files = {}
    duplicates = []

    for root, dirs, filenames in os.walk(directory):
        if not search_subdirectories:
            dirs[:] = []  # 清空目录列表，不遍历子目录
        for filename in filenames:
            filepath = os.path.join(root, filename)
            if os.path.isfile(filepath) and is_utf8(filepath):
                key = file_key(filepath)
                if key in files:
                    duplicates.append((files[key], filepath))
                else:
                    files[key] = filepath

    return duplicates

if __name__ == '__main__':
    # 检查命令行参数
    if len(sys.argv) == 2:
        directory = sys.argv[1]
        search_subdirectories = False
    elif len(sys.argv) == 3:
        directory = sys.argv[1]
        search_subdirectories = sys.argv[2].lower() == 'true'
    else:
        directory = input("请输入文件路径: ")
        search_subdirectories = input("是否搜索子目录? (true): ").lower() == 'true'

    # 检查目录是否存在
    if not os.path.isdir(directory):
        print("提供的路径不是一个有效的目录")
        sys.exit(1)

    duplicates = find_duplicate_files(directory, search_subdirectories)

    if duplicates:
        print("找到以下重复的文件对:")
        for dup in duplicates:
            print(f'{dup[0]} 和 {dup[1]}')
    else:
        print("没有找到重复的文件。")

    # 等待用户输入 'y' 以退出程序
    print("\n处理完成。按 'y' 退出程序：")
    exit_command = input().lower()
    if exit_command == 'y':
        print("程序已退出。")
        sys.exit()