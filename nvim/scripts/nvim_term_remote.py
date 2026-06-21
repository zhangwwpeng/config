#!/usr/bin/env python3
"""
子终端 -> 父 Neovim 的 RPC 桥接。

用法: nvim_term_remote.py <nvim_server> [path]
  nvim_server  父实例的 pipe/socket（如 $NVIM）
  path         可选，转为绝对路径后传给 :RemoteTrigger；省略则传 "null"
"""

import os
import sys
import subprocess


def main():
    if len(sys.argv) < 2 or not sys.argv[1]:
        print("[info] must have nvim pip")
        return
    nvim_server = sys.argv[1]

    if len(sys.argv) <= 2:
        abs_path = "null"
    else:
        abs_path = os.path.abspath(sys.argv[2])

    remote_send_payload = f"<Cmd>RemoteTrigger {abs_path}<CR>"
    cmd = [
        "nvim",
        "--server", nvim_server,
        "--remote-send", remote_send_payload,
    ]

    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"执行控制命令失败: {e}")

if __name__ == "__main__":
    main()
