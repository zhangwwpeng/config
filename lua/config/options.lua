-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt
local g = vim.g
local o = vim.o

-- tab set
o.tabstop = 4 -- A TAB character looks like 4 spaces
o.expandtab = true -- Pressing the TAB key will insert spaces instead of a TAB character
o.softtabstop = 4 -- Number of spaces inserted instead of a TAB character
o.shiftwidth = 4 -- Number of spaces inserted when indenting
o.background = "dark"
