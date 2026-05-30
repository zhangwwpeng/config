return {
    -- Using lazy.nvim
    {
        -- 'zhangwwpeng/bamboo.nvim',
        "bamboo_zhangwwpeng.nvim",
        dir = "~/workspace/bamboo.nvim",
        priority = 1000,
        config = function()
            vim.cmd([[colorscheme bamboo]])
        end,
    },
}
