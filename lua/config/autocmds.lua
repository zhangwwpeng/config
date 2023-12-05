-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- neovide
local function set_ime(args)
  if args.event:match("Enter$") then
    vim.g.neovide_input_ime = true
  else
    vim.g.neovide_input_ime = false
  end
end

local ime_input = vim.api.nvim_create_augroup("ime_input", { clear = true })

vim.api.nvim_create_autocmd({ "InsertEnter", "InsertLeave" }, {
  group = ime_input,
  pattern = "*",
  callback = set_ime,
})

vim.api.nvim_create_autocmd({ "CmdlineEnter", "CmdlineLeave" }, {
  group = ime_input,
  pattern = "[/\\?]",
  callback = set_ime,
})

-- indent animal line
vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", {})
vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { fg = "#a89a7c" })

-- neo-tree bg
vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", {})
vim.api.nvim_set_hl(0, "NeoTreeNormal", {})
vim.api.nvim_set_hl(0, "NeoTreeFloatBorder", { bg = "#333c43" })
vim.api.nvim_set_hl(0, "NeoTreeTitleBar", { bg = "#333c43" })
vim.api.nvim_set_hl(0, "NeoTreeFloatTitle", { bg = "#333c43" })
vim.api.nvim_set_hl(0, "NeoTreeFloatNormal", { bg = "#333c43" })

-- mini file fg
vim.api.nvim_set_hl(0, "MiniFilesBorder", { bg = "#333c43" })
vim.api.nvim_set_hl(0, "MiniFilesBorderModified", { bg = "#333c43" })
vim.api.nvim_set_hl(0, "MiniFilesDirectory", { bg = "#333c43" })
vim.api.nvim_set_hl(0, "MiniFilesTitle", { bg = "#333c43" })
vim.api.nvim_set_hl(0, "MiniFilesTitleFocused", { bg = "#333c43" })
vim.api.nvim_set_hl(0, "MiniFilesNormal", { bg = "#333c43" })

--visual
vim.api.nvim_set_hl(0, "Visual", { fg = "#333c43", bg = "#a7c080" })
