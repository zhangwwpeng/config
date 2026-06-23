# Neovim 配置

个人 Neovim 配置，面向 Neovim 0.11+。插件通过内置 `vim.pack.add()` 管理（非 lazy.nvim）。

## 要求

- Neovim 0.11+

## 多进程终端

主实例在首次切换时拉起两个子 Neovim，通过 Unix pipe RPC 通信：

| 实例 | 切换键 | 说明 |
|------|--------|------|
| 浮动终端 | `<C-t>` | 全屏浮层，多 tab shell |
| 子终端 | `<C-,>` | 分屏（下/左/上/右），`<leader>t` 隐藏 |

子终端内 shell 会设置 `NVIM_PIP_FATHER`（父实例 servername）。`vim` / `nvim` / `vimdiff` 通过 wrapper 路由到子实例，而不是在终端里再开一个独立 Neovim。

```
主 Neovim (father)
  ├── 子终端 nvim  ← 监听 <father>_sub
  └── 浮动终端 nvim ← 监听 <father>_flt
```

相关文件：`lua/terminal.lua`、`lua/remote_terminal.lua`、`init_sub_term.lua`、`init_flt_term.lua`。

## Shell wrapper（`~/.common_sh`）

在子终端里，`NVIM_PIP_FATHER` 已设置时，`vim` / `vimdiff` 会在**主 Neovim** 里打开文件（焦点留在 terminal）：

| 命令 | 行为 |
|------|------|
| `vim` / `nvim` / `vi` | 主 Neovim 新 tab 打开文件 |
| `vimdiff` | 主 Neovim diff 模式打开 |

未设置 `NVIM_PIP_FATHER` 时回退到系统自带的 `nvim` / `vimdiff`。

### `scripts/nvim_term_remote.py`

纯 stdlib。终端里 `vim` / `vimdiff` 时发给主 Neovim：

- 打开文件：`:e <path>`
- 比较文件：`CodeDiff file f1 f2`
- 比较目录：`CodeDiff dir d1 d2`

```bash
~/.config/nvim/scripts/nvim_term_remote.py "$NVIM_PIP_FATHER" file.lua
~/.config/nvim/scripts/nvim_term_remote.py "$NVIM_PIP_FATHER" -d f1 f2
~/.config/nvim/scripts/nvim_term_remote.py "$NVIM_PIP_FATHER" -d old/ new/
```

## 常用快捷键

| 键 | 作用 |
|----|------|
| `<C-s>` | 保存 |
| `<C-q>` | 退出 |
| `<C-l>` | 格式化（conform） |
| `<C-t>` | 浮动终端 |
| `<C-,>` | 子终端 / 切换分屏方向 |
| `<leader>t` | 隐藏子终端窗口 |
| `<leader>e` | Oil 文件树 |
| `<leader><space>` | 智能文件查找 |
| `<leader>g` | AI chat |
| `<leader>=` / `<leader>-` | 主题饱和度 |

## `scripts/` 目录

| 脚本 | 作用 |
|------|------|
| `nvim_term_remote.py` | 终端内 vim/vimdiff → 主 Neovim |
| `ai_diff_lib.py` | AI diff 公共库 |
| `ai-diff-session-start.py` | SessionStart hook |
| `ai-diff-hook.py` | PreToolUse hook（记录变更到 old/） |
| `ai-diff-stop.py` | Stop hook（填充 new/、通知 Neovim） |
| `test_ai_diff_hook.py` | hook 单元测试 |

AI diff 流程与 hook 配置见 [doc/ai-hooks.md](doc/ai-hooks.md)。

## 文档

| 文件 | 内容 |
|------|------|
| [doc/ai-hooks.md](doc/ai-hooks.md) | Claude/Codex ai-diff hook |
| [doc/lsp_lint.md](doc/lsp_lint.md) | LSP / lint |
| [SHADOW.md](SHADOW.md) | shadow 目录镜像追踪 |
| [CLAUDE.md](CLAUDE.md) | 给 AI 助手的仓库说明 |

## LSP / 格式化

- LSP：`lua_ls`、`perlnavigator`（`lsp/`）
- 格式化：Lua `stylua`，Perl `perltidy`，Python `isort` + `black`
- Lint：`nvim-lint`，保存时触发
