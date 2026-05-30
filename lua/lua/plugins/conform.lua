return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
        -- {
        --  -- Customize or remove this keymap to your liking
        --  "<leader>f",
        --  function()
        --      require("conform").format({ async = false })
        --  end,
        --  mode = "",
        --  desc = "Format buffer",
        -- },
    },
    -- This will provide type hinting with LuaLS
    ---@module "conform"
    ---@type conform.setupOpts
    opts = {
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
    },
}
