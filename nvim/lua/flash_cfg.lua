------------------------------------------------------------------------
-- Plugin config
------------------------------------------------------------------------
-- require("delta").setup({})
-- require("terminal")

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
