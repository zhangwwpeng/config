-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- delete noice ui
vim.keymap.set("n", "<BS>", function()
	require("noice").cmd("dismiss")
end, { desc = "delete noice ui" })

-- for venn
vim.keymap.set("v", "<c-p>", ":VBox<CR>")
vim.keymap.set("n", "<c-k>", ":Inspect<CR>")

-- set q to quit
-- set c-q to origi q
vim.keymap.set({ "n", "v" }, "q", "<Esc>")
vim.keymap.set({ "n", "v" }, "<c-q>", "q")
