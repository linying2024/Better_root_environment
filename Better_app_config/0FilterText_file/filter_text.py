#!/usr/bin/env python3

# 载入需要用到的模块
import os
import sys

# ANSI转义序列定义颜色
RED = "\033[91m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
RESET = "\033[0m"

# 定义一个过滤用的函数
def filter(source_list_path, exclusion_list_path):
    """
    函数功能描述: 过滤列表，排除掉排除名单里面的字符串
    :param source_list_path: 源列表文件的路径，其中包含需要过滤的字符串
    :param exclusion_list_path: 排除列表文件的路径，包含需要从源列表中排除的字符串
    :return: 过滤后的字符串列表
    :raises FileNotFoundError: 如果文件不存在
    :raises ValueError: 如果文件读取错误
    """
    # 检查排除列表文件是否存在或为空，如果不存在或为空，则打印警告信息
    if not os.path.exists(exclusion_list_path) or os.path.getsize(exclusion_list_path) == 0:
        print(f"{YELLOW}警告：要过滤掉的字符串列表文件 '{exclusion_list_path}' 不存在或为空{RESET}")
        exclusion_list = set()
    # 否则执行
    else:
        # 尝试
        try:
            # 打开排除列表文件，并读取其中的字符串(忽略空行，由#开头的注释行，以及空格行等字符串)
            with open(exclusion_list_path, 'r') as bl_file:
                exclusion_list = {line.strip() for line in bl_file if line.strip() and not line.strip().startswith('#')}
        # 尝试失败
        except Exception as e:
            # 如果读取排除列表文件时发生错误，打印错误信息并退出
            print(f"{RED}错误：读取排除列表文件 '{exclusion_list_path}' 时发生错误：{e}{RESET}")
            sys.exit(1)

    try:
        # 打开源列表文件读取
        with open(source_list_path, 'r') as app_file:
            apps = [line.strip() for line in app_file if line.strip() and not line.strip().startswith('#')]
            # 如果源列表文件过滤后为空，打印警告信息并退出
            if not apps:
                print(f"{YELLOW}警告：'{source_list_path}' 文件过滤后为空。{RESET}")
                sys.exit(1)
    except FileNotFoundError:
        # 如果源列表文件不存在，打印错误信息并退出
        print(f"{RED}错误：源列表文件 '{source_list_path}' 不存在。{RESET}")
        sys.exit(1)
    except Exception as e:
        # 如果读取源列表文件时发生错误，打印错误信息并退出
        print(f"{RED}错误：读取源列表文件 '{source_list_path}' 时发生错误：{e}{RESET}")
        sys.exit(1)

    # 过滤源列表，排除排除名单中的字符串
    filtered_apps = [app for app in apps if app not in exclusion_list and not app.isspace()]

    # 如果过滤后的源列表为空，打印警告信息
    if not filtered_apps:
        print(f"{YELLOW}警告：没有字符串被过滤掉{RESET}")

    # 打印过滤后的源列表
    for app in filtered_apps:
        print(app)

# 定义被非python方式直接调用的处理方式
if __name__ == "__main__":
    # 检查命令行参数的数量是否正确，参数不对则直接退出
    if len(sys.argv) != 3:
        print(f"{BLUE}用法: <filename> <source_list_path> <exclusion_list_path>{RESET}")
        sys.exit(1)

    # 获取源列表文件路径和排除列表文件路径
    source_list_path = sys.argv[1]
    exclusion_list_path = sys.argv[2]

    # 调用过滤函数
    filter(source_list_path, exclusion_list_path)