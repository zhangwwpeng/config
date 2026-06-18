#!/bin/bash
# PreToolUse hook: snapshot files before Write/Edit.
# Reads hook payload from stdin:
#   { "session_id": "...", "tool_name": "Write|Edit", "tool_input": { "file_path": "...", ... } }
set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
  exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

if [[ -z "$FILE_PATH" || -z "$SESSION_ID" ]]; then
  exit 0
fi

# Resolve to absolute path
FILE_PATH=$(realpath "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")

CWD="${PWD}"

# Compute relative path from CWD. Strip CWD + trailing / prefix.
REL_PATH="${FILE_PATH#$CWD/}"
if [[ "$REL_PATH" == "$FILE_PATH" ]]; then
  # File is not under CWD — skip (don't snapshot files outside the project)
  exit 0
fi

SESSION_ROOT="${HOME}/.cache/nvim/ai-diff/sessions"
SESSION_DIR="${SESSION_ROOT}/${SESSION_ID}"
SNAPSHOT="${SESSION_DIR}/${REL_PATH}"

# Skip if snapshot already exists (first write wins)
if [[ -f "$SNAPSHOT" ]]; then
  exit 0
fi

mkdir -p "$(dirname "$SNAPSHOT")"

if [[ -f "$FILE_PATH" ]]; then
  cp "$FILE_PATH" "$SNAPSHOT"
else
  # New file — create empty snapshot
  touch "$SNAPSHOT"
fi

# Persist CWD so the Stop hook can pass it to Neovim
echo "$CWD" > "${SESSION_DIR}/.cwd"
