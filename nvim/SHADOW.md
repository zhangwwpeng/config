# Shadow Directory — Claude Code 文件修改追踪系统

## 目标

每次 Claude Code 通过 Write/Edit 工具修改文件时，自动在 `shadow/` 目录中镜像一份，并 Git commit。这样你可以：

- 查看 Claude 做了哪些修改（`git log`）
- 对比每次修改的 diff（`git show`）
- 撤销任意文件到任意版本（从 shadow 复制回真实位置）
- 完全回退某次会话的所有改动

## 架构

```
~/.config/nvim/
├── lua/                    # 真实代码（Claude 直接修改这里）
├── shadow/                 # Git 仓库（自动镜像，只增不改）
│   └── .git/               #   每次 Write/Edit → 自动 commit
├── .claude/
│   ├── hooks/
│   │   └── shadow-mirror.sh   # PostToolUse hook 脚本
│   └── settings.json          # hook 配置
```

### 数据流

```
Claude Write/Edit 工具调用
        │
        ▼
   真实文件被修改
        │
        ▼
PostToolUse hook 触发
        │
        ▼
shadow-mirror.sh 收到 JSON（含 tool_name + file_path）
        │
        ▼
   cp 真实文件 → shadow/<相对路径>
   git -C shadow/ add -A
   git -C shadow/ commit -m "Claude <ToolName>: <相对路径>"
```

## 文件详解

### 1. `shadow/` — Git 仓库

```
shadow/
├── .git/                  # 独立的 Git 仓库
├── .gitignore             # 仓库自身的 gitignore
├── lua/                   # 镜像的项目文件结构
│   ├── config.lua
│   ├── keymaps.lua
│   └── ...
├── init.lua
└── ...
```

- 初始化时包含整个项目树的 baseline 快照（commit: `Baseline: full project snapshot before Claude modifications`）
- 之后每次 Claude Write/Edit 自动追加一个 commit
- 与主项目完全隔离，不影响真实代码

### 2. `.claude/hooks/shadow-mirror.sh` — Hook 脚本

```bash
#!/bin/bash
set -euo pipefail

# 1. 从 stdin 读取 JSON，提取 tool_name 和 file_path
TOOL_NAME=$(jq -r '.tool_name // empty')
FILE_PATH=$(jq -r '.tool_input.file_path // empty')

# 2. 跳过无效调用（无文件路径、项目外文件）
# 3. 计算相对路径，在 shadow 中创建对应目录
# 4. cp 文件到 shadow（如果文件存在）
# 5. git add -A && git commit
```

- 每次 Write/Edit 后由 Claude Code 自动调用
- 通过 stdin 接收完整的 tool 调用 JSON
- 只处理项目内的文件（`$CLAUDE_PROJECT_DIR` 前缀匹配）
- 幂等：shadow 仓库不存在时自动 `git init`
- 超时 30 秒，失败不阻塞 Claude

### 3. `.claude/settings.json` — Hook 配置

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{
          "type": "command",
          "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/shadow-mirror.sh",
          "timeout": 30
        }]
      }
    ]
  }
}
```

- `matcher: "Write|Edit"` — 只匹配这两种工具调用
- `PostToolUse` — 在工具执行**成功后**触发（此时文件已写入磁盘）
- `${CLAUDE_PROJECT_DIR}` — Claude Code 自动替换为项目根目录

## 日常使用

### 查看 Claude 改了什么

```bash
cd ~/.config/nvim/shadow

# 看所有修改记录
git log --oneline

# 输出示例：
# f3a4d98 Claude Write: lua/config.lua
# 03af48b Claude Edit: lua/keymaps.lua
# b0d3f75 Claude Write: lua/theme.lua
# 6868b8c Baseline: full project snapshot before Claude modifications
```

### 对比每次修改的 diff

```bash
# 看最近一次修改的 diff
git show HEAD

# 看某个文件从 baseline 以来的所有改动
git log -p -- lua/config.lua
```

### 撤销某个文件

```bash
# 恢复到 baseline 版本（Claude 改动之前）
git show 6868b8c:lua/config.lua > ../lua/config.lua

# 恢复到某个中间版本
git show b0d3f75:lua/config.lua > ../lua/config.lua
```

### 撤销整个项目

```bash
# 从 shadow 的 baseline commit 恢复所有文件
cd ~/.config/nvim/shadow
git checkout 6868b8c -- .
cp -r lua/ ../lua/
cp init.lua ../init.lua
# ... 其他顶层文件
```

### 确认 Claude 改动无误后

真实文件已经包含改动，**不需要额外操作**。Shadow 只是安全网，不影响正常流程。

## 限制

| 限制 | 说明 |
|------|------|
| Bash 写入不追踪 | `sed -i`、`> file`、`git checkout` 等通过 Bash 工具修改的文件不会触发 hook |
| 需重启 Claude Code | settings.json 在新 session 才会加载，当前 session 不改动 |
| 不追踪文件删除 | 如果 Claude 删除了文件，shadow 会保留最后一份副本（不会自动删除） |
| 大文件性能 | 每次 commit 约 100-300ms，批量写很多文件时会有累积延迟 |

## 扩展：全局启用

如果想让所有项目都用这个功能，把 `~/.config/nvim/.claude/settings.json` 中的 hooks 配置复制到 `~/.claude/settings.json`，并把脚本路径改为绝对路径：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{
          "type": "command",
          "command": "/Users/wpzhang/.config/nvim/.claude/hooks/shadow-mirror.sh",
          "timeout": 30
        }]
      }
    ]
  }
}
```
