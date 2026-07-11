# shellcheck source=/dev/null
source ~/.common_sh
PS1='\[\e[36m\]\W > \[\e[0m\]'

# Ctrl-R: fzf history search (falls back to default if fzf not found)
if command -v fzf >/dev/null 2>&1; then
    __fzf_history() {
        local line
        line=$(__fzf_history_select)
        READLINE_LINE="${line}"
        READLINE_POINT=${#line}
    }
    bind -x '"\C-r": __fzf_history'
fi
