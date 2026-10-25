# kitty 配置速查

本目录下的 kitty 配置说明，重点整理**实际生效的快捷键**。
`kitty.conf` 是官方模板（大部分内容是中文注释文档），真正生效的配置只有寥寥几行，
所以看代码很难弄清键位，用这份 README 查更快。

## 文件结构

| 文件 | 作用 |
| --- | --- |
| `kitty.conf` | 主配置。除少量生效行外都是模板注释 |
| `themes/bamboo.conf` | 配色主题，在 `kitty.conf` 最后用 `include` 引入 |
| `current-theme.conf` | 默认主题（全用 kitty 内置值），当前**没有**被 include，留作还原用 |
| `quick-access-terminal.conf` | 快速唤醒终端（`kitten quick_access_terminal`）的独立配置，不影响主窗口 |
| `tab_bar.py` | `tab_bar_style custom` 时绘制标签栏的 Python 脚本 |

## 生效中的基础设置

```conf
font_family            Maple Mono Normal NF CN
font_size              18.0
enable_audio_bell      no
hide_window_decorations titlebar-only
tab_bar_style          custom          # 配合 tab_bar.py
kitty_mod              alt             # ← 下文所有 kitty_mod 都是 Option/Alt
include                themes/bamboo.conf
```

## 关于 `kitty_mod` 与 `--allow-fallback`

- `kitty_mod = alt`，在 macOS 上就是 **Option**。
- 不少绑定写成 `map --allow-fallback=shifted,ascii ...`：
  它允许「同时按住 Shift 得到的字符」或「ASCII 变体」也触发同一个动作，
  规避 Option 组合键在不同键盘布局/输入法下产生不同字符的问题。
- `<键>><键>` 形式表示**前缀键**：例如 `kitty_mod+p>f` 是先按 `alt+p`，松开，再按 `f`。

---

## 一、自定义 / 改动过的绑定

这些是相对 kitty 默认值有变化的部分（`kitty_mod` → `Option`）：

| 按键 | 动作 | 说明 / 被顶掉的默认键 |
| --- | --- | --- |
| `alt+;` | 新建窗口 | 默认新建窗口是 `alt+enter`，**仍然可用** |
| `alt+t` | 新建标签 | 与默认一致 |
| `alt+q` | 关闭标签 | 与默认一致 |
| `alt+n` | 下一个标签 | 顶掉默认 `alt+n`（新开 OS 窗口，改用 `cmd+n`）；默认的 `alt+→`、`ctrl+tab` 仍可用 |
| `alt+p` | 上一个标签 | 默认 `alt+p` 原本没绑定；`alt+←`、`ctrl+shift+tab` 仍可用 |
| `alt+1` … `alt+9` | 跳到第 N 个标签 | 顶掉默认 `alt+1..9`（切到第 N 个**窗口**，改用 `cmd+1..9`） |
| `alt+option+r` | 设置标签标题 | 默认是 `alt+option+t` / `shift+cmd+i` |
| `alt+v` | 下一个布局 | ⚠️ 顶掉默认 `alt+v`（**粘贴**）→ 粘贴请用 `cmd+v` |
| `alt+o` | 在 stack 布局间来回切换（临时放大当前窗口） | ⚠️ 顶掉默认 `alt+o`（把选中内容交给外部程序） |
| `alt+f` | 可视化选择并聚焦窗口（按提示字符跳转） | 顶掉默认 `alt+f`（窗口前移）；默认的 `alt+f7` 仍可用 |
| `alt+w` | 插入光标处/选中的**单词**（`kitten hints --type word --program -`） | ⚠️ 顶掉默认 `alt+w`（**关闭窗口**）→ 用 `shift+cmd+d` 关窗口，`alt+q` 关标签 |
| `alt+m` | 命令面板（command palette） | 默认 `alt+f3` 仍可用 |

> 想恢复某个默认键，只要删掉/注释掉 `kitty.conf` 里对应的那一行 `map ...`，然后 `alt+f5` 重载。
> 想看**最终生效**的完整键位表，按 `alt+f6`（debug_config）打开 kitty 自己打印的合并后配置。

## 二、窗口（splits）

| 按键 | 动作 |
| --- | --- |
| `alt+;` | 新建窗口（**自定义**；`alt+enter` 也可） |
| `shift+cmd+d` | 关闭窗口（`alt+w` 已被 hints 占用） |
| `alt+]` / `alt+[` | 下一个 / 上一个窗口 |
| `alt+1..9` ⚠️ | 已改为「跳到第 N 个标签」，窗口请用 `cmd+1..9` |
| `alt+0` | 第十个窗口 |
| `alt+f8` | 可视化交换窗口 |
| `alt+f7` / `alt+f` | 可视化聚焦窗口 |
| `alt+r` | 开始调整窗口大小（方向键调整，`esc` 结束） |
| `` alt+` `` | 把当前窗口移到最顶层 |
| `alt+b` | 当前窗口后移（默认仍在；`alt+f` 的「窗口前移」被聚焦窗口占用） |

## 三、标签（tabs）

| 按键 | 动作 |
| --- | --- |
| `alt+t` | 新建标签 |
| `alt+q` | 关闭标签 |
| `alt+n` / `alt+p` | 下一个 / 上一个标签（也可 `ctrl+tab` / `ctrl+shift+tab` / `alt+→` / `alt+←`） |
| `alt+1..9` | 跳到第 1–9 个标签 |
| `alt+option+r` | 重命名标签 |
| `alt+.` / `alt+,` | 标签前移 / 后移 |
| `shift+cmd+w` | 关闭整个 OS 窗口 |

## 四、布局（layouts）

| 按键 | 动作 |
| --- | --- |
| `alt+v` | 下一个布局（⚠️ 原 `alt+v` = 粘贴，现用 `cmd+v`；默认的 `alt+l` 仍可用） |
| `alt+o` | 在 stack 布局之间来回切换（临时放大当前窗口） |

## 五、滚动与回看

| 按键 | 动作 |
| --- | --- |
| `alt+↑` / `alt+k` / `cmd+↑` | 向上滚一行（smooth） |
| `alt+↓` / `alt+j` / `cmd+↓` | 向下滚一行（smooth） |
| `alt+page_up` / `alt+page_down` | 上翻 / 下翻一页 |
| `alt+home` / `alt+end` | 滚到顶部 / 底部 |
| `alt+z` / `alt+x` | 跳到上一条 / 下一条 shell prompt |
| `alt+h` | 在分页器里查看全部 scrollback |
| `alt+g` | 查看上一条命令的输出 |
| `alt+/` | 在 scrollback 里搜索 |

## 六、剪贴板 / 选择

| 按键 | 动作 |
| --- | --- |
| `alt+c` | 复制到系统剪贴板 |
| `cmd+v` | 从系统剪贴板粘贴（`alt+v` 已被布局占用） |
| `alt+s` / `shift+insert` | 粘贴「选择区」内容 |
| `alt+w` | 插入光标下单词（hints，选中内容后直接输入进终端） |
| `alt+e` | 用 hints 打开可见 URL |
| `alt+p>f` | hints 选择**路径**并插入 |
| `alt+p>shift+f` | hints 选路径并**打印** |
| `alt+p>l` / `alt+p>n` / `alt+p>h` / `alt+p>y` | 行号 / 纯行 / hash / 超链接 |
| `alt+p>c` / `alt+p>d` | 选文件 / 选目录 |
| 鼠标中键 | 粘贴选择区 |
| `ctrl+shift+left click` | 打开链接 |
| `shift+click` / 右键拖动 | 扩展选择 |
| `ctrl+alt+left drag` | 矩形（块）选择 |
| 双击 / 三击 | 选词 / 选行 |

## 七、字体、透明度、清屏

| 按键 | 动作 |
| --- | --- |
| `alt+=` / `alt++` / `alt+kp_add` | 字体放大 2.0 |
| `alt+-` / `alt+kp_subtract` | 字体缩小 2.0 |
| `alt+backspace` | 字体恢复默认 |
| `alt+a>m` / `alt+a>l` | 背景不透明度 +0.1 / −0.1 |
| `alt+a>1` / `alt+a>d` | 不透明度设为 1 / 恢复默认 |
| `alt+delete` | 清屏 + 清 scrollback |
| `cmd+ctrl+l` / `cmd+k` / `cmd+l` | 清到光标处（+scrollback）/ 清到光标 / 清上一条命令 |

## 八、配置与调试（最常用）

| 按键 | 动作 |
| --- | --- |
| `alt+f2` / `cmd+,` | 打开编辑 `kitty.conf` |
| `alt+f5` / `ctrl+cmd+,` | 重载配置 |
| `alt+f6` / `opt+cmd+,` | **打印最终生效配置**（含所有 map，排查键位就看它） |
| `alt+m` | 命令面板（可搜索所有动作并执行，默认 `alt+f3` 也可） |
| `alt+f1` | 打开 kitty 文档速查 |
| `alt+escape` | 打开 kitty shell（用 Python 操作 kitty） |
| `alt+u` | Unicode 输入（粘贴不常见字符） |

## 九、OS 级 / 全屏

| 按键 | 动作 |
| --- | --- |
| `alt+f11` / `ctrl+cmd+f` | 全屏 |
| `alt+f10` | 最大化 |
| `cmd+n` | 新开一个 OS 窗口（`alt+n` 已被标签占用） |
| `cmd+enter` | 新窗口（等价 `alt+;`） |
| `cmd+`` ` `` / `cmd+shift+`` ` `` | 在 OS 窗口之间循环 |
| `cmd+h` / `opt+cmd+h` | 隐藏 kitty / 隐藏其它 App |
| `cmd+m` / `cmd+q` | 最小化 / 退出 |

---

## 冲突速查（默认键被顶掉了什么）

| 键 | kitty 默认动作 | 现在是什么 | 替代方案 |
| --- | --- | --- | --- |
| `alt+v` | 粘贴 | 下一个布局 | `cmd+v` |
| `alt+w` | 关闭窗口 | hints 插入单词 | `shift+cmd+d` |
| `alt+o` | 选中内容交外部程序 | stack 布局切换 | 无 |
| `alt+n` | 新 OS 窗口 | 下一个标签 | `cmd+n` |
| `alt+1..9` | 切到第 N 个窗口 | 跳到第 N 个标签 | `cmd+1..9` |
| `alt+f` | 窗口前移 | 可视化聚焦窗口 | 无 |

## 改键小抄

`kitty.conf` 里加一行，然后 `alt+f5`：

```conf
# 基本形式
map kitty_mod+shift+g   show_scrollback

# 带前缀（先松开前缀再按第二键）
map kitty_mod+p>t       kitten hints --type path --program -

# 取消一个绑定
map kitty_mod+o
```

`quick-access-terminal.conf` 是给 `kitten quick_access_terminal` 用的，与上面的主窗口快捷键无关。
