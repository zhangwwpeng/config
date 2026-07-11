# aichat_nvim

Neovim AI chat 的 Python RPC 服务。Neovim 通过 msgpack-rpc 连接 `127.0.0.1:6666`，把 `chat.md` 中的提问流式写回 buffer。

## 目录结构

```text
~/.local/aichat/
├── system.txt                 # 全局 system prompt
└── session/
    └── <name>/
        ├── chat.md            # 对话正文
        └── summary.txt        # 自动摘要（供后续轮次使用）
```

服务启动时会自动创建 `ROOT`、`session/` 和空的 `system.txt`。

## 启动

```bash
cd ~/.config/nvim/aichat_nvim
uv sync
uv run python main.py
```

服务只监听 loopback，没有鉴权；不要把监听地址改成 `0.0.0.0`。

## RPC 操作

| op | message / 参数 | 说明 |
|---|---|---|
| `get_session` | — | 返回 `~/.local/aichat/session/` 下已有 session 的绝对路径列表 |
| `create_session` | session 名 | 创建 `session/<name>/`，并初始化 `chat.md`、`summary.txt` |
| `sub_ai` | session 名 | 读取对应 `chat.md`，调用模型并把回答流式写入 Neovim buffer |

`sub_ai` 还需要 `nvim_header`（父 Neovim 的 servername）和 `buf`（目标 buffer id）。

## Session 名规则

允许字母、数字、中文、空格以及 `._-`。拒绝：

- 空名、`.`、`..`
- 路径分隔符、绝对路径
- 首尾空格
- 解析后落在 `ROOT` 之外的符号链接

## 模型映射

在 `chat.md` 最后一轮提问行末尾写模型别名，例如：

```markdown
# Ask CHATGPT
解释一下这段代码
```

Neovim 里可用 `<C-a>` 在 AI chat buffer 中轮换 `DEEPSEEK` / `CHATGPT` / `GEMINI`。

| 别名 | 提供商 | 实际模型 | 说明 |
|---|---|---|---|
| `DEEPSEEK` | DeepSeek API | `deepseek-v4-pro` | 需要 `DEEPSEEK_API_KEY` |
| `CHATGPT` | 本地 OpenAI 兼容代理 | `[pro]gpt-5.5` | 默认 `http://127.0.0.1:15721` |
| `GEMINI` | Google GenAI | `gemini-3.1-pro` | 需要 `GEMINI_API_KEY` 或 SDK 默认凭据 |

摘要更新固定走 DeepSeek 的 `deepseek-chat`，与上面主对话模型无关。

## 错误处理

- 空问题、未知模型、非法 session 名会返回 `ERROR: ...`
- 无法连接 Neovim buffer 或 API 失败时，错误会写入 buffer 或 RPC 返回值，不会拖垮服务进程
- 摘要失败时主回答仍会完成，并返回 `WARNING: answer completed but summary update failed: ...`

## 测试

离线单元测试（不访问真实 API）：

```bash
cd ~/.config/nvim/aichat_nvim
uv run python -m unittest discover -s tests -v
```

手动 smoke 脚本在 `examples/` 下，需要显式运行且会联网：

```bash
uv run python examples/openai_smoke.py
uv run python examples/gemini_smoke.py
uv run python examples/deepseek_smoke.py
```

## Neovim 快捷键

| 键 | 作用 |
|---|---|
| `<leader>aa` | 创建 session |
| `<leader>s` | 选择并打开 session |
| `P` | 在 AI chat buffer 中提交当前内容 |
| `<C-a>` | 轮换 DeepSeek / ChatGPT / Gemini |
