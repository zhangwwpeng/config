source ~/.common_sh
PROMPT="%F{cyan}%1~ > %f"

# Ctrl-R: fzf history search (falls back to default if fzf not found)
if command -v fzf >/dev/null 2>&1; then
    fzf-history-widget() {
        local selected
        selected=$(__fzf_history_select "$LBUFFER")
        if [[ -n "$selected" ]]; then
            LBUFFER="$selected"
        fi
        zle reset-prompt
    }
    zle -N fzf-history-widget
    bindkey '^R' fzf-history-widget
fi
