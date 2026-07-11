set shell := ["bash", "-euo", "pipefail", "-c"]

# Back up the current configuration, then deploy clean copies from this repo.
install:
    #!/usr/bin/env bash
    set -euo pipefail
    command -v rsync >/dev/null
    backup_dir="{{justfile_directory()}}/tmp/backups/$(date '+%Y%m%d-%H%M%S')"
    mkdir -p "$backup_dir"
    for entry in kitty nvim neovide karabiner yabai sketchybar glide; do
        just --justfile "{{justfile_directory()}}/Justfile" _backup_and_copy_config "$entry" "$entry" "$backup_dir"
    done
    for entry in .common_sh .zshrc .bashrc; do
        just --justfile "{{justfile_directory()}}/Justfile" _backup_and_copy_dotfile "$entry" "$backup_dir"
    done
    printf 'Configuration installed. Backup: %s\n' "$backup_dir"

# Check host-side dependencies without changing the machine.
doctor:
    #!/usr/bin/env bash
    set -uo pipefail
    required=(git rsync nvim python3)
    optional=(just kitty kitten neovide sketchybar yabai glide im-select fzf ruff shellcheck stylua shfmt jq yamlfmt taplo svlint verilator verible-verilog-format slang-server)
    missing=0
    printf 'Required commands:\n'
    for cmd in "${required[@]}"; do
        if path="$(type -P "$cmd")"; then
            printf '  [ok]      %-24s %s\n' "$cmd" "$path"
        else
            printf '  [missing] %s\n' "$cmd"
            missing=1
        fi
    done
    printf 'Optional commands:\n'
    for cmd in "${optional[@]}"; do
        if path="$(type -P "$cmd")"; then
            printf '  [ok]      %-24s %s\n' "$cmd" "$path"
        else
            printf '  [optional] %s\n' "$cmd"
        fi
    done
    if [[ "$(uname -s)" != Darwin ]]; then
        printf '  [warning] These desktop settings target macOS.\n'
    fi
    exit "$missing"

_backup_and_copy_config name dest backup_dir:
    #!/usr/bin/env bash
    set -euo pipefail
    source_dir="{{justfile_directory()}}/{{name}}"
    target_dir="${HOME}/.config/{{dest}}"
    staging_dir="${HOME}/.config/.{{dest}}.staging.$$"
    backup_target="{{backup_dir}}/.config/{{name}}"
    [[ -d "$source_dir" ]] || { printf 'Missing source: %s\n' "$source_dir" >&2; exit 1; }
    mkdir -p "${HOME}/.config" "$(dirname "$backup_target")"
    if [[ -e "$target_dir" || -L "$target_dir" ]]; then
        rsync -a "$target_dir" "$backup_target"
    fi
    rm -rf "$staging_dir"
    trap 'rm -rf "$staging_dir"' EXIT
    mkdir -p "$staging_dir"
    rsync -a \
        --exclude '.git/' \
        --exclude '.venv/' \
        --exclude '.ruff_cache/' \
        --exclude '__pycache__/' \
        --exclude '*.pyc' \
        --exclude 'scripts/.test_run.log' \
        "$source_dir/" "$staging_dir/"
    rm -rf "$target_dir"
    mv "$staging_dir" "$target_dir"
    trap - EXIT
    printf 'Installed %s -> %s\n' "{{name}}" "$target_dir"

_backup_and_copy_dotfile name backup_dir:
    #!/usr/bin/env bash
    set -euo pipefail
    source_file="{{justfile_directory()}}/{{name}}"
    target_file="${HOME}/{{name}}"
    staging_file="${HOME}/.{{name}}.staging.$$"
    [[ -f "$source_file" ]] || { printf 'Missing source: %s\n' "$source_file" >&2; exit 1; }
    if [[ -e "$target_file" || -L "$target_file" ]]; then
        mkdir -p "{{backup_dir}}"
        cp -a "$target_file" "{{backup_dir}}/{{name}}"
    fi
    trap 'rm -f "$staging_file"' EXIT
    install -m 0644 "$source_file" "$staging_file"
    mv -f "$staging_file" "$target_file"
    trap - EXIT
    printf 'Installed %s -> %s\n' "{{name}}" "$target_file"
