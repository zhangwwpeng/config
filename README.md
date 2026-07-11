# macOS 开发环境配置

这是一套面向 macOS（主要是 Apple Silicon）的个人配置，覆盖 Shell、Neovim、终端、键盘重映射、状态栏和窗口管理。仓库使用 `just` 统一部署；安装前会备份现有配置，且不会自动安装 Homebrew 软件或修改系统权限。

## 配置组成

| 路径 | 部署位置 | 用途 |
|---|---|---|
| `.common_sh`、`.zshrc`、`.bashrc` | `~/` | 公共环境变量、alias、fzf 历史和 Neovim 远程 wrapper |
| `nvim/` | `~/.config/nvim` | Neovim 0.12、LSP、lint、format、RPC 子终端、AI diff/chat |
| `kitty/` | `~/.config/kitty` | Kitty、主题、tab bar、quick-access terminal |
| `neovide/` | `~/.config/neovide` | Neovide 窗口和字体 |
| `karabiner/` | `~/.config/karabiner` | 全局按键重映射和应用快捷键 |
| `sketchybar/` | `~/.config/sketchybar` | Space、前台应用、时间、电池和消息角标 |
| `yabai/` | `~/.config/yabai` | 仅负责 Space 聚焦，不管理窗口布局 |
| `glide/` | `~/.config/glide` | 可按 Space 启用的窗口平铺 |

`karabiner/automatic_backups/` 是历史备份，不参与日常配置审计。`nvim/queries/` 是随 Tree-sitter parser 配套的 query，原则上按上游版本整体更新。

## 快速开始

先安装基础工具：

```bash
brew install just rsync neovim
```

检查当前主机依赖：

```bash
just doctor
```

预览安装命令，不写入 HOME：

```bash
just --dry-run install
```

确认后部署：

```bash
just install
```

安装过程会：

1. 在 `tmp/backups/<时间戳>/` 备份已有配置；
2. 排除 `.git`、`.venv`、缓存、字节码和测试日志；
3. 先写入同文件系统的 staging 路径，再替换目标，避免复制一半的配置生效。

`install` 是“复制部署”，不是符号链接。修改仓库后需要再次运行 `just install` 才会更新 `~/.config`。

完整安装和权限设置见 [docs/installation.md](docs/installation.md)，快捷键见 [docs/shortcuts.md](docs/shortcuts.md)。

## 关键依赖

- macOS + Homebrew；配置中的 `/opt/homebrew` 明确面向 Apple Silicon。
- Neovim 0.12+。配置使用 `vim.pack.add()`，不能在 0.11 上启动。
- 字体：`Maple Mono Normal NF CN`（Kitty/Neovide）和 `Hack Nerd Font`（SketchyBar）。
- GUI：Kitty、Neovide、Karabiner-Elements、SketchyBar；yabai 与 Glide 按需启用。
- Neovim 外部工具：`git`、`im-select`、LSP、formatter、linter 和 Tree-sitter CLI，详见 [nvim/doc/lsp_lint.md](nvim/doc/lsp_lint.md)。
- AI chat：Python 3.13、`uv`、对应 API key；AI diff hooks 仅需要 Python 3。

## 本机专属设置

以下值是有意保留的个人配置，迁移到其他机器时应检查：

- `.common_sh` 固定代理 `127.0.0.1:7897`，代理未运行时网络命令会失败。
- Claude/DeepSeek 模型和 endpoint 是个人服务约定。
- 英文输入法为 `com.apple.keylayout.Australian`，中文输入法为 Squirrel/Rime。
- Karabiner shell command 使用 `/opt/homebrew/bin`。
- AI hook 文档示例包含当前用户名路径；复制时应替换为自己的 `$HOME` 绝对路径。

## Secrets

仓库不保存密钥。`.common_sh` 会在文件存在时加载：

```bash
~/.secrets_sh
```

建议权限：

```bash
chmod 600 ~/.secrets_sh
```

常用变量包括 `DEEPSEEK_API_KEY`、`GEMINI_API_KEY`/Google GenAI 默认变量，以及本地 OpenAI 兼容代理需要的变量。不要把 `.secrets_sh`、`.env` 或真实 token 加入 Git。

## 常用维护

```bash
# 查看配置依赖
just doctor

# 运行仓库静态检查
just check

# AI diff hook 单元测试
python3 nvim/scripts/test_ai_diff_hook.py -v

# AI chat 离线测试
cd nvim/aichat_nvim && uv run python -m unittest discover -s tests -v
```

Neovim 插件由内置 `vim.pack` 管理，锁文件是 `nvim/nvim-pack-lock.json`。Tree-sitter parser 使用 `nvim/scripts/treesitter_install.sh` 安装。

## 文档索引

- [安装、依赖与 macOS 权限](docs/installation.md)
- [完整快捷键](docs/shortcuts.md)
- [本次配置审计](docs/config-audit.md)
- [Neovim 架构](nvim/README.md)
- [LSP、lint、format 与 Tree-sitter](nvim/doc/lsp_lint.md)
- [AI diff hooks](nvim/doc/ai-hooks.md)
- [AI chat 服务](nvim/aichat_nvim/README.md)

## 恢复与排障

若新配置无法启动，先从 `tmp/backups/<时间戳>/` 找到对应文件，将其复制回 HOME。常见检查顺序：

1. `just doctor` 确认命令和路径；
2. `just check` 确认仓库语法；
3. `nvim --clean` 区分 Neovim 本体与配置问题；
4. `sketchybar --reload`、`yabai --restart-service` 分别重载 GUI 服务；
5. 查看 [docs/config-audit.md](docs/config-audit.md) 中无法自动验证的 GUI/API 项目。
