# grep.lua 说明

文件路径：`nvim/lua/grep.lua`
加载方式：`init.lua` 中 `require("grep")`（加载即注册命令与映射，无需 `setup()`）

---

## 1. 模块目标

一个**自实现的异步 grep 搜索器**，替代/增强 Neovim 内置的 `:grep`：

- 调用外部命令（默认 `grepprg`，本机为 `rg --vimgrep -uu`）做全项目搜索。
- **异步流式**执行：结果边产生边填充 quickfix / location list，不阻塞 UI。
- 进度状态栏：搜索中显示动画进度条与已匹配数量，结束时显示 `Done`。
- quickfix 列表自定义渲染：文件分组标题行 + 对齐的行号/列号 + 内容。
- 内置**浮动预览窗口**：在列表上按 `p` 可在上方弹出对应源码并高亮。
- 两条命令：`:Grep` 使用 location list，`:GREP` 使用 quickfix list。

---

## 2. 依赖与全局别名

```lua
local api, QUICK, LOCAL, FORWARD, BACKWARD, mapset = vim.api, 1, 2, 1, 2, vim.keymap.set
local treesitter, fn = vim.treesitter, vim.fn
local async = vim.async
```

- `QUICK = 1` / `LOCAL = 2`：区分 quickfix 与 location list。
- `FORWARD = 1` / `BACKWARD = 2`：移动方向。
- `async = vim.async`：**Neovim 0.12+** 提供的协程异步 API（`async.run` / `async.await`）。
  - `async.run(fn)`：在协程里运行 `fn`。
  - `async.await(argc, fun, ...)`：调用 `fun`，并把它的第 `argc` 个参数替换为回调，协程在此挂起，直到回调被调用；`await` 的返回值即回调收到的参数。
  - 本文件用它把 `vim.system` 的 `on_exit`（第 3 个参数）变成可等待的回调。

> 因为使用了 `vim.async`，该模块要求 **Neovim 0.12+**。

---

## 3. 命令与映射速查

### 3.1 用户命令

| 命令 | 列表类型 | 参数 | 补全 |
| --- | --- | --- | --- |
| `:Grep <pattern...>` | location list（按窗口） | `nargs = '+'` | `file_in_path` |
| `:GREP <pattern...>` | quickfix list（全局） | `nargs = '+'` | `file_in_path` |

命令内部的 `t` 分别传 `LOCAL` / `QUICK`：

```lua
api.nvim_create_user_command('Grep', function(opts)
  grep(LOCAL, unpack(opts.fargs))
end, { nargs = '+', complete = 'file_in_path', desc = 'Search using location list' })
```

额外注册了**命令行缩写**：在命令行输入 `grep` 会自动展开成 `Grep`（仅当整行就是 `grep` 时）：

```vim
cnoreabbrev <expr> grep (getcmdtype() ==# ':' && getcmdline() ==# 'grep') ? 'Grep' : 'grep'
```

### 3.2 quickfix 窗口内的映射

由 `setup_init(buf, is_quick)` 在打开列表窗口后设置，均为 **buffer-local**：

| 键 | 行为 |
| --- | --- |
| `q` | 关闭预览窗口 + 关闭列表（`cclose` / `lclose`） |
| `<Esc>` | 只关闭预览窗口（`close_preview`） |
| `<C-n>` | 下一个匹配（`cnext` / `lnext`），并刷新预览 |
| `<C-p>` | 上一个匹配（`cprev` / `lprev`），并刷新预览 |
| `p` | 切换预览窗口（`toggle_preview`） |

> 注意：`p` 仅在 quickfix/location 窗口内覆盖了默认的粘贴；其它窗口不受影响。

---

## 4. 状态结构（state）

```lua
local state = {
  preview = {
    win = nil,       -- 预览浮动窗口 id
    enabled = false, -- 是否处于预览模式
    autocmd = nil,   -- 监听 CursorMoved 的 autocmd id
  },
  count = 0,   -- 当前已匹配数量（用于标题）
  done = false,-- 搜索是否结束
  win = nil,   -- 列表窗口 id
  buf = nil,   -- 列表 buffer id
}
```

---

## 5. 执行流程（从输入命令到结果落地）

```
:Grep foo
  └─ grep(LOCAL, "foo")
       ├─ 重置 state.count / state.done
       └─ async.run(function()
            ├─ ① 构建外部命令 cmd（见 §6）
            ├─ ② 记录 owner = 当前窗口（location list 归属）
            ├─ ③ async.await(3, vim.system, cmd, { stdout = 流式回调 })
            │     每收到一段 stdout：
            │       ├─ 拼接 pending，按 '\n' 切分，保留最后不完整行
            │       ├─ parse_line：识别文件名、累加计数、插入分组标题伪条目
            │       ├─ 达到 batch_size(200) 或 EOF 时切出一个 batch
            │       └─ vim.schedule 回到主线程：填充列表 + 刷新 UI
            ├─ ④ 第一次有内容时：copen/lopen 打开并 setup_init 绑定映射/高亮
            └─ ⑤ await 返回后：退出码 >1 视为错误并 notify
          end)
```

关键点：**填充列表与打开窗口都通过 `vim.schedule` 回到主线程执行**（stdout 回调运行在快速事件上下文中，不能直接改 UI）。

---

## 6. 外部命令构建规则

```lua
local cmd = {}
local expanded = false
for _, part in ipairs(vim.split(vim.o.grepprg, '%s+', { trimempty = true })) do
  if part == '$*' then
    expanded = true
    table.insert(cmd, '--fixed-strings')
    vim.list_extend(cmd, args)
  else
    table.insert(cmd, part)
  end
end
if not expanded then
  table.insert(cmd, '--fixed-strings')
  vim.list_extend(cmd, args)
end
```

规则：

1. 把 `&grepprg` 按空白切成词。
2. 若出现 `$*` 占位符，则在**该位置**插入 `--fixed-strings` 及用户参数；否则在**命令末尾**追加 `--fixed-strings` 及用户参数。
3. `$*` 只会展开一次（第一处之后的 `$*` 会被保留成普通参数）。

以本机为例：

```text
grepprg = rg --vimgrep -uu
:Grep hello world
→ rg --vimgrep -uu --fixed-strings hello world
```

**含义**：默认所有搜索都是**字面量（固定字符串）搜索**，不带正则。若想用正则，需要修改 `grepprg` 或本文件逻辑。

---

## 7. 输出解析与 quickfix 渲染

### 7.1 每行解析 `parse_line`

识别两种 vimgrep 格式的文件名前缀：

- `filename:lnum:col:text`（带列号）
- `filename:lnum:text`（不带列号）

```lua
local filename = line:match('^(.-):%d+:%d+:') or line:match('^(.-):%d+:')
```

若匹配成功：

- `total` 计数 +1。
- 若是**该文件首次出现**，插入一条 `lnum == 0` 的**伪条目**作为文件分组标题：
  ```lua
  table.insert(chunk, filename .. ':0:0:')
  ```
- 原始行本身也追加进 `chunk`。

> 用 `seen_files` 表去重，`filename -> true`。

### 7.2 命令 `errorformat`

```lua
efm = '%f:%l:%c:%m,%f:%l:%m'
```

对应上面两种格式；`lnum == 0` 的伪条目通过第二条 `%f:%l:%m` 也无法解析出有效行列，于是留作标题。

### 7.3 自定义渲染 `quickfixtextfunc = qf_text`

`qf_text(info)` 是**无状态**的：对 `info` 指定的 `[start_idx, end_idx]` 区间，**每个 item 恰好输出一行**。这样即使增量调用（每次 append 的批次、`setqflist` 分片）也不会错位或重复。

渲染格式：

| 情况 | 输出 |
| --- | --- |
| item 不存在 | 空字符串 |
| `item.lnum == 0`（标题行） | `▸ <文件名>` |
| 正常匹配 | `  %4d:%-3d │ <文本>` |

```lua
lines[#lines + 1] = string.format('▸ %s', name)
lines[#lines + 1] = string.format('  %4d:%-3d │ %s', item.lnum, item.col or 0, item.text or '')
```

### 7.4 批量填充

- `batch_size = 200`：每积累 200 条就 flush 一次，实现“边搜边出”。
- EOF（`data == nil`）时把剩余 `chunk` 全部 flush（这是原实现修复的关键 bug：尾部数据不回填）。
- 追加写列表：
  ```lua
  qf_fn({}, id and 'a' or ' ', {
    lines = process, id = id,
    efm = '%f:%l:%c:%m,%f:%l:%m',
    title = title, quickfixtextfunc = qf_text,
  })
  ```
  - 第一次用 `' '`（新建，替换），之后用 `'a'`（追加）。
  - 首次写入后通过 `getqflist({id=0}).id` / `getloclist(owner,{id=0}).id` 取回 id 供追加。

### 7.5 location list 的归属窗口

location list 是**按窗口**的。为避免异步过程中焦点切换导致写入错误窗口，代码在启动时记录 `owner`：

```lua
local owner = api.nvim_get_current_win()
local qf_fn = is_quick and function(...) fn.setqflist(...) end
                    or function(...) fn.setloclist(owner, ...) end
```

并在首次打开前，如当前窗口不是 `owner` 就切回 `owner`。

---

## 8. 进度标题 `update_title`

```lua
local width = 15
if not state.done then
  local anim_pos = state.count % width
  -- 15 个格子，第 anim_pos 个为 ●，其余 ○
else
  -- 全部 ●
end
vim.wo[state.win].stl =
  string.format(' %s [%s] %d matches', state.done and 'Done' or 'Searching', bar, state.count)
api.nvim__redraw({ win = state.win, statusline = true })
```

- 利用 `state.count % 15` 做简单动画。
- 通过设置窗口局部 `statusline`（`stl`）显示进度。
- `nvim__redraw`（内部 API）强制刷新状态栏。

---

## 9. 浮动预览窗口

### 9.1 开关 `toggle_preview(buf)`

- 若已开启 → `close_preview()` 关闭。
- 否则 `preview.enabled = true`，调用 `update_preview()`，并注册 **buffer-local `CursorMoved`**（`preview.autocmd`）以便光标移动时同步预览。

### 9.2 创建窗口 `create_preview_window(bufnr)`

- 相对 quickfix 窗口定位：宽度与其相同，置于其**上方**。
- 高度 = `floor(&lines * 0.6)`；若空间不足（`preview_row < 0`），则贴顶并压缩高度。
- 属性：`style = 'minimal'`、`focusable = false`（不抢焦点）。
- 注册一次性 `WinClosed` autocmd → 预览窗口被任何方式关闭时自动清理。

### 9.3 刷新 `update_preview()`

1. 仅在 `preview.enabled` 时工作。
2. 判断当前窗口是 location list 还是 quickfix（`getwininfo(...).loclist == 1`）。
3. 取当前行 `fn.line('.')`，从对应列表取 item。
4. 跳过空 buffer：`if not item or not item.bufnr or item.bufnr == 0 then return end`
   （注释特别指出 Lua 中 `0` 为真值，必须显式比较）。
5. 需要时创建预览窗口，`nvim_win_set_buf` 换 buffer。
6. 若 `vim.filetype.match` 得到 ft，则尝试 `treesitter` 启动高亮。
7. 定位光标：`{lnum = max(item.lnum or 1, 1), col = max((item.col or 1) - 1, 0)}`
   （`win_set_cursor` 需要 1-based 行、0-based 列）。
8. `normal! zz` 让目标行居中。

### 9.4 关闭 `close_preview()`

- `enabled = false`
- 删除 `CursorMoved` autocmd
- 关闭预览窗口（若有效）
- 置 `win = nil`

> 幂等：多处（`q`、`<Esc>`、`WinClosed`）都会调用，内部做了有效性判断与 `pcall`。

---

## 10. 列表窗口初始化 `setup_init(buf, is_quick)`

窗口选项（buffer-local）：

```lua
vim.opt_local.wrap = false
vim.opt_local.number = false
vim.opt_local.relativenumber = false
vim.opt_local.signcolumn = 'no'
```

高亮（window-local `matchadd`，优先级从高到低）：

| 组名 | 匹配正则 | 优先级 |
| --- | --- | --- |
| `qfFileName` | `^▸ \zs.*` | 12 |
| `qfLineNr` | `^\s\+\d\+:\d\+` | 20 |
| `qfSeparator` | `│` | 15 |
| `qfText` | `│ \zs.*` | 10 |

> `qfFileName` / `qfLineNr` / `qfText` 由 Neovim 运行时 `syntax/qf.vim` 定义（`hi def link`）。
> 但 `qfSeparator`（不带数字后缀）**在默认运行时里并不存在**，需要在主题中自行定义才能生效。

移动函数（闭包）：

```lua
local move = function(dir)
  return function()
    api.nvim_buf_call(buf, function()
      pcall(vim.cmd, dir == FORWARD and (is_quick and 'cnext' or 'lnext')
                              or (is_quick and 'cprev' or 'lprev'))
      update_preview()
    end)
  end
end
```

---

## 11. 错误处理

```lua
if result.code > 1 then
  vim.schedule(function()
    local msg = (result.stderr and result.stderr ~= '') and ('\n' .. result.stderr) or ''
    vim.notify('Grep failed with exit code: ' .. result.code .. msg, vim.log.levels.ERROR)
  end)
end
```

- grep/rg 的退出码 `1` 表示“无匹配”，属正常；只有 `> 1` 才报错。
- 错误通过 `vim.notify(..., ERROR)` 在主线程弹出。

---

## 12. 注意事项与已知限制

1. **需要 Neovim 0.12+**：依赖 `vim.async`。
2. **默认字面量搜索**：命令总会加 `--fixed-strings`，无法直接使用正则（除非改 `grepprg`/本模块）。
3. **`qfSeparator` 未定义**：需在 `theme.lua` 等位置添加 `hi qfSeparator`，否则分隔符无高亮。
4. **location list 的 owner 语义**：`:Grep` 的结果绑定到发起命令的窗口；若该窗口关闭，写入会被跳过（`nvim_win_is_valid(owner)` 检查）。
5. **`p` 键覆盖**：仅在 qf/loc 窗口内生效，但会屏蔽该窗口内的粘贴操作。
6. **预览窗口不可聚焦**：`focusable = false`，用 `close_preview` 关闭而不是普通窗口切换。
7. **Windows/多屏**：预览窗口基于 quickfix 窗口的屏幕坐标计算，极端布局下会贴顶并压缩高度。
8. **重复 `:Grep`**：会重置 `count/done`，但不会主动清空上一次已打开列表；第一次 flush 用新建（`' '`）覆盖。

---

## 13. 可扩展点

- 增加“正则模式”开关，去掉硬编码的 `--fixed-strings`（例如根据 `\v` 或参数前缀判断）。
- 支持在 `grepprg` 中插入更多参数（当前仅 `$*` 单一占位符）。
- 为 `qfSeparator` 等补充高亮定义到 `lua/theme.lua`。
- 预览窗口可加入 `scrolloff` / 自适应高度 / 跟随水平滚动等增强。
- 可暴露 `require('grep').setup({ batch_size = ..., grepprg = ... })` 做配置化（当前为常量/直接读 `&grepprg`）。

---

## 14. 源码结构总览（按出现顺序）

| 函数 / 语句 | 作用 |
| --- | --- |
| `close_preview()` | 关闭预览并清理 autocmd 状态 |
| `create_preview_window(bufnr)` | 在列表窗口上方创建浮动预览窗 |
| `update_preview()` | 根据当前列表项刷新预览内容与光标 |
| `toggle_preview(buf)` | 开关预览模式 |
| `setup_init(buf, is_quick)` | 初始化列表窗口的选项、高亮与键位 |
| `update_title()` | 更新搜索进度状态栏 |
| `qf_text(info)` | `quickfixtextfunc`，无状态逐行渲染 |
| `grep(t, ...)` | 主流程：构命令 → 异步执行 → 流式填充列表 |
| `:Grep` / `:GREP` | 用户命令注册 |
| `cnoreabbrev` | `grep` → `Grep` 命令行缩写 |
