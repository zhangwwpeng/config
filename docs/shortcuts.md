# 快捷键

`Leader` 是空格，`kitty_mod` 是左 `Option/Alt`。Neovim 模式缩写：`n` Normal、`i` Insert、`x/v` Visual、`t` Terminal、`c` Command-line。

## Karabiner 全局映射

### 基础映射

| 输入 | 输出 |
|---|---|
| `§`（international3） | `` ` `` / `~` |
| `英数`、`かな` | `Space` |
| `Caps Lock` | 左 `Shift + Option` |
| `Ctrl + K` | `Enter` |
| `Ctrl + H` | `Backspace` |

### Shift + Option

| 快捷键 | 功能 |
|---|---|
| `Shift + Option + O` | 切换 Kitty quick-access terminal，并先切英文输入法 |
| `Shift + Option + Q` | 新建 Kitty 窗口 |
| `Shift + Option + M` | yabai 聚焦最近使用的 Space |
| `Shift + Option + P/N` | yabai 聚焦上一个/下一个 Space |
| `Shift + Option + 1..9` | yabai 聚焦指定 Space |
| `Shift + Option + D` | 发送 `Cmd + Q` |

这些 shell command 固定使用 `/opt/homebrew/bin`，因此默认面向 Apple Silicon Homebrew。

## Kitty

| 快捷键 | 功能 |
|---|---|
| `Alt + ;` | 新建 window |
| `Alt + F` | 可视化选择并聚焦 window |
| `Alt + T` | 新建 tab |
| `Alt + Q` | 关闭 tab |
| `Alt + N/P` | 下一个/上一个 tab |
| `Alt + 1..9` | 跳到指定 tab |
| `Alt + Alt + R` | 设置 tab 标题 |
| `Alt + V` | 下一个布局 |
| `Alt + O` | 切换 stack 布局 |
| `Alt + W` | 选择可见单词并插入终端 |
| `Alt + M` | Kitty command palette |

## Neovim 主实例

### 文件、导航和窗口

| 快捷键 | 模式 | 功能 |
|---|---|---|
| `Ctrl + S` | `n/i/x/s` | 保存 |
| `Ctrl + Q` | `n/i/x/s` | 关闭当前 Neovim 窗口 |
| `Leader Leader` | `n` | Snacks 智能查找 |
| `Leader E` | `n` | Oil 打开父目录 |
| `Tab` | `n` | QuickBuf buffer 选择 |
| `Leader Q T` | `n` | 切换当前 buffer 固定状态 |
| `Shift + H/L` | `n` | 上一个/下一个固定 buffer |
| `S` / `Shift + S` | `n/x/o` | Flash / Flash Tree-sitter 跳转 |
| 方向键 | `n` | 调整当前窗口尺寸 |
| `Ctrl + F` | `n/v` | 切换专注 tab |
| `Ctrl + P` | `n` | 自定义 command panel |

### 编辑与代码

| 快捷键 | 模式 | 功能 |
|---|---|---|
| `Ctrl + /` | `n/x/i` | 注释/取消注释 |
| `Ctrl + L` | `n/i/v` | 关闭浮窗并格式化 |
| `Leader 0` | `n` | 显示当前行真实诊断 |
| `Tab` / `Shift + Tab` | `x` | 扩大/缩小 Tree-sitter 选区 |
| `Ctrl + ;` | `i/s` | 展开 snippet 或跳到下一占位 |
| `Ctrl + A/E` | `n/c/i` | 行首/行尾 |
| `Ctrl + F/B` | `i` | 右移/左移 |

自动配对在 Insert 和 Command-line 模式支持 `()`、`[]`、`{}`、双引号、单引号和反引号。Verilog/SystemVerilog 中单引号和反引号不会自动配对。空配对中：

- `Enter`：换行并缩进；
- `Space`：在配对内插入空格；
- `Backspace`：同时删除两端。

### 补全

Blink 使用 `preset = none`，只有下面这些显式键位：

| 快捷键 | 功能 |
|---|---|
| `Ctrl + P/N` | 上一个/下一个候选 |
| `Enter` | 选择并接受；无候选时回退为普通回车 |
| `Ctrl + E` | 隐藏菜单 |
| `Ctrl + U/D` | 上下滚动文档 |

配置没有为 `<C-y>`、`<C-Space>` 或 `<C-k>` 定义补全快捷键。

### RPC 终端

| 快捷键 | 模式 | 功能 |
|---|---|---|
| `Ctrl + T` | `n/i/t` | 切换浮动子 Neovim 终端 |
| `Ctrl + ,` | `n/i/t` | 打开/聚焦底部子终端 |
| `Leader T` | `n` | 隐藏/恢复子终端窗口 |

子实例 Terminal/Insert 模式：

| 快捷键 | 功能 |
|---|---|
| `Ctrl + W` 后接 `S/V` | 水平/垂直分窗 |
| `Ctrl + W` 后接 `H/J/K/L/W` | 窗口导航 |
| `Ctrl + W Q` | 关闭窗口 |
| `Ctrl + W R` | 旋转窗口 |
| `Ctrl + O` | 离开 Terminal 模式 |
| `Ctrl + 0` | 循环子终端位置 |

子实例 Normal 模式使用 `T/D/P/N/R` 新建、关闭、切换和重命名 tab。

### 输入法、Neovide 和 AI

| 快捷键 | 模式 | 功能 |
|---|---|---|
| `Ctrl + [` | `i/t` | 记录中文输入法、切英文并退出当前模式 |
| `Cmd + S` | Neovide `n` | 保存 |
| `Cmd + C` | Neovide `v` | 复制到系统剪贴板 |
| `Cmd + V` | Neovide 多模式 | 从系统剪贴板粘贴 |
| `Ctrl + +` / `Ctrl + -` | Neovide `n` | 放大/缩小界面 |
| `Leader A A` | `n` | 创建 AI chat session |
| `Leader S` | `n` | 选择并打开 AI chat session |
| `P` | AI chat buffer `n` | 提交当前内容 |
| `Ctrl + A` | AI chat buffer `n` | 轮换 DeepSeek/ChatGPT/Gemini |

## Glide

Glide 默认不管理 Space；先按 `Alt + Shift + E` 为当前 Space 启用。

| 快捷键 | 功能 |
|---|---|
| `Alt + Shift + E` | 切换当前 Space 是否受管理 |
| `Alt + Shift + H/J/K/L` | 向左/下/上/右移动焦点 |
| `Alt + H/J/K/L` | 向对应方向移动窗口节点 |
| `Alt + Shift + Z/X` | 向左/右调整 5% |
| `Alt + Shift + S` | 建立横向 group |
| `Alt + Shift + U` | 解除 group |
| `Alt + Shift + V` | 切换窗口浮动 |
| `Alt + Shift + F` | 切换全屏 |

## SketchyBar

- 点击 Space 项：调用 yabai 聚焦对应 Space。
- 电池图标按 0–29、30–59、60–89、90–100% 分级，交流电源时显示闪电。
- 飞书/企业微信都无角标时隐藏消息项；有消息时显示两者计数。
