#!/bin/bash
# Stop hook: notify Neovim if any snapshots were created during this session.
# Reads hook payload from stdin: { "session_id": "...", ... }
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

if [[ -z "$SESSION_ID" ]]; then
  exit 0
fi

SESSION_ROOT="${HOME}/.cache/nvim/ai-diff/sessions"
SESSION_DIR="${SESSION_ROOT}/${SESSION_ID}"

# No session dir = no writes happened
if [[ ! -d "$SESSION_DIR" ]]; then
  exit 0
fi

# Count actual snapshot files (exclude .cwd marker)
SNAPSHOT_COUNT=$(find "$SESSION_DIR" -type f ! -name '.cwd' 2>/dev/null | wc -l | tr -d ' ')
if [[ "$SNAPSHOT_COUNT" -eq 0 ]]; then
  rm -rf "$SESSION_DIR"
  exit 0
fi

CWD=$(cat "${SESSION_DIR}/.cwd" 2>/dev/null || echo "$PWD")
rm -f "${SESSION_DIR}/.cwd"

# Notify Neovim via --remote-send
if [[ -n "${NVIM_PIP_FATHER:-}" ]]; then
  nvim --server "$NVIM_PIP_FATHER" --remote-send "<Cmd>AiDiff ${SESSION_ID} ${CWD}<CR>" 2>/dev/null || true
fi
