# 安装、依赖与权限

## 支持范围

桌面部分只面向 macOS。当前 Karabiner 命令和 Shell PATH 使用 `/opt/homebrew`，即 Apple Silicon Homebrew；Intel Mac 需要把相关路径改成 `/usr/local`。Neovim 的大部分配置可在 Unix 环境运行，但输入法、GUI、quick-access terminal 和 RPC pipe 行为按 macOS 验证。

## 1. 基础环境

先安装 Homebrew、Git、Just、rsync 和 Neovim：

```bash
brew install git just neovim
```

macOS 自带 `/usr/bin/rsync` 可以运行当前安装器，也可用 Homebrew 新版本。

确认 Neovim 至少为 0.12：

```bash
nvim --version
```

配置使用 `vim.pack.add()`、`vim.lsp.enable()`、`vim._core.ui2` 和内部 FFI 接口。0.11 没有 `vim.pack`；未来 Neovim 升级后，内部 UI/FFI 模块也需要重新做启动测试。

## 2. 桌面组件

按需安装：

```bash
brew install kitty neovide sketchybar yabai im-select
brew install --cask karabiner-elements
```

Glide 不由仓库自动安装，请按该工具自己的发布方式安装。yabai 在本配置中只负责 Space 聚焦，所有窗口都设置为 `manage=off`；Glide 才负责可选平铺，因此两者可以同时存在。

字体需手动确认：

- Kitty、Neovide：`Maple Mono Normal NF CN`
- SketchyBar：`Hack Nerd Font`

字体名称不同会导致回退字体、图标方块或宽度错位，可以直接修改 `kitty/kitty.conf`、`neovide/config.toml` 和 `sketchybar/sketchybarrc`。

## 3. macOS 权限

### Karabiner-Elements

在“系统设置 → 隐私与安全性”中允许 Karabiner 需要的输入监控权限。配置包含：

- Caps Lock → 左 Shift+Option；
- `Ctrl+H/K` → Backspace/Enter；
- Kitty 和 yabai 的全局 shell command。

如果快捷键没有响应，先在 Karabiner EventViewer 确认输入 key code，再检查 `/opt/homebrew/bin/kitten`、`im-select` 和 `yabai` 是否存在。

### SketchyBar

启动并注册服务：

```bash
brew services start sketchybar
sketchybar --reload
```

`feishu.sh` 通过 `lsappinfo` 读取飞书和企业微信角标。系统或应用不提供 `StatusLabel` 时，消息项会保持隐藏。

### yabai

```bash
yabai --start-service
```

yabai 需要辅助功能权限。当前配置不移动、缩放或平铺窗口，只通过 CLI 聚焦 Space；是否需要调整 SIP 取决于安装的 yabai 版本和所使用的 Space 功能，请以 yabai 官方文档为准。

### Kitty quick-access terminal

先手动执行一次：

```bash
kitten quick-access-terminal
```

Karabiner 的 `Shift+Option+O` 之后会调用同一命令。外观来自 `kitty/quick-access-terminal.conf`。

## 4. Neovim 工具链

常用工具：

```bash
brew install fzf ruff basedpyright pyrefly lua-language-server
brew install llvm bash-language-server shellcheck
brew install stylua shfmt yamlfmt taplo svlint verilator
cargo install just-lsp
go install github.com/owenrumney/make-ls/cmd/make-ls@latest
```

其他手动组件：

- `slang-server`
- `verible-verilog-format`、`verible-verilog-lint`
- `tcl-lsp-server.pyz`
- Rust 的 `rust-analyzer` 和 `clippy`
- `tree-sitter` CLI

完整职责和安装方式见 [../nvim/doc/lsp_lint.md](../nvim/doc/lsp_lint.md)。

安装本仓库所列 Tree-sitter parser：

```bash
bash ~/.config/nvim/scripts/treesitter_install.sh
```

脚本使用临时工作目录并在退出时清理；parser 写到 `~/.local/share/nvim/site/parser/`。

## 5. Shell 与 Secrets

`.zshrc` 和 `.bashrc` 都会加载 `~/.common_sh`。安装器必须同时部署这三个文件，否则 shell 会在启动时报错。

按需创建：

```bash
touch ~/.secrets_sh
chmod 600 ~/.secrets_sh
```

示例（不要提交真实值）：

```bash
export DEEPSEEK_API_KEY='...'
export GEMINI_API_KEY='...'
```

公共配置固定导出本地代理：

```text
http://127.0.0.1:7897
socks5://127.0.0.1:7897
```

不使用代理时应删除或注释 `.common_sh` 对应行；否则 Homebrew、Git、curl 和 AI SDK 可能连接失败。

## 6. AI chat 服务

```bash
cd ~/.config/nvim/aichat_nvim
uv sync
uv run python main.py
```

服务监听 `127.0.0.1:6666`，数据结构为：

```text
~/.local/aichat/
├── system.txt
└── session/
    └── <name>/
        ├── chat.md
        └── summary.txt
```

这是仅监听 loopback 的个人服务，没有远程认证能力；不要把监听地址改为 `0.0.0.0`。

## 7. AI diff hooks

AI diff 是可选功能。它需要把三个 Python hook 配置到实际使用的 AI CLI，并确保 AI CLI 从 Neovim RPC 子终端启动，这样环境中才有 `NVIM_PIP_FATHER`。

Hook 脚本：

- `ai-diff-session-start.py`
- `ai-diff-hook.py`
- `ai-diff-stop.py`

详细 JSON 示例和安全模型见 [../nvim/doc/ai-hooks.md](../nvim/doc/ai-hooks.md)。示例中的 `/Users/wpzhang` 是当前机器路径，迁移时必须替换。

## 8. 部署与恢复

```bash
cd /path/to/config
just doctor
just --dry-run install
just install
```

备份位于：

```text
tmp/backups/YYYYMMDD-HHMMSS/
├── .config/
└── .common_sh / .zshrc / .bashrc
```

恢复示例：

```bash
cp -a tmp/backups/<时间戳>/.zshrc ~/.zshrc
rm -rf ~/.config/nvim
cp -a tmp/backups/<时间戳>/.config/nvim ~/.config/nvim
```

恢复前先退出对应 GUI 应用，避免应用退出时再次覆盖配置。

## 9. 验证

```bash
just check
python3 nvim/scripts/test_ai_diff_hook.py -v
cd nvim/aichat_nvim
uv run python -m unittest discover -s tests -v
```

不会自动化验证的项目：

- Karabiner 实际键盘事件；
- SketchyBar 的 GUI 排版和真实应用角标；
- yabai/Glide 的系统权限与 Space 行为；
- 真实 AI endpoint、额度和模型可用性；
- Neovide/Kitty 在不同显示器上的字体渲染。
