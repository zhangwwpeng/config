#!/bin/bash
# agy terminal title: unified static state glyph + workspace name.
# working = ●, idle = ○, other = ·
set -euo pipefail

DATA=$(cat)
STATE=$(printf '%s' "$DATA" | jq -r '.agent_state // "idle"' 2>/dev/null || echo idle)
CWD=$(printf '%s' "$DATA" | jq -r '.workspace.current_dir // ""' 2>/dev/null || echo "")
NAME=$(basename "${CWD:-unknown}")

case "$STATE" in
  idle)  GLYPH="○" ;;
  working|tool_use|reviewing|authenticating|initializing) GLYPH="●" ;;
  *)     GLYPH="·" ;;
esac

printf '%s %s\n' "$GLYPH" "$NAME"
