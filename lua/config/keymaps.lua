------------------------------------------------------------------------
-- Keymap
------------------------------------------------------------------------
local map = vim.keymap.set
local unmap = vim.keymap.del

------------------------------------------------------------------------
-- Save file
------------------------------------------------------------------------
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
map({ "i", "x", "n", "s" }, "<C-q>", "<cmd>q<cr><esc>", { desc = "Save File and Quit nvim" })

------------------------------------------------------------------------
-- Ui move
------------------------------------------------------------------------
map("n", "<Up>", "<cmd>resize -2<CR>", { desc = "Remove windows up" })
map("n", "<Down>", "<cmd>resize +2<CR>", { desc = "Remove windows down" })
map("n", "<Left>", "<cmd>vertical resize -2<CR>", { desc = "Remove windows left" })
map("n", "<Right>", "<cmd>vertical resize +2<CR>", { desc = "Remove windows right" })

------------------------------------------------------------------------
-- Yazi
------------------------------------------------------------------------
map({ "n", "v" }, "<leader>e", "<cmd>Yazi toggle<cr>", { desc = "Open yazi at the current file" })

------------------------------------------------------------------------
-- Comment
------------------------------------------------------------------------
local comment_opts = { desc = "comment keybinding", remap = true }
map("n", "<C-/>", "gcc", comment_opts)
map("x", "<C-/>", "gc", comment_opts)
map("i", "<C-/>", function()
    vim.cmd.normal("gcc")
end, comment_opts)

------------------------------------------------------------------------
-- Zen mode
------------------------------------------------------------------------
map("n", "<leader>z", function()
    -- 保存当前 UI 设置状态
    local zen_mode = vim.g.zen_mode or false
    if not zen_mode then
        vim.opt.showtabline = 0
        vim.opt.signcolumn = "no"
        vim.opt.number = false
        vim.opt.colorcolumn = ""
        require("snacks").indent.disable()
    else
        vim.opt.showtabline = 2
        vim.opt.signcolumn = "no"
        vim.opt.number = true
        vim.opt.colorcolumn = "120"
        require("snacks").indent.enable()
    end
    vim.g.zen_mode = not zen_mode
end, { desc = "Toggle Zen mode" })

------------------------------------------------------------------------
-- Code formmat
------------------------------------------------------------------------

map({ "i", "n", "v" }, "<C-l>", function()
    require("conform").format({ async = true })
end, { desc = "Formate Code" })
