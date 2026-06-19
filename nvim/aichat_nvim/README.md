###### aichat-nvim

Neovim AI chat plugin — runs an msgpack-rpc server that handles requests from Neovim.

## OpCodes

| Op | Message | Description |
|---|---|---|
| `get_session` | — | Return full full path names under `~/.local/aichat/session/` |
| `create_session` | folder name | Create a new directory under `~/.local/aichat/session/` |
| `sub_ai` | session | 根据session 去查ai_chat 目录下，是否有该目录，如果有就返回ok |

