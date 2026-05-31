------------------------------------------------------------------------
-- Plugin config
------------------------------------------------------------------------
require("indent").setup()
require("edit")
require("imselect").setup()
require("delta").setup({})
require("oil").setup()
require("terminal")

require("snacks").setup({
    bigfile = { enabled = true },
    quickfile = { enabled = true },
    notifier = {
        enabled = true,
        style = "minimal",
        width = { min = 0, max = 0.4 },
    },
    picker = {
        enabled = true,
        layout = "ivy",
        layouts = {
            ivy = {
                layout = {
                    box = "vertical",
                    backdrop = true,
                    row = -1,
                    width = 0,
                    height = 0.8,
                    border = "top",
                    title = " {title} {live} {flags}",
                    title_pos = "left",
                    { win = "input", height = 1, border = "bottom" },
                    {
                        box = "horizontal",
                        { win = "list", border = "none" },
                        { win = "preview", title = "{preview}", width = 0.6, border = "left" },
                    },
                },
            },
        },
    },
})

require("blink.cmp").setup({
    -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
    -- 'super-tab' for mappings similar to vscode (tab to accept)
    -- 'enter' for enter to accept
    -- 'none' for no mappings
    --
    -- All presets have the following mappings:
    -- C-space: Open menu or open docs if already open
    -- C-n/C-p or Up/Down: Select next/previous item
    -- C-e: Hide menu
    -- C-k: Toggle signature help (if signature.enabled = true)
    --
    -- See :h blink-cmp-config-keymap for defining your own keymap
    keymap = {
        preset = "none",
        ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
        ["<C-n>"] = { "select_next", "fallback_to_mappings" },

        ["<C-y>"] = { "select_and_accept", "fallback" },

        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
    },

    appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = "mono",
    },

    -- (Default) Only show the documentation popup when manually triggered
    completion = {
        documentation = { auto_show = true },
        accept = {
            -- experimental auto-brackets support
            auto_brackets = {
                enabled = true,
            },
        },
        menu = {
            draw = {
                treesitter = { "lsp" },
            },
        },
        list = { selection = { preselect = false, auto_insert = true } },
    },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        providers = {
            path = {
                name = "Path",
                module = "blink.cmp.sources.path",
                score_offset = 3,
                opts = {
                    trailing_slash = false,
                    label_trailing_slash = true,
                    get_cwd = function(context)
                        return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
                    end,
                    show_hidden_files_by_default = false,
                },
            },
        },
    },

    -- significantly
    signature = { enabled = true },

    -- cmd line setting
    cmdline = {
        enabled = true,
        keymap = {
            preset = "cmdline",
            ["<Right>"] = false,
            ["<Left>"] = false,
        },
        completion = {
            list = { selection = { preselect = false } },
            menu = {
                auto_show = function(ctx)
                    return vim.fn.getcmdtype() == ":"
                end,
            },
            ghost_text = { enabled = true },
        },
    },

    -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
    -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
    -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
    --
    -- See the fuzzy documentation for more information
    fuzzy = { implementation = "prefer_rust_with_warning" },
})

require("conform").setup({
    -- Define your formatters
    formatters_by_ft = {
        lua = { "stylua" },
        perl = { "perltidy" },
        python = { "isort", "black" },
    },
    -- Set default options
    default_format_opts = {
        lsp_format = "never",
    },
    -- Set up format-on-save
    -- format_on_save = { timeout_ms = 500 },
    -- Customize formatters
    formatters = {
        shfmt = {
            append_args = { "-i", "2" },
        },
        stylua = {
            append_args = { "--indent-type", "Spaces" },
        },
    },
})

require("flash").setup({
    search = {
        mode = function(str)
            return "\\<" .. str
        end,
    },
    highlight = {
        backdrop = false,
    },
    modes = {
        char = {
            highlight = {
                backdrop = false,
            },
        },
    },
})
