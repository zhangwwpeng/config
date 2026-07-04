------------------------------------------------------------------------
-- key mapping
------------------------------------------------------------------------
local map = vim.keymap.set
local unmap = vim.keymap.del

-- save file
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
map({ "i", "x", "n", "s" }, "<C-q>", "<cmd>q<cr><esc>", { desc = "Quit nvim" })

-- ui move
map("n", "<Up>", "<cmd>resize -2<CR>", { desc = "Remove windows up" })
map("n", "<Down>", "<cmd>resize +2<CR>", { desc = "Remove windows down" })
map("n", "<Left>", "<cmd>vertical resize -2<CR>", { desc = "Remove windows left" })
map("n", "<Right>", "<cmd>vertical resize +2<CR>", { desc = "Remove windows right" })

-- yazi
-- map({ "n", "v" }, "<leader>y", "<cmd>Yazi toggle<cr>", { desc = "Open yazi at the current file" })

-- comment
local comment_opts = { desc = "comment keybinding", remap = true }
map("n", "<C-/>", "gcc", comment_opts)
map("x", "<C-/>", "gc", comment_opts)
map("i", "<C-/>", function()
    vim.cmd.normal("gcc")
end, comment_opts)

-- picker
map({ "n" }, "<leader><leader>", function()
    Snacks.picker.smart()
end, { desc = "Smart Find Files" })

-- flash
map({ "n", "x", "o" }, "s", function()
    require("flash").jump()
end, { desc = "Flash" })
map({ "n", "x", "o" }, "S", function()
    require("flash").treesitter()
end, { desc = "Flash Tressiter" })

-- oil
map("n", "<leader>e", "<CMD>Oil<CR>", { desc = "Open parent directory" })
map("n", "<leader>0", function()
    require("code_preview").preview_at(12, {
        error = { "undefined symbol: foo" },
        warn = { "unused variable: bar" },
        info = { "type inferred as any" },
        msm = { "custom note" }, -- 或 msg
        suggestion = { "consider renaming variable" },
    })
end, { desc = "Line diagnostic panel" })

-- emcal style
map({ "c", "n" }, "<C-a>", "<Home>", { noremap = true })
map({ "c", "n" }, "<C-e>", "<end>", { noremap = true })
map("i", "<C-a>", "<C-o>^", { noremap = true })
map("i", "<C-e>", "<C-o>$", { noremap = true })
map("i", "<C-f>", "<Right>", { noremap = true })
map("i", "<C-b>", "<left>", { noremap = true })
