# shellcheck source=/dev/null
source ~/.common_sh

# Force emacs keybindings everywhere (including vim terminals)
bindkey -e
# bindkey '^P' up-line-or-history
# bindkey '^N' down-line-or-history
# bindkey '^A' beginning-of-line
# bindkey '^E' end-of-line
# shellcheck disable=SC2034
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
