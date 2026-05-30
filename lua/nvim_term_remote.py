#!/usr/bin/env python3
import os
import sys
import subprocess

def main():
    # 1. 获取当前传入的所有参数（等同于 shell 的 $@）
    # sys.argv[0] 是脚本自己，sys.argv[1:] 才是用户传的文件名

    if not sys.argv[1]:
        print("[info] must have nvim pip")
        return
    nvim_server = sys.argv[1]

    # 3. 循环遍历所有参数，并自动拼上当前 pwd 的绝对路径
    if len(sys.argv) <= 2  :
        abs_path = "null"
    else:
        abs_path = os.path.abspath(sys.argv[2])

    # 4. 组装控制 nvim 的命令
    # nvim --server <pipe> --remote <file1> <file2> ...
    remote_send_payload = f"<Cmd>RemoteTrigger {abs_path}<CR>"

    cmd = [
        "nvim",
        "--server", nvim_server,
        "--remote-send", remote_send_payload
    ]

    # 5. 执行命令并把结果投送给父 nvim
    try:
        # subprocess.run 传入列表形式，完美原生免去任何引号转义的痛苦
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"执行控制命令失败: {e}")

if __name__ == "__main__":
    main()
