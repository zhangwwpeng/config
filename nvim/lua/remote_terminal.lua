--- forbidden plugin
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
map({ "i", "t" }, "<C-0>", function()
    vim.rpcnotify(Father_chan, "nvim_command", "CycleTerm")
end)

------------------------------------------------------------------------
-- tab 管理
------------------------------------------------------------------------

map({ "n" }, "t", "<cmd>tabnew<cr>")
map({ "n" }, "d", "<cmd>tabclose<cr>")
map({ "n" }, "p", "<cmd>tabprevious<cr>")
map({ "n" }, "n", "<cmd>tabnext<cr>")
map({ "n" }, "r", function()
    local name = vim.fn.input("Tab name: ")
    vim.t.tab_title = name
    vim.cmd("redrawtabline")
end)

function _G.make_pure_tabline()
    local s = ""
    for i = 1, vim.fn.tabpagenr("$") do
        if i == vim.fn.tabpagenr() then
            s = s .. "%#TabLineSel#"
        else
            s = s .. "%#TabLine#"
        end
        s = s .. " " .. i .. ":"
        local ok, title = pcall(vim.api.nvim_tabpage_get_var, i, "tab_title")
        if ok and title and title ~= "" then
            s = s .. title .. " "
        else
            local buflist = vim.fn.tabpagebuflist(i)
            local winnr = vim.fn.tabpagewinnr(i)
            local bufname = vim.fn.bufname(buflist[winnr])
            if bufname == "" then
                s = s .. "[empty] "
            else
                s = s .. vim.fn.fnamemodify(bufname, ":t") .. " "
            end
        end
    end
    s = s .. "%#TabLineFill#%T"
    return s
end

vim.opt.tabline = "%!v:lua.make_pure_tabline()"

--- 跳转到指定名字的 tab，不存在则创建，可选执行命令
---@param tabname string
---@param cmd string|nil  创建新 tab 时在终端执行的命令
function _G.goto_or_create_tab(tabname, cmd)
    for i = 1, vim.fn.tabpagenr("$") do
        local ok, title = pcall(vim.api.nvim_tabpage_get_var, i, "tab_title")
        if ok and title == tabname then
            vim.cmd("tabnext " .. i)
            return
        end
    end
    vim.cmd("tabnew")
    vim.t.tab_title = tabname
    vim.cmd("redrawtabline")
    vim.env.NVIM_PIP_FATHER = vim.g.pip_father
    vim.cmd("term")
    vim.cmd("startinsert")
    if cmd then
        local term_buf = vim.api.nvim_get_current_buf()
        local chan = vim.bo[term_buf].channel
        if chan and chan > 0 then
            vim.api.nvim_chan_send(chan, cmd .. "\n")
        end
    end
end

--- 向指定 tab 的终端发送文本
---@param tabname string
---@param text string
function _G.send_to_tab_terminal(tabname, text)
    _G.goto_or_create_tab(tabname)
    for _, buf in ipairs(vim.fn.tabpagebuflist()) do
        if vim.bo[buf].buftype == "terminal" then
            local chan = vim.bo[buf].channel
            if chan and chan > 0 then
                vim.api.nvim_chan_send(chan, text)
                return
            end
        end
    end
    vim.notify("no terminal found in tab: " .. tabname, vim.log.levels.WARN)
end

------------------------------------------------------------------------
-- autocmd
------------------------------------------------------------------------

vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        vim.env.NVIM_PIP_FATHER = vim.g.pip_father
        vim.cmd("term")
        vim.cmd("startinsert")
        vim.t.tab_title = "bash"
        vim.api.nvim_buf_set_name(vim.api.nvim_get_current_buf(), "bash")
    end,
})

vim.api.nvim_create_autocmd("TabNew", {
    callback = function()
        vim.env.NVIM_PIP_FATHER = vim.g.pip_father
        vim.schedule(function()
            vim.cmd("term")
            vim.cmd("startinsert")
        end)
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
