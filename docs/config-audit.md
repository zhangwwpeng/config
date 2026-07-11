# 配置审计报告

审计日期：2026-07-11  
平台：macOS 26.5，Apple Silicon Homebrew 路径  
范围：仓库 186 个 Git 跟踪文件中的当前生效配置和自研脚本

## 范围说明

逐项检查：

- 根目录 Shell、Justfile 与 ignore 规则；
- Kitty、Neovide、Karabiner、SketchyBar、yabai、Glide；
- Neovim 启动入口、Lua 模块、LSP、lint、format、Tree-sitter、RPC 子终端；
- AI diff Python hooks；
- `aichat_nvim` Python RPC 服务；
- 现有 README 和 `nvim/doc/`。

没有逐行审查：

- `.git/`；
- `nvim/aichat_nvim/.venv/`、`.ruff_cache/`、`__pycache__/`；
- Karabiner `automatic_backups/` 历史文件；
- 上游 Tree-sitter query 的语义正确性；
- `uv.lock` 中第三方包源码。

这些内容仍检查了“是否误部署、是否被错误引用、是否与文档冲突”。

## 已确认并修复的问题

### 高影响

1. 安装器漏掉 `.common_sh` 和 SketchyBar，但 `.zshrc`/`.bashrc` 启动时强制加载 `.common_sh`。
2. 安装器用 `cp -r` 复制整个 Neovim 工作树，会把嵌套 `.git`、`.venv` 和缓存一起部署；所有备份、删除和复制错误还被 `-` 静默忽略。
3. `.common_sh` 调用不存在的 `~/.config/nvim/nvim_term_remote.py`；真实文件在 `scripts/` 下。
4. `nvim_term_remote.py` 使用 `os.system` 拼接 RPC 地址和文件路径，空格会破坏命令，特殊字符可注入 shell/Ex 命令。
5. `init.lua` 的 `:AiDiff` 扫描错误目录，并在 Stop hook 只传 session ID 时拼接空 `cwd_path`；新增和删除也无法完整进入比较。
6. AI diff session ID 未校验，可通过绝对路径或 `..` 逃逸 cache 根目录；SessionStart 中的递归删除放大了风险。
7. AI chat 的代码使用 `~/.local/aichat/<name>`，README 和 system prompt 逻辑却假设 `~/.local/aichat/session/<name>`，会读错 `system.txt`。
8. AI chat session 名未限制，RPC 调用可越界创建目录和文件。
9. 三个名为 `test_*.py` 的 AI provider 脚本在测试发现时会直接访问真实网络和 API。

### 功能错误

1. Neovim 文档声明 0.11+，实际使用 0.12 才提供的 `vim.pack.add()`。
2. `<leader>0` 文档说显示当前行诊断，代码却始终显示硬编码示例。
3. SystemVerilog 在 conform 判断“无需修改”后不会运行补充 Tree-sitter formatter。
4. SystemVerilog 保存时通过 `linters_by_ft` 和显式调用重复运行 `svlint`。
5. Python LSP 把路径中任意名为 `lib` 的项目目录当成标准库并跳过。
6. SketchyBar 主配置使用 Bash 数组但没有 shebang；Space 订阅绑定到了不存在的 `space` 项，而不是 `space.N`。
7. 电池脚本在 BSD grep 下使用不支持的 `\d`，并在 `/bin/sh` 中使用非 POSIX `[[`。
8. 飞书脚本注释说无消息隐藏，实际强制显示 `(0)`；每 10 秒刷新一次，却单次阻塞约 9.6 秒。
9. Karabiner Caps Lock 描述包含 Ctrl，但实际只发送 Shift+Option。
10. `TOOLS_BIN` 未定义时，原 PATH 拼接会产生空路径段，可能把当前目录加入命令搜索。
11. `EDITOR=nvim_wrapper` 指向只存在于交互 shell 的函数，外部程序启动 editor 时可能找不到命令。

### 文档与仓库卫生

1. 根 README 只有快捷键，没有安装、依赖、恢复、Secrets、服务启动和验证说明。
2. Neovim README 引用不存在的 `SHADOW.md`、`CLAUDE.md`。
3. 补全文档写 `<C-y>` 接受，实际 `preset=none` 且接受键为 Enter。
4. snippet 注释写 `<C-l>/<C-h>`，实际仅映射 `<C-;>`。
5. AI diff 文档同时描述旧 Shell hooks、失效内联命令和未实现的等待信号。
6. `nvim/scripts/.test_run.log` 是失败日志却被 Git 跟踪。
7. `tressiter` 文件名长期拼写错误，安装脚本在当前目录 clone 并在失败后继续执行。

## 有意保留的耦合

以下不是通用 dotfiles 设计，但符合当前个人环境，因此仅记录和检查，不自动抽象：

- `/opt/homebrew`；
- 本地代理端口 7897；
- Australian 英文键盘与 Squirrel/Rime；
- DeepSeek/Claude 模型别名和本地 OpenAI 兼容 endpoint；
- Kitty/Neovide/SketchyBar 字体名称；
- Neovim `vim._core.ui2` 和 `indent.lua` FFI 内部接口；
- yabai 只做 Space focus、Glide 做可选平铺的组合。

其中 Neovim 内部 API 是升级风险：每次升级 Neovim 都应运行 headless smoke test，并实际打开一次消息 UI、缩进线和 RPC 子终端。

## 验证结果

实现前已确认：

- JSON、TOML 全部可解析；
- 13 个 Python 文件可通过 AST 解析；
- 44 个 Lua 文件可由 Neovim `loadfile()` 编译；
- Shell 基础语法和 Justfile 可解析；
- 本机 Neovim 为 0.12.3，存在 `vim.pack.add` 和 `vim.lsp.enable`。

实现后验证包括：

- `just check` 全仓静态检查；
- ShellCheck 与 Ruff；
- AI diff、AI chat 离线单元测试；
- 临时 HOME/XDG 下的安装器测试；
- Neovim headless 启动和关键模块 smoke test。

最终命令和环境限制见 [installation.md](installation.md)。

## 无法完全自动验证

以下项目需要人工 smoke test：

1. Karabiner EventViewer 中的真实键盘布局和全局快捷键；
2. SketchyBar 的图标字体、Space 选择状态和飞书/企业微信真实角标；
3. yabai/Glide 在当前 macOS 权限、SIP 和多显示器环境下的行为；
4. Kitty quick-access terminal 的系统 Service 注册；
5. Neovide 输入法、透明度和显示器缩放；
6. DeepSeek、Gemini、本地代理的真实模型名称、鉴权、额度和流式响应。
