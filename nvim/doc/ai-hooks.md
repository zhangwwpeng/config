# AI Hook 配置指南

本文说明如何为 **Claude Code**、**Codex CLI** 手动添加 ai-diff hook。
会话快照统一保存在 `~/.cache/nvim/ai-diff/sessions/`。

## 整体流程

```
Session 开始
    │
    ▼
SessionStart hook → 创建 session/old/new/
    │
    ▼
PreToolUse hook（Write/Edit/MultiEdit/Delete/apply_patch）
    │  查 change.json，新路径则记录 A/M/D 如果路径已存在,那就不复制
    │  M/D 时复制原文件到 old/
    ▼
AI 执行写/删
    │
    ▼
Stop hook
    │  把 M/A 的当前工作区文件复制到 new/
    │  通知 Neovim: CodeDiff dir old/ new/
    ▼
用户在 Neovim 中比较 old vs new
    │
    ▼
关闭 diff 视图后
    │  把 new/ 全部同步到工作区
    │  并按 change.json 处理 D（删除工作区同名文件）
    ▼
通知 shell 继续（/tmp/aidiff_<session_id>）
```

## Session 目录结构

```
~/.cache/nvim/ai-diff/sessions/<session_id>/
├── old/              # 修改/删除前的快照
├── new/              # Stop 时从工作区复制的修改后版本（仅 M/A）
├── change.json       # {"相对路径": "M" | "A" | "D"}
└── .cwd              # 项目根目录
```

### change.json 规则

| 值 | 含义 | PreToolUse | Stop 时 new/ |
|----|------|------------|--------------|
| `M` | 修改已有文件 | 复制原文件到 `old/` | 复制当前工作区文件到 `new/` |
| `A` | 新建文件 | 只写 change.json | 复制当前工作区文件到 `new/` |
| `D` | 删除文件 | 复制原文件到 `old/` | 不复制（new/ 无此文件） |

同一 session 内，同一路径**只记录第一次**操作。

实现细节：

- 兼容 `session_id` / `sessionId`
- 兼容 `cwd` / `workspace_path` / `workspacePath` 等目录字段
- 兼容 `tool_name` 与 `tool_input`
- 对相对路径统一按 payload 的 `cwd` 解析，避免用户级 hook 在非项目目录运行时记录失败

## 依赖脚本

| 脚本 | 作用 |
|------|------|
| `nvim_term_remote.py` | 子终端内 `vim` / `vimdiff` → 子 Neovim（`vimdiff` 支持文件与目录） |
| `ai_diff_lib.py` | 公共逻辑 |
| `ai-diff-session-start.py` | SessionStart |
| `ai-diff-hook.py` | PreToolUse（Write/Edit/MultiEdit/Delete/apply_patch） |
| `ai-diff-stop.py` | Stop：填充 new/、通知 Neovim、等待同步完成 |
| `lua/aidiff.lua` | Neovim `:AiDiff`：目录对比 + 关闭后同步 |

---

## Hook 配置

> 如果你希望“同一客户端只用一个固定目录”，可以在命令前加环境变量：
> - Claude: `AI_DIFF_FIXED_SESSION=claude`
> - Codex: `AI_DIFF_FIXED_SESSION=codex`
>
> 这样目录会固定为：
> `~/.cache/nvim/ai-diff/sessions/claude`（或 `codex`），不再按每次对话 ID 变化。
> 同时 `SessionStart` 会重建该目录，避免残留上一次会话的 `change.json`。

### Claude Code — `~/.claude/settings.json`

```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "AI_DIFF_FIXED_SESSION=claude python3 /Users/wpzhang/.config/nvim/scripts/ai-diff-session-start.py",
        "timeout": 10
      }]
    }],
    "PreToolUse": [{
      "matcher": "Write|Edit|MultiEdit|Delete|apply_patch",
      "hooks": [{
        "type": "command",
        "command": "AI_DIFF_FIXED_SESSION=claude python3 /Users/wpzhang/.config/nvim/scripts/ai-diff-hook.py",
        "timeout": 10
      }]
    }],
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "AI_DIFF_FIXED_SESSION=claude python3 /Users/wpzhang/.config/nvim/scripts/ai-diff-stop.py",
        "timeout": 10
      }]
    }]
  }
}
```

### Codex CLI — `~/.codex/hooks.json`

```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "AI_DIFF_FIXED_SESSION=codex python3 /Users/wpzhang/.config/nvim/scripts/ai-diff-session-start.py",
        "timeout": 10
      }]
    }],
    "PreToolUse": [{
      "matcher": "Write|Edit|MultiEdit|Delete|apply_patch",
      "hooks": [{
        "type": "command",
        "command": "AI_DIFF_FIXED_SESSION=codex python3 /Users/wpzhang/.config/nvim/scripts/ai-diff-hook.py",
        "timeout": 10
      }]
    }],
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "AI_DIFF_FIXED_SESSION=codex python3 /Users/wpzhang/.config/nvim/scripts/ai-diff-stop.py",
        "timeout": 10
      }]
    }]
  }
}
```

---

## 测试

```bash
python3 ~/.config/nvim/scripts/test_ai_diff_hook.py -v
```

手动模拟删除 + Stop 填充 new/：

```bash
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"
echo "old content" > foo.txt

# SessionStart
echo "{\"session_id\":\"manual\",\"cwd\":\"$TEST_DIR\"}" \
  | python3 ~/.config/nvim/scripts/ai-diff-session-start.py

# 记录删除
echo "{\"tool_name\":\"Delete\",\"session_id\":\"manual\",\"cwd\":\"$TEST_DIR\",\"tool_input\":{\"path\":\"$TEST_DIR/foo.txt\"}}" \
  | python3 ~/.config/nvim/scripts/ai-diff-hook.py

rm -f foo.txt   # 模拟 AI 删除

# 查看
cat ~/.cache/nvim/ai-diff/sessions/manual/change.json
cat ~/.cache/nvim/ai-diff/sessions/manual/old/foo.txt

rm -rf "$TEST_DIR" ~/.cache/nvim/ai-diff/sessions/manual
```

---

## Neovim 同步逻辑（`lua/aidiff.lua`）

1. `:AiDiff <session_id> <cwd>` 打开 `CodeDiff dir old/ new/`
2. 用户关闭 diff 标签页后触发同步：
   - 递归复制 `new/` → 工作区
   - 对 `change.json` 中 `D` 的条目删除工作区对应文件
3. 创建 `/tmp/aidiff_<session_id>` 通知 Stop hook 继续

---

## 前置条件

- Python 3
- Neovim + codediff.nvim（或子终端内用 `vimdiff old/ new/` 手动比较）
- AI 从 remote terminal 启动（设置 `NVIM_PIP_FATHER`）
- `~/.common_sh` 中 `nvim_wrapper` / `vimdiff_wrapper` 指向 `scripts/nvim_term_remote.py`（见 [README.md](../README.md)）

## 常见问题

- Hook 进程当前目录不一定是项目目录（尤其用户级 hook），不要依赖 `os.getcwd()` 解析相对路径。
- 当前实现会优先使用 payload 里的 `cwd/workspace_path/workspacePath` 解析路径；若这些字段为空，才回退到进程当前目录。
