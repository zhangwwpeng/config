# Lsp

## lsp插件

未使用任何第三方 LSP 插件，使用 Neovim 0.11+ 内置 `vim.lsp.enable()`。

配置文件目录：`lsp/*.lua`  
启用入口：`lua/code_lsp.lua`

## 配置

| file_type | lsp | 配置文件 | 职责 | 安装方式 |
| - | - | - | - | - |
| lua | lua_ls | `lsp/lua_ls.lua` | 补全 / 诊断 / 跳转 | `brew install lua-language-server` |
| c / c++ | clangd | `lsp/clangd.lua` | 补全 / 诊断 / 跳转 | `brew install llvm` |
| rust | rust_analyzer | `lsp/rust_analyzer.lua` | 补全 / 诊断 / 跳转 | `rustup component add rust-analyzer` |
| bash / sh | bashls | `lsp/bashls.lua` | 补全 / 诊断 / 跳转 | `brew install bash-language-server` |
| just | just | `lsp/just.lua` | 补全 / 诊断 / 跳转 / format | `cargo install just-lsp` |
| make | make_ls | `lsp/make_ls.lua` | 补全 / 诊断 / 跳转 / format | `go install github.com/owenrumney/make-ls/cmd/make-ls@latest` |
| tcl | tcl_lsp | `lsp/tcl_lsp.lua` | 补全 / 诊断 / 跳转 / format | Manual install（见下） |
| python | ruff | `lsp/ruff.lua` | lint 诊断、organize imports | `brew install ruff` |
| python | basedpyright | `lsp/basedpyright.lua` | 类型检查诊断 | `brew install basedpyright` |
| python | pyrefly | `lsp/pyrefly.lua` | 补全 / 跳转 | `brew install pyrefly` |

### clangd

- 项目根识别：`compile_commands.json`、`.clangd`、`.clang-format` 等
- 建议生成编译数据库：

```bash
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .
ln -sf build/compile_commands.json .
```

### rust_analyzer

- 项目根识别：`Cargo.toml`、`Cargo.lock`、`rust-project.json`、`.git`
- 需在 Rust 项目目录（含 `Cargo.toml`）内打开文件

### bashls

- 支持 `bash`、`sh` filetype（`.sh` 通过 `code_tressiter.lua` 注册为 bash 高亮）
- 项目根识别：`.git`；单文件脚本也可 attach
- 诊断依赖 **shellcheck**（可选但推荐）：`brew install shellcheck`

### just

- 支持 `just` filetype（Neovim 0.11+ 内置 justfile 识别）
- 项目根识别：`justfile`、`Justfile`、`.justfile`、`.git`
- format 由 LSP 提供（`just-lsp` 内置）

### make_ls

- 支持 `make` filetype（Makefile / makefile / GNUmakefile）
- 项目根识别：`Makefile`、`makefile`、`GNUmakefile`、`.git`
- format 由 LSP 提供（`make-ls` 内置）

### tcl_lsp

- 支持 `tcl`、`tcl-apl` filetype（`.tcl`、`.tk`、`.irule` 等扩展名见 `code_lsp.lua`）
- 项目根识别：`.git`；`single_file_support = true`
- 仅需 Python 3.10+，zipapp 自带依赖，无需 pip/uv
- Manual install（[INSTALL-cli.md](https://github.com/bitwisecook/tcl-lsp/blob/main/INSTALL-cli.md) 同款方式，只装 LSP server）：

```bash
version=1.11.3
curl -fLO "https://github.com/bitwisecook/tcl-lsp/releases/download/v${version}/tcl-lsp-server-${version}.pyz"
install -m 0755 "tcl-lsp-server-${version}.pyz" ~/.local/bin/tcl-lsp-server.pyz
```

- Neovim 配置：`lsp/tcl_lsp.lua` + `vim.lsp.enable("tcl_lsp")`

### Python 三分工

配置在 `lsp/ruff.lua`、`lsp/basedpyright.lua`、`lsp/pyrefly.lua`，共享 `lua/python_lsp.lua` 的 `root_dir`：

- **ruff**：快速 lint；关闭 format/hover（format 交给 conform）
- **basedpyright**：精确类型诊断；关闭补全/跳转/format 等（交给 pyrefly / ruff / conform）
- **pyrefly**：快速补全和导航；关闭 semantic tokens / code action / hover 等（高亮用 treesitter，其余交给 basedpyright / ruff）

在 `lua/code_lsp.lua` 中启用：

```lua
vim.lsp.enable({
    "lua_ls",
    "clangd",
    "rust_analyzer",
    "bashls",
    "just",
    "make_ls",
    "tcl_lsp",
    "ruff",
    "basedpyright",
    "pyrefly",
})
```

# Lint

## lint插件

    "https://github.com/mfussenegger/nvim-lint",

配置入口：`lua/code_lint.lua`

## 配置

保存时触发 lint（`BufWritePost`）。

| file_type | ext_lint | function | 安装方式 |
| - | - | - | - |
| all_file | typos | 拼写检查 | `brew install typos-cli` |
| c/cpp | clangtidy | lint | `brew install llvm` |
| rust | clippy | lint | `brew install rust` |
| json / jsonc | jsonlint | 语法检查 | `brew install jsonlint` |
| yaml | yamllint | lint | `brew install yamllint` |
| toml | taplo | 语法检查 | `brew install taplo` |

Python 的 lint 由 **ruff LSP** 负责，不再通过 nvim-lint 重复跑 ruff。

# Format

## format插件

    "https://github.com/stevearc/conform.nvim",

配置入口：`lua/code_format.lua`

| file_type | formatter | 说明 | 安装方式 |
| - | - | - | - |
| lua | stylua | 外部 formatter | `brew install stylua` |
| python | ruff_format | `ruff format` | `brew install ruff` |
| c / c++ | clangd (LSP) | `lsp_format = "fallback"`，走 clangd 内置 format | `brew install llvm` |
| rust | rust_analyzer | lsp_format  = "fallback" | `rustup component add rust-analyzer` |
| just | just-lsp (LSP) | `lsp_format = "fallback"` | `cargo install just-lsp` |
| make | make-ls (LSP) | `lsp_format = "fallback"` | `go install github.com/owenrumney/make-ls/cmd/make-ls@latest` |
| tcl | tcl-lsp (LSP) | `lsp_format = "fallback"` | Manual install `tcl-lsp-server.pyz` |
| bash / sh | shfmt | 外部 formatter | `brew install shfmt` |
| json / jsonc | jq | 按 `shiftwidth` 缩进 | 系统自带 / `brew install jq` |
| yaml | yamlfmt | 外部 formatter | `brew install yamlfmt` |
| toml | taplo | `taplo format` | `brew install taplo` |
| 其他 | trim_whitespace | 默认 fallback | 内置 |

格式化快捷键：`<C-l>`（同时关闭所有 float window）。

# Treesitter

配置入口：`lua/code_tressiter.lua`  
安装脚本：`scripts/tressiter_install.sh`  
Parser 安装路径：`~/.local/share/nvim/site/parser/`  
Queries 目录：`queries/<lang>/`

## 自动启用 filetype

`c`、`verilog`、`python`、`rust`、`sh`、`markdown`、`json`、`yaml`、`toml`、`just`、`make`、`tcl`

## 已安装 parser

| parser | 来源 |
| - | - |
| python | `tree-sitter/tree-sitter-python` (v0.25.0) |
| bash | `tree-sitter/tree-sitter-bash` |
| json | `tree-sitter/tree-sitter-json` |
| yaml | `tree-sitter-grammars/tree-sitter-yaml` |
| toml | `tree-sitter-grammars/tree-sitter-toml` |
| rust | `tree-sitter/tree-sitter-rust` |
| just | `casey/tree-sitter-just` |
| make | `tree-sitter-grammars/tree-sitter-make` |
| tcl | `tree-sitter-grammars/tree-sitter-tcl` |
| systemverilog | `gmlarumbe/tree-sitter-systemverilog` |

安装：

```bash
bash ~/.config/nvim/scripts/tressiter_install.sh
```
