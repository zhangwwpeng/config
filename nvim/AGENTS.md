
# OpenCode Agent Instructions for Neovim Configuration (`~/.config/nvim`)

This repository contains a Neovim configuration primarily written in Lua.

## Setup and Environment

*   **Neovim Version**: Configuration is tailored for Neovim. Specific version compatibility is not explicitly stated, but relies on features present in recent versions.
*   **Language Servers**:
    *   `lua_ls` and `perlnavigator` are explicitly enabled via `vim.lsp.enable()`.
    *   `nvim-lspconfig` is installed and managed.
*   **Plugin Management**: Plugins are managed using `vim.pack.add` (likely an alias for a plugin manager like `packer.nvim`). Exact plugin versions are locked in `nvim-pack-lock.json`.
*   **External Providers Disabled**: Built-in providers for Perl, Python, Ruby, and Node are disabled (`vim.g.loaded_..._provider = 0`).
*   **Neovide GUI**: Specific configurations exist for the Neovide GUI, including custom keybindings for macOS clipboard integration, window scaling, blur, and opacity.

## Core Commands and Workflows

*   **`mapleader`**: The leader key is set to `space`.
*   **Saving**: Press `<C-s>` in normal, visual, insert, or select mode to save the current file.
*   **Quitting**: Press `<C-q>` in normal, visual, insert, or select mode to save and quit Neovim.
*   **Formatting**: Press `<C-l>` in normal, visual, or insert mode to format the current buffer using `conform.nvim`. The configuration supports `stylua` for Lua, `perltidy` for Perl, and `isort`/`black` for Python.
*   **File Navigation**:
    *   Use `<leader>e` (e.g., `space` then `e`) to open the `oil.nvim` file explorer for the current directory.
    *   Use `<Up>`, `<Down>`, `<Left>`, `<Right>` in normal mode to resize the current window.
*   **Autocompletion**: `blink.cmp` is configured for autocompletion. Standard navigation keys (`<C-p>`, `<C-n>`) and accept (`<C-y>`) are available. Command-line completion is also enhanced.
*   **LSP Interaction**: While LSP is configured, specific commands for interacting with LSP features (e.g., go-to-definition, hover) are not explicitly mapped here and likely rely on default Neovim LSP keybindings or those provided by plugins like `noice.nvim`.
*   **Notifications**: `snacks.nvim` is used for notifications.

## Key Quirks and Conventions

*   **Modular Configuration**: The configuration is organized into multiple Lua files (`init.lua`, `config.lua`, `keymaps.lua`, `theme.lua`, etc.) managed via `require()`.
*   **Linting**: `nvim-lint` is installed, but its activation or configuration is not explicitly defined by custom keybindings or setup calls in the main configuration files. It may rely on LSP diagnostics or implicit auto-triggering.
*   **Embedded Terminals**: Custom RPC channels are set up for two embedded Neovim instances, likely for specific terminal functionalities.
*   **Custom Keymaps**: Several custom keybindings are defined, particularly for Neovide, window management, and basic editing actions.
*   **No Build/Test Commands**: No explicit commands for building, testing, or running linters/formatters via external scripts or commands are defined in these core configuration files. Interactions are expected to be within Neovim.
