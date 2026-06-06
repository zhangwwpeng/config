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
| `lua/config.lua` | All plugin `setup()` calls (blink.cmp, conform, snacks, flash, etc.) |
| `lua/theme.lua` | Custom colorscheme (`Settheme` command), statusline, diagnostics config, foldtext |
| `lua/keymaps.lua` | General key mappings (save, resize, format, picker, flash, oil, emacs-style) |
| `lua/autocmds.lua` | Lint on save, disable LSP semantic tokens, hide diagnostics in insert mode |
| `lua/terminal.lua` | Terminal window creation/toggle for the main nvim instance |
| `lua/remote_terminal.lua` | Tab-terminal system for child nvim instances, `_G.goto_or_create_tab()`, RPC helpers |
| `lua/edit.lua` | Auto-pair brackets/quotes with smart handling for empty pairs, enter, space, backspace |
| `lua/indent.lua` | Custom indent guides using `nvim_set_decoration_provider` + tree-sitter + C FFI |
| `lua/imselect.lua` | macOS input method switching (en/zh) via `im-select` |
| `lua/claude.lua` | Placeholder (empty module) |

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
