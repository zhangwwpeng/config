local M = {}

function M.setup()
    require("mini.diff").setup({
        view = {
            -- Visualization style. Possible values are 'sign' and 'number'.
            -- Default: 'number' if line numbers are enabled, 'sign' otherwise.
            -- style = vim.go.number and "number" or "sign",
            style = "sign",

            -- Signs used for hunks with 'sign' view
            signs = { add = "+", change = "┃", delete = "-" },

            -- Priority of used visualization extmarks
            priority = 0,
        },
    })
end

return M
