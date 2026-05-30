--- forbiden plugin
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_gzip = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_getscript = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_vimball = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_logiPat = 1
vim.g.loaded_rrhelper = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.showtabline = 2 -- tab栏
vim.opt.laststatus = 0 -- 设置stat line永远一行
vim.opt.cmdheight = 0 -- 设置cmd height高度
vim.opt.smartcase = true -- but make it case sensitive if an uppercase is entered
vim.opt.splitbelow = true -- 窗口打开位置
vim.opt.splitright = true -- 窗口打开位置

local statusline = table.concat({
    "%{repeat('-',winwidth(0))}",
})
vim.o.statusline = statusline

------------------------------------------------------------------------
-- key mapping
------------------------------------------------------------------------
local map = vim.keymap.set
local unmap = vim.keymap.del

map({ "i", "t" }, "<C-w>s", "<C-\\><C-n><C-w>s")
map({ "i", "t" }, "<C-w>v", "<C-\\><C-n><C-w>v")
map({ "i", "t" }, "<C-w>h", "<C-\\><C-n><C-w>h")
map({ "i", "t" }, "<C-w>j", "<C-\\><C-n><C-w>j")
map({ "i", "t" }, "<C-w>k", "<C-\\><C-n><C-w>k")
map({ "i", "t" }, "<C-w>l", "<C-\\><C-n><C-w>l")
map({ "i", "t" }, "<C-w>w", "<C-\\><C-n><C-w>w")
map({ "i", "t" }, "<C-w>q", "<C-\\><C-n><C-w>q")
map({ "i", "t" }, "<C-w>r", "<C-\\><C-n><C-w>r")
map({ "i", "t" }, "<C-w>;", "<C-\\><C-n>")
map({ "i", "t" }, "<C-w><space>", "<C-\\><C-n><C-w>r")

map({ "i", "t" }, "<C-w><space>", function()
    rpc_cmd("RemoteCycleTerm")
end, comment_opts)

------------------------------------------------------------------------
-- autocmd
------------------------------------------------------------------------

vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        vim.env.NVIM_PIP_FATHER = vim.g.pip_father
        vim.cmd("term")
        vim.cmd("startinsert")
    end,
})

vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
        local buf_type = vim.bo.buftype
        local cur_win = vim.api.nvim_get_current_win()
        local cur_buf = vim.api.nvim_win_get_buf(cur_win)

        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)

            if buf == cur_buf and win ~= cur_win then
                vim.env.NVIM_PIP_FATHER = vim.g.pip_father
                vim.cmd("term")
            end
        end

        if buf_type == "terminal" then
            vim.cmd("startinsert")
        else
            vim.env.NVIM_PIP_FATHER = vim.g.pip_father
            vim.cmd("term")
            vim.cmd("startinsert")
        end
    end,
})

------------------------------------------------------------------------
-- RPC
------------------------------------------------------------------------
chan_id = vim.fn.sockconnect("pipe", vim.g.pip_father, { rpc = true })

function rpc_cmd(cmd_string)
    vim.rpcnotify(chan_id, "nvim_exec_lua", "vim.api.nvim_command(...)", { cmd_string })
end

-- function rpc_send(func_name, ...)
--     vim.rpcnotify(chan_id, "nvim_exec_lua", func_name .. "(...)", { ... })
-- end
