------------------------------------------------------------------------
-- Set color mainbg
------------------------------------------------------------------------
vim.api.nvim_create_user_command("Mainbg", function(opts)
    local color = opts.args
    vim.g.main_bg = color
    vim.notify("main_bg set to " .. color, vim.log.levels.INFO)
    vim.cmd([[colorscheme bamboo]])
end, {
    nargs = 1, -- 必须传一个参数
})
