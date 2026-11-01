# Neovim 配置

个人 Neovim 配置，面向 **Neovim 0.13-dev**（用到了 `vim.pack`、`vim._core.ui2`、内置 multicursor、`vim.async`）。
插件用内置 `vim.pack.add()` 管理（锁文件 `nvim-pack-lock.json`），没有 lazy.nvim。

## 目录结构

```text
init.lua                 选项 / neovide / 浮窗透明度 / 插件列表 / 加载各模块
lsp/*.lua                各 LSP server 配置（vim.lsp.config 自动读取）
lua/                     功能模块（见下表）
colors/bamboo_bamboo.lua 自带配色
queries/<lang>/*.scm     treesitter query（覆盖 runtime 自带的）
snippets/*.lua           LuaSnip 片段（lua 格式）
ftplugin/                filetype 局部设置
scripts/                 外部脚本（终端→父 nvim 转发、verible 包装、parser 安装）
doc/                     专题文档
.svlint.toml             svlint 规则（code_lint.lua 用绝对路径引用，需要一起提交）
```

## 启动流程

1. `init.lua` 同步部分：关掉不用的 provider / 内置插件 → 设置选项 → 加载配色 → neovide 配置 → 注册浮窗 `winblend` autocmd。
2. `vim.schedule` 里（首屏渲染之后）：`vim.pack.add` 所有插件，然后按顺序 `require` 各模块。

> 注意：模块是在 `vim.schedule` 里加载的，`nvim foo.py` 打开的第一个 buffer 的 `FileType` 事件已经过去了。
> 所以凡是用 `FileType` autocmd 做初始化的模块，都要给已加载的 buffer 补一次（`code_treesitter.lua` 已经这么做了）。新增类似逻辑时记得照做。

## 模块一览

| 模块 | 作用 |
|------|------|
| `bigfile.lua` | 大文件（>1MB）/ 二进制 / log·csv·tsv：关掉 treesitter（高亮+折叠）、缩进线、treesitter-context、markdown 代码块背景、保存时 lint（含 typos）、AI 补全 |
| `keymaps.lua` | 全局键位（见下文）、目录 buffer 键位、surround、宏、文件信息 |
| `ui.lua` | ui2 消息窗、诊断显示、statusline（laststatus=0，只在分屏时出现）、foldtext、LSP 进度消息过滤 |
| `code_lsp.lua` | `vim.lsp.enable` 所有 server、关 semantic tokens、开 inlay hint / codelens、tcl 系扩展名 |
| `python_lsp.lua` | ruff / basedpyright / pyrefly 共用的 `root_dir`（跳过 site-packages） |
| `code_completion.lua` | blink.cmp 补全 |
| `code_snip.lua` | LuaSnip，`<C-;>` 展开 / 下一个占位符 |
| `code_format.lua` | conform 格式化；verilog/systemverilog 额外跑 `sv_format.lua` |
| `sv_format.lua` | 自写的 SystemVerilog 补充格式化 |
| `code_lint.lua` | nvim-lint，保存时触发；自定义 taplo / svlint / verible / rumdl 解析 |
| `code_treesitter.lua` | 对指定 filetype 启动 treesitter（parser 缺失时静默退回 regex） |
| `code_edit.lua` | 自写 autopair（insert + cmdline） |
| `code_git.lua` | mini.diff 符号列 |
| `code_picker.lua` | refer.nvim picker，并接管 `vim.ui.select` |
| `cmd_panel.lua` | `<C-p>` 命令面板：session、插件管理、AI、pi diff 等 |
| `grep.lua` | 自写异步 grep → quickfix（`:Grep` / `:GREP`），见 [doc/grep.md](doc/grep.md) |
| `run.lua` | `:Run <cmd>` / `:Rerun` 异步运行命令，输出进 quickfix，可在 qf 里 `i` 发 stdin、`E` 发 EOF |
| `quickfix.lua` | quickfix 自定义渲染 + `dd`/`d` 删除条目、`o` 打开并关闭 |
| `terminal.lua` | `<C-t>` 全屏浮动终端，`<C-w>t` 轮换 float/below/left/above/right |
| `focus_tab.lua` | `<C-f>` 把当前 buffer 放进独立 tab 专注编辑（屏蔽切 buffer 类按键） |
| `dir.lua` | 内置目录浏览（filetype=directory）的增删改复制、隐藏文件开关、大小/mtime 虚拟文本 |
| `indent.lua` | 自写缩进线（FFI 调 nvim 内部函数，nvim 升级后若崩溃优先查这里） |
| `imselect.lua` | macOS 输入法自动切换（依赖 `im-select`，没装则自动禁用） |
| `markdown_hlcode.lua` | markdown 代码块背景高亮 |
| `markdown_tabfmt.lua` | markdown 表格自动对齐（命令面板 "markdown fmt" 开关，`:Mtm`） |
| `remote_open.lua` | 终端里 `vim file` 转发到父实例时的打开策略（复用普通窗口，不抢焦点） |
| `ai.lua` | copilot / minuet / cursortab（命令面板 "enable ai" 后才加载） |
| `ai_select.lua` | 选区 → OpenAI 兼容接口流式解释（同上，"enable ai" 后才加载） |
| `agent.lua` | pi / claude 统一入口：两者只能启动一个，`<C-;>` 自动分发给正在运行的那个 |
| `pi_agent_cfg.lua` / `pi_diff.lua` | pi-agent 浮窗 + 每轮 rsync 快照 / codediff 对比 / 回滚 |
| `claude_cfg.lua` | claudecode.nvim 配置 + 自写的全屏浮窗终端 provider（不依赖 snacks）；diff 开在新 tab，不被浮窗盖住 |
| `flash_cfg.lua` / `glance_cfg.lua` / `grug_far_cfg.lua` / `obsidian_cfg.lua` / `treesitter_context_cfg.lua` | 对应插件的 setup |

## 插件

| 插件 | 用途 |
|------|------|
| saghen/blink.cmp + L3MON4D3/LuaSnip | 补全 + snippet |
| stevearc/conform.nvim | 格式化 |
| mfussenegger/nvim-lint | lint |
| juniorsundar/refer.nvim | picker / `vim.ui.select` |
| folke/flash.nvim | `s` / `S` 跳转 |
| DNLHC/glance.nvim | LSP 定义/引用预览 |
| MagicDuck/grug-far.nvim | 项目级搜索替换 |
| esmuellert/codediff.nvim | diff 视图（`:CodeDiff`） |
| nvim-mini/mini.diff | git 改动符号 |
| nvim-treesitter/nvim-treesitter-context | 顶部上下文 |
| folke/lazydev.nvim | lua_ls 的 nvim API 类型 |
| danymat/neogen | 生成注释文档 |
| obsidian-nvim/obsidian.nvim | Obsidian 笔记（vault：`~/vaults/obsidian/doc`） |
| zhangwwpeng/pi-agent.nvim | AI agent 浮窗 |
| coder/claudecode.nvim | Claude Code 集成（和 pi 二选一） |
| zbirenbaum/copilot.lua, milanglacier/minuet-ai.nvim, cursortab/cursortab.nvim | AI 补全（按需启用） |

内置可选包：`nohlsearch`、`nvim.undotree`。

## 常用快捷键

`<leader>` = 空格，`<localleader>` = `\`。

### 通用

| 模式 | 键 | 作用 |
|------|----|------|
| n/x/s | `<C-s>` | 保存 |
| n | `<leader>l` | 格式化（conform + sv_format） |
| n | `<C-p>` | 命令面板 |
| n | `<leader><leader>` | buffer 列表（在浮动终端里打开时只列 term buffer） |
| n | `<leader>f` / `<leader>g` / `<leader>o` | 找文件 / live grep / 最近文件 |
| | `搜索词; -参数` | 在 `<leader>f` / `<leader>g` 的输入框里给 fd / rg 传参数，如 `init; -g '*.lua'`、`init; -e py`。`;` 后面紧跟 `-` 才算分隔符，`a = b;` 照常搜；要搜字面的 `; -` 写 `\;` |
| n | `<leader>e` / `<leader>E` | 打开当前文件所在目录 / cwd |
| n | `<leader>u` | undotree（树里 `<CR>` 用 CodeDiff 对比） |
| n | `<leader>r` | `:Rerun` |
| n | `<leader>t` | 在当前窗口开 `:terminal` |
| n/t | `<C-t>` | 浮动终端开关 |
| n | `<C-w>t` | 终端布局轮换 |
| n/v | `<C-f>` | focus tab 开关 |
| n | `<leader>/` | neogen 生成注释 |
| n | `<Up>/<Down>/<Left>/<Right>` | 调整窗口大小 |
| n | `H` / `L` | 上/下一个 tab |
| n | `J` / `D` | 切到上一个 buffer / 删除 buffer |
| n | `q` | 显示文件信息（路径、ft、大小、光标、LSP） |
| n | `Q` | 录制宏（原 `q`） |
| n | `<C-q>` | 重放上一次宏；x 模式（行选择）对选中行执行上次执行过的宏 |
| n/x | `m` / `m=` | 内置 multicursor（原 `Q` / `q=`） |
| n | `<leader>m{a-z/A-Z}` | 打 mark（原生 `m`） |
| n | `<leader>M` | 列出 mark（当前 buffer 的 a-z + 全局 A-Z），选中后跳过去 |
| n | `gI` | 跳到倒数第二次修改的位置（`g;g;`，覆盖了内置 `gI`） |
| n/x/o | `s` / `S` | flash 跳转 / flash treesitter |
| x | `<Tab>` / `<S-Tab>` | treesitter 扩大 / 缩小选区 |
| x | `a` + 字符 | 用成对符号包围选区（会盖掉 visual 下的 `aw`/`a(` 等文本对象） |
| x | `M` + 字符 | 把选区内的成对符号替换为新符号 |
| x | `Y` / `P` | 复制到 / 从系统剪贴板粘贴；n 模式 `P` 也粘系统剪贴板 |
| x | `p` | 粘贴不覆盖寄存器 |
| x | `O` | 浏览器 Google 搜索选中文本 |
| n/i/x | `<C-/>` | 注释 |
| c/i | `<C-a>` / `<C-e>` / `<C-b>` | emacs 风格行首 / 行尾 / 左移（n/x 下 `<C-e>` 也是行尾） |

`gg` / `G` / `n` / `N` 都加了 `keepjumps`，不会污染 jumplist。

### LSP / 诊断

| 键 | 作用 |
|----|------|
| `gD` / `gr` / `gt` / `gi` | Glance 定义 / 引用 / 类型定义 / 实现 |
| `]d` / `[d` | 跳诊断并弹浮窗 |
| `gK` | virtual_text 在“只当前行 / 所有行”之间切换 |
| `<leader>d` / `<leader>D` | 所有 / 当前 buffer 诊断 → quickfix |

> `gr` 覆盖了 0.11+ 的默认 `grn`/`gra`/`grr`/`gri`/`grt` 前缀，按 `gr` 后会等 `timeoutlen` 再执行 Glance。

### 补全 / AI

| 模式 | 键 | 作用 |
|------|----|------|
| i | `<C-n>` / `<C-p>` | 补全上下项；菜单没开且启用了 AI 时，切到 minuet 并循环建议 |
| i | `<CR>` | 有选中项时确认，否则换行 |
| i | `<C-l>` | 关闭补全菜单 |
| i | `<C-u>` / `<C-d>` | 滚动补全文档 |
| i/s | `<C-;>` | snippet 展开 / 下一个占位符 |
| i | `<C-f>` | 接受 copilot / minuet 的 ghost text，都没有时右移一格 |
| n | `<Tab>` | 接受 cursortab 建议 |
| n/t | `<C-;>` | 打开 / 关闭正在运行的 agent 浮窗（pi 或 claude，同时切输入法） |
| x | `<C-;>` | 把选区发给正在运行的 agent |
| x | `A` / `H`，n `M` | ai_select 提问 / 快速提问 / 进结果窗（"enable ai" 后生效；`A` 只在 `v`/`V` 下提问，块 visual 下仍是原生块尾追加） |

### 目录 buffer（filetype=directory）

| 键 | 作用 |
|----|------|
| `.` | 显示 / 隐藏点文件 |
| `a` / `A` | 新建文件或目录 / 批量新建 |
| `r`（n/x） | 重命名 / 批量重命名 |
| `d`（n/x） | 删除 / 批量删除 |
| `p` | 粘贴（复制）上次 yank 的文件 |

### 待定：覆盖了内置功能的键位

这几个键位目前覆盖了内置行为，还没想好怎么重新分配，先记在这里：

| 键 | 现在的作用 | 被覆盖的内置功能 |
|----|-----------|------------------|
| n `gr` | Glance references | 0.11+ 默认的 `grn`/`gra`/`grr`/`gri`/`grt` LSP 前缀（按 `gr` 后要等 `timeoutlen`） |
| x `a` | 用成对符号包围选区 | visual 模式的 `aw` / `ap` / `a(` 等文本对象 |

## 命令面板（`<C-p>`）

save session / load session / last session / session open dir / restart / piagent start / claude start（两者二选一）/ enable ai / grep（GrugFar）/ markdown fmt / mini diff（overlay）/ change pwd to cwd / pi diff / pi diff rollback / update all plugin / delete plugin。

退出时若打开了 ≥3 个文件 buffer，会自动按 cwd 保存 session 到 `stdpath("state")/sessions/`。

## LSP / 格式化 / Lint

详见 [doc/lsp_lint.md](doc/lsp_lint.md)。简表：

| 语言 | LSP | 格式化 | Lint |
|------|-----|--------|------|
| Lua | lua_ls (+lazydev) | stylua | — |
| C/C++ | clangd | LSP | clang-tidy |
| Python | ruff + basedpyright + pyrefly（分工见文档） | ruff format | ruff (LSP) |
| Bash/sh | bashls | shfmt | — |
| Make | make-ls | LSP | — |
| (System)Verilog | slang-server | verible + sv_format | svlint + verilator + verible-lint |
| JSON | — | jq | jsonlint |
| YAML | — | yamlfmt | yamllint |
| TOML | — | taplo | taplo |
| Markdown | — | rumdl | rumdl |
| 所有文件 | — | trim_whitespace | typos（保存时跑，bigfile 除外） |

外部工具（全部需在 PATH 中）：`lua-language-server clangd bash-language-server make-ls slang-server ruff basedpyright pyrefly stylua shfmt jq yamlfmt taplo rumdl typos jsonlint yamllint clang-tidy svlint verilator verible-verilog-lint verible-verilog-format rg rsync im-select`。

Treesitter parser 用 `scripts/treesitter_install.sh` 安装到 `~/.local/share/nvim/site/parser`。

## 终端里的 vim → 父实例

在 nvim 的 `:terminal` 里，shell wrapper（`~/.common_sh`）把 `vim` / `nvim` / `vimdiff` 转发给父 Neovim（地址取 `NVIM_PIP_FATHER`，否则 `$NVIM`）：

| 命令 | 行为 |
|------|------|
| `vim` / `nvim` / `vi` | 父实例里复用普通窗口 `:edit`（`lua/remote_open.lua`，不抢终端焦点） |
| `vimdiff` | 父实例里 `CodeDiff file` / `CodeDiff dir` |

不在 nvim 终端内、socket 失效或转发失败时，回退到本地 `nvim` / `nvim -d`。
转发脚本 `scripts/nvim_term_remote.py`（纯 stdlib），统一用 `$NVIM_BIN`（默认 `~/nvim-macos-arm64/bin/nvim`）：

```bash
~/.config/nvim/scripts/nvim_term_remote.py "${NVIM_PIP_FATHER:-$NVIM}" file.lua
~/.config/nvim/scripts/nvim_term_remote.py "${NVIM_PIP_FATHER:-$NVIM}" -d f1 f2
~/.config/nvim/scripts/nvim_term_remote.py "${NVIM_PIP_FATHER:-$NVIM}" -d old/ new/
```

## Neovide

只在 `vim.g.neovide` 时生效：`<D-s>/<D-c>/<D-v>` 系统快捷键、`<C-+>`/`<C-_>` 缩放、关闭动画、浮窗模糊阴影、Option 当 Meta、`DirChanged` 时同步 `$PWD`。
字体在 `~/.config/neovide/config.toml` 配，不要在 init.lua 里设 `guifont`。

浮窗透明度唯一来源是 `vim.g.float_win_blend`（init.lua），blink / ui2 / pi-agent / claude 浮窗各自读取。

## 文档

| 文件 | 内容 |
|------|------|
| [doc/lsp_lint.md](doc/lsp_lint.md) | LSP / lint / format / Tree-sitter |
