M = {}

function M.setup()
    vim.keymap.set({ "n", "v" }, "<leader>d", "<cmd>DeltaView<cr>", { desc = "Toggle focus_windows tab" })
    require("deltaview").setup({
        -- disable nerd font icons if uninstalled (defaults to true)
        use_nerdfonts = false,

        -- will show the delta style line numbers in the statuscolumn.
        line_numbers = false,

        -- override the picker for :DeltaMenu. If nil, auto-detects in order:
        -- fzf-lua -> telescope -> vim.ui.select
        fzf_picker = nil, -- 'fzf-lua' | 'telescope' | 'ui_select' | nil

        -- custom keybindings
        keyconfig = {
            -- global keybind to toggle DeltaMenu
            dm_toggle_keybind = "<leader>xm",

            -- global keybind to toggle DeltaView (and exit diff if open)
            dv_toggle_keybind = "<leader>xl",

            -- global keybind to toggle Delta (and exit diff if open)
            d_toggle_keybind = "<leader>xa",

            -- navigate between hunks in a diff
            next_hunk = "<Tab>",
            prev_hunk = "<S-Tab>",

            -- open help legend
            help_legend = "d?",
        },
    })

    -- for configuration of how the diff buffers look
    require("delta").setup({
        -- default lines of context around each hunk.
        context = 3,

        highlighting = {
            -- minimum Levenshtein similarity (0.0–1.0) for two lines to be
            -- paired for word-level highlighting. The lower the number, the
            -- less similar two lines have to be to get word level
            -- highlighting. Matches delta's --max-line-distance option.
            max_similarity_threshold = 0.6,
        },
    })
end

return M
