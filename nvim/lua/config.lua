------------------------------------------------------------------------
-- Plugin config
------------------------------------------------------------------------
require("indent").setup()
require("edit")
require("imselect").setup()
-- require("delta").setup({})
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

require("mini.completion").setup()
