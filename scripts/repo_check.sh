#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

python3 -B - <<'PY'
import ast
import json
import subprocess
import tomllib
from pathlib import Path

root = Path(".")
for name in [
    "karabiner/karabiner.json",
    *Path("karabiner/assets/complex_modifications").glob("*.json"),
]:
    json.loads((root / name).read_text())
for name in [
    "neovide/config.toml",
    "glide/glide.toml",
    "nvim/.svlint.toml",
    "nvim/aichat_nvim/pyproject.toml",
]:
    tomllib.loads((root / name).read_text())
print("JSON/TOML syntax: OK")
PY

python3 -B - <<'PY'
import ast
import subprocess
from pathlib import Path

files = subprocess.check_output(["git", "ls-files", "*.py"], text=True).splitlines()
for name in files:
    ast.parse(Path(name).read_text(), filename=name)
print(f"Python syntax: OK ({len(files)} files)")
PY

nvim --clean -u NONE -i NONE --headless \
    "+lua local files=vim.fn.systemlist({'git','ls-files','*.lua'}); for _,f in ipairs(files) do assert(loadfile(f)) end; print('Lua syntax: OK (' .. #files .. ' files)')" \
    +qa!

bash -n .common_sh .bashrc nvim/scripts/*.sh sketchybar/plugins/feishu.sh
zsh -n .common_sh .zshrc nvim/scripts/treesitter_install.sh
sh -n yabai/yabairc sketchybar/sketchybarrc sketchybar/plugins/battery.sh \
    sketchybar/plugins/clock.sh sketchybar/plugins/front_app.sh \
    sketchybar/plugins/space.sh sketchybar/plugins/volume.sh

if command -v shellcheck >/dev/null 2>&1; then
    shellcheck -s bash .common_sh .bashrc .zshrc sketchybar/sketchybarrc sketchybar/plugins/feishu.sh
    shellcheck -s sh sketchybar/plugins/battery.sh
else
    printf 'shellcheck: unavailable (skipped)\n'
fi

if command -v ruff >/dev/null 2>&1; then
    ruff check --no-cache nvim/scripts nvim/aichat_nvim
else
    printf 'ruff: unavailable (skipped)\n'
fi

python3 nvim/scripts/test_ai_diff_hook.py -q

if command -v uv >/dev/null 2>&1; then
    (
        cd nvim/aichat_nvim
        UV_PROJECT_ENVIRONMENT="/tmp/aichat-nvim-uv-env" uv run --offline python -m unittest discover -s tests -q
    )
else
    printf 'uv: unavailable (skipped aichat tests)\n'
fi

git diff --check
printf 'Repository checks passed.\n'
