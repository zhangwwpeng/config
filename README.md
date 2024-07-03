# Config 配置

## 安装流程

1. 确保安装 just
2. 将 config 克隆在 .config 目录下面
3. 运行 just check 确认是否安装成功
4. 运行 just 将目录链接到相关目录

## Neovim 常用快捷键

| 快捷键 | 命令 | 备注 |
| -- | -- | -- |
| ctrl + h | 向左跳转窗口 | |
| ctrl + j | 向下跳转窗口 | |
| ctrl + k | 向上跳转窗口 | |
| ctrl + l | 向左跳转窗口 | |
| leader + e | 打开文件夹 | |
| leader + gg | 打开 Lazygit | |
| leader + yy | 打开 yazi  | |

## kitty or windows terminal

| 捷键 | 命令 | 备注 |
| -- | -- | -- |
| alt + o | 打开一个新的窗口 | 待实现 |
| alt + h | 向左跳转窗口 | 待实现 |
| alt + j | 向下跳转窗口 | 待实现 |
| alt + k | 向上跳转窗口 | 待实现 |
| alt + l | 向左跳转窗口 | 待实现 |

## 常用shell command

| 快捷键 | 命令 | 备注 |
| -- | -- | -- |
| yy | 打开 yazi | |
| nv | 打开 nvim | |
| gi | 打开 lazygit | |
| ff | 使用 fzf 和 find 搜索文件夹 | |
| fk | 使用 fzf 和 kill 杀死进程 | |
| cat | 使用 bat 替换 | |
| btm | 查看系统任务 | 待改进 |
| ctrl + r | 搜索历史命令 | |
| ctrl + f | 补全命令 | |

## Lazygit 常用快捷键

| 快捷键 | 命令 | 备注 |
| -- | -- | -- |
| U |  拉取下来 | 修改默认快捷键p -> U，避免与推送混淆 |
| P | 推送 |  |
| A | 全部提交到暂存区 | |
| Space | 单独选择文件 | |
| n | 新建branch | |
| e | 使用nvim打开文件 | |
| o | 使用code打开文件 | |

## todo

- [x] 傻瓜式一键安装
- [x] 终端快捷键适配修改
- [ ] 修改 riml-ls 快捷键补全问题
- [ ] 修改 Lazygit 快捷键问题
- [ ] 修改 主题配色 (长期)
- [ ] 添加 nvim 的 inset 模式下快捷键
- [ ] 修改 nvim 的 snip
- [ ] 改进 btm
