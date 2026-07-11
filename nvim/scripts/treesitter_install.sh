#!/usr/bin/env bash
set -euo pipefail

target="${HOME}/.local/share/nvim/site/parser"
mkdir -p -- "$target"

tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/nvim-treesitter.XXXXXX")"
cleanup() {
    rm -rf -- "$tmpdir"
}
trap cleanup EXIT

build_parser() {
    local name="$1"
    local repository="$2"
    local ref="${3-}"
    local source_dir="${tmpdir}/${name}"
    local output="${tmpdir}/${name}.so"
    local clone_args=(--depth 1)

    if [[ -n "$ref" ]]; then
        clone_args+=(--branch "$ref")
    fi

    git clone "${clone_args[@]}" "$repository" "$source_dir"
    (
        cd "$source_dir"
        tree-sitter build -o "$output"
    )
    install -m 0644 "$output" "${target}/${name}.so"
}

# Python stays pinned because newer parser versions have incompatible queries.
build_parser python https://github.com/tree-sitter/tree-sitter-python v0.25.0
build_parser bash https://github.com/tree-sitter/tree-sitter-bash
build_parser json https://github.com/tree-sitter/tree-sitter-json
build_parser yaml https://github.com/tree-sitter-grammars/tree-sitter-yaml
build_parser toml https://github.com/tree-sitter-grammars/tree-sitter-toml
build_parser rust https://github.com/tree-sitter/tree-sitter-rust
build_parser tcl https://github.com/tree-sitter-grammars/tree-sitter-tcl
build_parser systemverilog https://github.com/gmlarumbe/tree-sitter-systemverilog
build_parser just https://github.com/casey/tree-sitter-just
build_parser make https://github.com/tree-sitter-grammars/tree-sitter-make

