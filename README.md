# macOS 开发环境配置

这是一套面向 macOS（主要是 Apple Silicon）的个人配置，覆盖 Shell、Neovim、终端、键盘重映射、状态栏和窗口管理。仓库是唯一的修改源，用 `make` 覆盖部署到 `~/.config` 和 `~/`；不会自动安装 Homebrew 软件或修改系统权限。

## 配置组成

| 路径 | 部署位置 | 用途 |
|---|---|---|
| `.common_sh`、`.zshrc`、`.bashrc` | `~/` | 公共环境变量、alias、fzf 历史和 Neovim 远程 wrapper |
| `nvim/` | `~/.config/nvim` | Neovim 0.12、LSP、lint、format、RPC 子终端、AI diff/chat |
| `kitty/` | `~/.config/kitty` | Kitty、主题、tab bar、quick-access terminal |
| `neovide/` | `~/.config/neovide` | Neovide 窗口和字体 |
| `karabiner/` | `~/.config/karabiner` | 全局按键重映射和应用快捷键 |
| `sketchybar/` | `~/.config/sketchybar` | Space、前台应用、时间、电池和消息角标 |
| `bettercmdtab/` | `~/.config/bettercmdtab` | Cmd+Tab 应用切换器 |

`karabiner/automatic_backups/` 是历史备份，不参与日常配置审计。`nvim/queries/` 是随 Tree-sitter parser 配套的 query，原则上按上游版本整体更新。

## 部署

```bash
brew install rsync neovim
make            # 等同 make install：同步所有配置目录和 dotfiles
make nvim       # 只同步单个目录（bettercmdtab/karabiner/kitty/neovide/nvim/sketchybar）
make dotfiles   # 只同步 .common_sh/.zshrc/.bashrc
make -n install # 预览命令
```

部署是 `rsync --delete` 复制（不是符号链接），以仓库为准：目标目录里仓库没有的文件会被删除（`.git`、缓存等已排除）。不做备份，回滚请用 git。

## 关键依赖

- macOS + Homebrew；配置中的 `/opt/homebrew` 明确面向 Apple Silicon。
- Neovim 0.12+。配置使用 `vim.pack.add()`，不能在 0.11 上启动。
- 字体：`Maple Mono Normal NF CN`（Kitty/Neovide）和 `Hack Nerd Font`（SketchyBar）。
- GUI：Kitty、Neovide、Karabiner-Elements、SketchyBar。
- Neovim 外部工具：`git`、`im-select`、LSP、formatter、linter 和 Tree-sitter CLI，详见 [nvim/doc/lsp_lint.md](nvim/doc/lsp_lint.md)。

## 本机专属设置

以下值是有意保留的个人配置，迁移到其他机器时应检查：

- `.common_sh` 固定代理 `127.0.0.1:7897`，代理未运行时网络命令会失败。
- Claude/DeepSeek 模型和 endpoint 是个人服务约定。
- 英文输入法为 `com.apple.keylayout.Australian`，中文输入法为 Squirrel/Rime。
- Karabiner shell command 使用 `/opt/homebrew/bin`。

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

## 文档索引

- [Neovim 架构](nvim/README.md)
- [LSP、lint、format 与 Tree-sitter](nvim/doc/lsp_lint.md)
