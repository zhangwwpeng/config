# 部署指南

本仓库是配置的唯一修改源。部署 = 用仓库内容覆盖本机目标路径，不是符号链接，也不做自动备份；回滚依赖 Git。

## 前提

- macOS（Apple Silicon）+ Homebrew。
- `rsync`、`neovim`：`brew install rsync neovim`。
- 需要 GUI 时另装：Kitty、Neovide、Karabiner-Elements、SketchyBar。
- 字体：`Maple Mono Normal NF CN`（Kitty/Neovide）、`Hack Nerd Font`（SketchyBar）。
- Neovim 0.12+，配置使用 `vim.pack.add()`，0.11 无法启动。

## 首次部署

```bash
git clone <repo> ~/workspace/config
cd ~/workspace/config
make -n install   # 先预览将执行的命令
make              # 等同 make install
```

`make install` 依次执行 `config`、`dotfiles`、`agy`、`omp`。

## 路径映射

| 仓库路径 | 目标路径 | 部署方式 |
|---|---|---|
| `bettercmdtab/` | `~/.config/bettercmdtab` | `rsync --delete` |
| `karabiner/` | `~/.config/karabiner` | `rsync --delete` |
| `kitty/` | `~/.config/kitty` | `rsync --delete` |
| `neovide/` | `~/.config/neovide` | `rsync --delete` |
| `nvim/` | `~/.config/nvim` | `rsync --delete` |
| `sketchybar/` | `~/.config/sketchybar` | `rsync --delete` |
| `.common_sh`、`.zshrc`、`.bashrc` | `~/` | `install -m 0644` |
| `agy/settings.json` | `~/.gemini/antigravity-cli/` | `install -m 0600` |
| `agy/title.sh` | `~/.gemini/antigravity-cli/` | `install -m 0755` |
| `agy/hooks.json` | `~/.gemini/config/` | `install -m 0644` |
| `omp/config.yml`、`models.yml` | `~/.omp/agent/` | `install -m 0600` |
| `omp/themes/` | `~/.omp/agent/themes/` | `rsync --delete` |
| `omp/extensions/` | `~/.omp/agent/extensions/` | `rsync --delete` |

## 分项部署

```bash
make nvim        # 只同步一个 ~/.config 目录
make kitty
make dotfiles    # 只同步 .common_sh/.zshrc/.bashrc
make agy         # Antigravity CLI 设置、标题脚本、Stop hook
make omp         # omp 模型/provider、主题、composer 扩展
```

`make nvim` 中的目录名可替换为 `bettercmdtab`、`karabiner`、`kitty`、`neovide`、`sketchybar`。

## 覆盖语义

- `config`、`omp/themes`、`omp/extensions` 使用 `rsync -a --delete`：目标目录中仓库没有的文件会被删除。
- `dotfiles`、`agy/*`、`omp/*.yml` 使用 `install`：只覆盖单个文件，不删除同目录其他内容。
- 排除项：`.git/`、`.DS_Store`、`.venv/`、`.ruff_cache/`、`.rumdl_cache/`、`__pycache__/`、`*.pyc`、`node_modules/`。
- 不会触碰工具自身的状态数据：`~/.omp/agent/*.db`、`~/.omp/logs`、agy 的 `conversations/`、`log/`、`brain/`、`cache/`。
- 部署前建议退出 agy、omp，避免运行中的进程在部署后回写设置。

## 密钥与隐私

仓库不保存密钥。`.common_sh` 只在文件存在时加载：

```bash
~/.secrets_sh
```

```bash
chmod 600 ~/.secrets_sh
```

常用变量：`DEEPSEEK_API_KEY`、`GEMINI_API_KEY`、本地 OpenAI 兼容代理需要的变量等。不要把 `.secrets_sh`、`.env`、真实 token 或带凭据的 URL 加入 Git。

提交前可做一次模式扫描：

```bash
rg -n --hidden -g '!.git' \
  '(sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{30,}|-----BEGIN [A-Z ]*PRIVATE KEY-----)' .
```

## 备份与回滚

部署不生成备份。需要保留现场时，先手动复制目标目录，或用 Git 回滚仓库：

```bash
git log --oneline
git checkout <commit> -- <path>
make <target>
```

## 新机器检查清单

- 代理：`.common_sh` 固定 `127.0.0.1:7897`，代理未启动时网络命令会失败。
- 输入法：英文 `com.apple.keylayout.Australian`，中文 Squirrel/Rime。
- 路径：Karabiner shell command 和 Homebrew 均假设 `/opt/homebrew`。
- 模型服务：`omp/models.yml` 指向 `http://127.0.0.1:3425/v1` 的 magpie 本地网关；omp/agy 的模型与 endpoint 是个人服务约定。
- Neovim 外部工具：`git`、`im-select`、LSP、formatter、linter、Tree-sitter CLI，见 [nvim/doc/lsp_lint.md](nvim/doc/lsp_lint.md)。

## 验证

```bash
make -n install                                  # 命令预览
diff -q agy/settings.json ~/.gemini/antigravity-cli/settings.json
diff -q omp/config.yml ~/.omp/agent/config.yml
nvim --version                                   # 确认 >= 0.12
bash -n sketchybar/sketchybarrc
python3 -c 'compile(open("kitty/tab_bar.py").read(), "kitty/tab_bar.py", "exec")'
```

## 故障排查

| 现象 | 处理 |
|---|---|
| `rsync: command not found` | `brew install rsync` |
| `Permission denied` 写 `~/.omp` | 检查目录属主；设置文件目标权限为 `600` |
| Neovim 启动报 `vim.pack` 不存在 | 升级到 0.12+ |
| 网络命令超时 | 启动 `127.0.0.1:7897` 代理，或临时注释 `.common_sh` 中的 proxy 行 |
| omp 设置被改回 | 退出 omp 后重新 `make omp`；运行中的实例会回写 `config.yml` |
