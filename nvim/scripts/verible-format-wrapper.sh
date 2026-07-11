#!/usr/bin/env bash
set -u

err_file="$(mktemp -t verible-format-stderr.XXXXXX)"
cleanup() {
    rm -f "$err_file"
}
trap cleanup EXIT

verible-verilog-format "$@" 2>"$err_file"
status=$?

if [ "$status" -ne 0 ]; then
    cat "$err_file" >&2
    exit "$status"
fi

if [ -s "$err_file" ]; then
    cat "$err_file" >&2
    exit 1
fi

exit 0
