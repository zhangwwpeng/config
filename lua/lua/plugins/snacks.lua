return {
    -- lazy.nvim
    {
        "folke/snacks.nvim",
        ---@type snacks.Config
        opts = {
            indent = {
                animate = { enabled = false },
                scope = { enabled = false },
            },
        },
        config = function()
            require("snacks").indent.disable()
        end,
    },
}
