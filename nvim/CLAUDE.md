# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal Neovim configuration. Uses Neovim 0.11+ built-in `vim.pack.add()` for plugin management (not lazy.nvim). Plugins are loaded in `init.lua` and configured in `lua/config.lua`.

## Multi-process RPC architecture

This is the most unusual part of the config. On `UIEnter`, the main nvim spawns **two child nvim instances** that communicate via `vim.rpcnotify` over Unix pipes:

- **Floating terminal** (`init_flt_term.lua`) — a hidden full-screen terminal toggled with `<C-t>`. Buffer: `Remote_flt_term_buf`, channel: `Flt_term_chan`.
- **Sub terminal** (`init_sub_term.lua`) — a split terminal (below/left/above/right) toggled with `<C-,>`. Buffer: `Remote_sub_term_buf`, channel: `Sub_term_chan`. Cycles position with `CycleTerm` command.

Both child instances load `lua/remote_terminal.lua`, which sets up tab-based terminal management. Each child connects back to the father via `Father_chan = vim.fn.sockconnect("pipe", vim.g.pip_father, { rpc = true })`. The father connects to the children as `Flt_term_chan` / `Sub_term_chan`.

When editing any file in this repo, be aware that modifying RPC plumbing (`terminal.lua`, `remote_terminal.lua`, or the `*_term.lua` init files) can break the multi-instance terminal system.

## Key files

| File | Purpose |
|------|---------|
| `init.lua` | Entry point: vim options, Neovide config, RPC setup, plugin list, `require` calls |
| `lua/config.lua` | All plugin `setup()` calls (mini.completion, conform, snacks, flash, etc.) |
| `lua/theme.lua` | Custom colorscheme with saturation control (`<leader>=`/`<leader>-`) |
| `lua/ui.lua` | Diagnostics config, statusline, foldtext |
| `lua/aichat.lua` | AI chat integration via TCP RPC (`<leader>g`), session picker, model cycling |
| `lua/keymaps.lua` | General key mappings (save, resize, format, picker, flash, oil, emacs-style) |
| `lua/autocmds.lua` | Lint on save, disable LSP semantic tokens, hide diagnostics in insert mode |
| `lua/terminal.lua` | Terminal window creation/toggle for the main nvim instance |
| `lua/remote_terminal.lua` | Tab-terminal system for child nvim instances, `_G.goto_or_create_tab()`, RPC helpers |
| `lua/edit.lua` | Auto-pair brackets/quotes with smart handling for empty pairs, enter, space, backspace |
| `lua/indent.lua` | Custom indent guides using `nvim_set_decoration_provider` + tree-sitter + C FFI |
| `lua/imselect.lua` | macOS input method switching (en/zh) via `im-select` |
| `lua/claude.lua` | Placeholder (empty module) |
| `lua/aidiff.lua` | AI diff review plugin: snapshot-based before/after diff with accept/rollback |

## LSP

Configured via `vim.lsp.enable()` (Neovim 0.11+ built-in) with server configs in `lsp/`:
- `lsp/lua_ls.lua` — lua-language-server
- `lsp/perlnavigator.lua` — Perl Navigator

The `ftplugin/lua.lua` sets up lazydev.nvim for Lua files.

## Formatters & linters

- **conform.nvim**: `stylua` (Lua), `perltidy` (Perl), `isort` + `black` (Python). Format key: `<C-l>`.
- **nvim-lint**: Runs on `BufWritePost`. Lints for current filetype + always runs `typos`.

## Dependencies on external tools

- `im-select` (brew) — for `lua/imselect.lua`
- `lua-language-server`, `perlnavigator` — LSP servers
- `stylua`, `perltidy`, `isort`, `black` — formatters
- `typos` — spell-check linting

## AI Diff Protocol

When modifying project source files (NOT this nvim config itself), Claude MUST follow this protocol so the user can review changes in Neovim via `:AiDiff`.

### Step 1: Generate session name

Before the first file write, generate a unique session name: `claude-YYYYMMDD-HHMMSS` (current timestamp).

### Step 2: Snapshot before every write

Before each `Write` or `Edit` tool call that modifies a file, save the original file contents:

```bash
SESSION_ROOT=~/.cache/nvim/ai-diff/sessions/<session_name>
CWD=<absolute project root>
REL_PATH=<file path relative to CWD>
TARGET="$CWD/$REL_PATH"

mkdir -p "$SESSION_ROOT/$(dirname "$REL_PATH")"

if [ ! -f "$SESSION_ROOT/$REL_PATH" ]; then
  if [ -f "$TARGET" ]; then
    cp "$TARGET" "$SESSION_ROOT/$REL_PATH"
  else
    touch "$SESSION_ROOT/$REL_PATH"
  fi
fi
```

Key rules:
- Skip snapshot if `$SESSION_ROOT/$REL_PATH` already exists (first snapshot wins).
- For new files (target doesn't exist), create an empty snapshot file.
- Only snapshot files in the project being modified, NOT this nvim config.

### Step 3: Write/modify the target file

Proceed with the `Write` or `Edit` tool call after snapshot is saved.

### Step 4: Notify Neovim after all changes

After ALL file modifications are complete, notify the user to run:

```
:AiDiff review <session_name> <cwd>
```

Or if `$NVIM` is set, send the command directly:

```bash
nvim --server "$NVIM" --remote-send "<Cmd>AiDiff review <session_name> <cwd><CR>"
```

### Neovim commands (for user)

| Command | Action |
|---------|--------|
| `:AiDiff review <session> [cwd]` | Scan session, sync buffers, show modified files in quickfix |
| `:AiDiff accept <session>` | Delete session (keep AI changes) |
| `:AiDiff rollback <session> [cwd]` | Restore all files from snapshots, delete session |
| `:AiDiff list` | List all available sessions |
