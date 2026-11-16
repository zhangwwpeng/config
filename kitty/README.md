# Kitty 配置速查

本文件整理实际生效的 Kitty 配置与快捷键。`kitty.conf` 为官方完整模板（含大量注释），生效配置集中在自定义片段中；全局键位联动关系见 [全局键位速查](../KEYMAPS.md)。

## 文件结构

| 文件 | 作用 |
| --- | --- |
| `kitty.conf` | 主配置与全部自定义快捷键绑定 |
| `themes/bamboo.conf` | 当前配色主题（在 `kitty.conf` 末尾 `include`） |
| `current-theme.conf` | 备用默认主题（当前未被 `include`） |
| `quick-access-terminal.conf` | 快速唤醒终端（`kitten quick_access_terminal`）独立配置 |
| `tab_bar.py` | `tab_bar_style custom` 时的自定义标签栏绘制脚本 |
| `tab_border_watcher.py` | 监听标签变化，仅在标签数 > 1 时显示分屏边框（`#6c6180`） |
| `tabbar-left.conf` | 左侧垂直标签栏覆盖配置（`kitty_mod+u` 加载） |
| `tabbar-bottom.conf` | 底部水平标签栏覆盖配置（`kitty_mod+y` 加载） |

## 生效中的基础设置

```conf
font_family                     Iosevka    # -calt -liga -dlig +NWID；中文 LXGW WenKai Mono；星标 Menlo
font_size                       26.0
enable_audio_bell               no
bell_on_tab                     ""
hide_window_decorations         titlebar-only
tab_bar_edge                    left
tab_bar_style                   custom     # 配合 tab_bar.py
kitty_mod                       alt+shift  # 配合 Karabiner：Caps Lock = Left Shift + Left Option
window_border_width             1pt
draw_minimal_borders            no
draw_window_borders_for_single_window yes
active_border_color             #232922
inactive_border_color           #232922
watcher                         ~/.config/kitty/tab_border_watcher.py
include                         themes/bamboo.conf
```

## 关于 `kitty_mod` 与 Karabiner

- 本配置将 `kitty_mod` 设为 `alt+shift`（macOS 上为 `Option + Shift`）。
- 由于 [Karabiner](../karabiner/karabiner.json) 将 **`Caps Lock` 映射为 `Left Shift + Left Option`**，日常按 **`Caps + 键`** 即等价于 `kitty_mod + 键`。
- 部分绑定带有 `--allow-fallback=shifted,ascii`，用于规避不同键盘布局或输入法下 Option 组合键产出字符差异的问题。
- Karabiner 对部分 `Left Shift + Left Option + 键` 做了全局拦截（如 `Caps+[`、`Caps+n`、`Caps+p`、`Caps+m`），这些按键若需触发 Kitty 原生动作，请改按 **右 `Option + Shift + 键`** 或表中的替代键。

---

## 一、自定义 / 改动的绑定

| 按键 | 日常按法 | 动作 | 说明 / 被覆盖的默认键 |
| --- | --- | --- | --- |
| `ctrl+enter` | `Ctrl+Enter` | `new_tab` | 新建标签（`Caps+t`、`Cmd+t` 仍可用） |
| `kitty_mod+h` | `Caps+h` | `previous_tab` | 上一个标签（覆盖 `show_scrollback`；`Ctrl+Shift+Tab` 仍可用） |
| `kitty_mod+l` | `Caps+l` | `next_tab` | 下一个标签（覆盖 `next_layout`；`Ctrl+Tab` 仍可用） |
| `kitty_mod+1..9` | `Caps+1..9` | `goto_tab 1..9` | 跳到第 1–9 个标签（覆盖切分屏窗口；切分屏改用 `Cmd+1..9`） |
| `kitty_mod+r` | `Caps+r` | `set_tab_title` | 重命名当前标签（覆盖 `start_resizing_window`；`Shift+Cmd+i` 仍可用） |
| `kitty_mod+u` | `Caps+u` | 加载 `tabbar-left.conf` | 切换为左侧垂直标签栏（覆盖 `unicode_input`；可用 `Ctrl+Cmd+Space`） |
| `kitty_mod+y` | `Caps+y` | 加载 `tabbar-bottom.conf` | 切换为底部水平标签栏 |
| `kitty_mod+b` | `Caps+b` | `next_layout` | 切换到下一个布局（覆盖 `move_window_backward`） |
| `kitty_mod+j` | `Caps+j` | `kitten hints --type word --program -` | 提示选词并直接输入终端（覆盖 `scroll_line_down`） |
| `kitty_mod+k` | `Caps+k` | `command_palette` | 打开命令面板（覆盖 `scroll_line_up`；`Caps+F3` 仍可用） |
| `kitty_mod+f` | `Caps+f` | `focus_visible_window` | 可视化聚焦分屏窗口（覆盖 `move_window_forward`；`Caps+F7` 仍可用） |

> 取消某条自定义映射只需注释 `kitty.conf` 对应行后按 `Caps+F5` 重载；按 `Caps+F6`（`debug_config`）可查看 Kitty 最终合并后的完整键位。

## 二、常用内置绑定（已按 `kitty_mod = alt+shift` 与 Karabiner 冲突校正）

### 窗口（Splits）

| 按键 | 动作 | 备注 |
| --- | --- | --- |
| `Caps+;` / `Caps+Enter` / `Cmd+Enter` | 新建分屏窗口 | — |
| `Caps+w` / `Shift+Cmd+d` | 关闭当前分屏窗口 | — |
| `Caps+]` / 右 `Opt+Shift+[` | 下一个 / 上一个分屏窗口 | `Caps+[` 被 Karabiner 拦为呼出快速终端 |
| `Cmd+1..9` / `Caps+0` | 跳到第 1–9 / 第 10 个分屏窗口 | `Caps+1..9` 已改为跳标签 |
| `Caps+f` / `Caps+F7` | 可视化选择并聚焦窗口 | — |
| `Caps+F8` | 可视化交换窗口位置 | — |
| ``Caps+` `` | 将当前窗口移到最顶层 | — |

### 标签（Tabs）

| 按键 | 动作 | 备注 |
| --- | --- | --- |
| `Ctrl+Enter` / `Caps+t` / `Cmd+t` | 新建标签 | — |
| `Caps+q` / `Cmd+w` | 关闭当前标签 | — |
| `Caps+h` / `Caps+l` | 上一个 / 下一个标签 | 也可 `Ctrl+Shift+Tab` / `Ctrl+Tab` / `Caps+←` / `Caps+→` |
| `Caps+1..9` | 跳到第 1–9 个标签 | — |
| `Caps+r` / `Shift+Cmd+i` | 重命名标签 | — |
| `Caps+.` / `Caps+,` | 标签前移 / 后移 | — |
| `Shift+Cmd+w` | 关闭整个 OS 窗口 | — |

### 布局（Layouts）

| 按键 | 动作 | 备注 |
| --- | --- | --- |
| `Caps+b` | 下一个布局 | — |
| `Caps+o` | 切换 `stack` 布局（临时放大当前窗口） | — |

### 滚动与回看（Scrollback）

| 按键 | 动作 | 备注 |
| --- | --- | --- |
| `Caps+↑` / `Cmd+↑` | 向上滚动一行（smooth） | — |
| `Caps+↓` / `Cmd+↓` | 向下滚动一行（smooth） | — |
| `Caps+PageUp` / `Caps+PageDown` | 上翻 / 下翻一页（亦可用 `Cmd+PageUp/PageDown`） | — |
| `Caps+Home` / `Caps+End` | 滚到顶部 / 底部（亦可用 `Cmd+Home/End`） | — |
| `Caps+z` / `Caps+x` | 跳到上一条 / 下一条 shell prompt | — |
| `Caps+g` | 在分页器查看上一条命令输出 | `Caps+h`（原 `show_scrollback`）已改绑上一个标签 |
| `Caps+/` / `Cmd+f` | 在 scrollback 中搜索 | — |

### 剪贴板与 Hints

| 按键 | 动作 | 备注 |
| --- | --- | --- |
| `Caps+c` | 复制到系统剪贴板 | — |
| `Caps+v` / `Cmd+v` | 从系统剪贴板粘贴 | — |
| `Caps+s` / `Shift+Insert` | 粘贴选择区（selection） | — |
| `Caps+j` | hints 选词并直接输入终端 | — |
| `Caps+e` | hints 打开可见 URL | — |
| 右 `Opt+Shift+p` 后接 `f`/`F`/`l`/`h`/`n`/`y`/`c`/`d` | hints 选路径/行/hash/行号/超链接/文件/目录 | `Caps+p` 被 Karabiner 拦为切上一 Space |

### 字体、透明度、清屏与调试

| 按键 | 动作 | 备注 |
| --- | --- | --- |
| `Caps+=` / `Caps++` / `Cmd++` / `Cmd+=` | 字体放大 2.0 | — |
| `Caps+-` / `Cmd+-` | 字体缩小 2.0 | — |
| `Caps+Backspace` / `Cmd+0` | 字体大小恢复默认 | — |
| `Caps+a>m` / `Caps+a>l` / `Caps+a>1` / `Caps+a>d` | 背景不透明度 +0.1 / -0.1 / 设为 1 / 恢复默认 | — |
| `Caps+Delete` | 重置清屏（含 scrollback） | — |
| `Cmd+Ctrl+l` / `Cmd+k` / `Cmd+l` / `Opt+Cmd+k` | 清到光标(+scrollback) / 清到光标 / 清上一条命令 / 清 scrollback | — |
| `Caps+F2` / `Cmd+,` | 编辑 `kitty.conf` | — |
| `Caps+F5` / `Ctrl+Cmd+,` | 重载配置 | — |
| `Caps+F6` / `Opt+Cmd+,` | 打印最终生效配置（含完整键位表） | — |
| `Caps+k` / `Caps+F3` | 打开命令面板 | — |
| `Caps+F1` / `Caps+Esc` / `Ctrl+Cmd+Space` | Kitty 文档 / kitty shell / Unicode 输入 | — |

### OS 级与全局联动

| 按键 | 触发源 | 动作 |
| --- | --- | --- |
| `Caps+[` | Karabiner | 切至英文输入法并在 `~` 呼出 `kitten quick_access_terminal`（`quick-access-terminal.conf`） |
| `Cmd+n` | Kitty | 新建 OS 窗口（`Caps+n` 被 Karabiner 拦为下一 Space） |
| ``Cmd+` `` / ``Cmd+Shift+` `` | Kitty | 在 Kitty 的 OS 窗口间正/反向循环 |
| `Caps+F11` / `Ctrl+Cmd+f` / `Caps+F10` | Kitty | 全屏 / 最大化 |
| `Cmd+h` / `Opt+Cmd+h` / `Cmd+m` / `Cmd+q` | Kitty | 隐藏 Kitty / 隐藏其他应用 / 最小化 / 退出 |

---

## 三、Karabiner 拦截冲突速查

| 被拦截组合 | Kitty 默认功能 | 实际被 Karabiner 拦截后的行为 | 替代按法 |
| --- | --- | --- | --- |
| `Caps+[` | `previous_window` | 呼出 `quick-access-terminal` | 右 `Opt+Shift+[` 或 `Caps+f` 聚焦分屏 |
| `Caps+p` | `kitty_mod+p>*` hints/选文件前缀 | 切换到上一个桌面 Space（`Ctrl+←`） | 右 `Opt+Shift+p` 后接子键 |
| `Caps+n` | `new_os_window` | 切换到下一个桌面 Space（`Ctrl+→`） | `Cmd+n` |
| `Caps+m` | 无 | 触发应用切换器（`Cmd+Tab`） | — |
