-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt
local g = vim.g
local o = vim.o

if vim.g.neovide then
	-- set font
	o.guifont = "FiraCode Nerd Font:h12"
	-- set padding
	g.neovide_padding_top = 0
	g.neovide_padding_bottom = 0
	g.neovide_padding_right = 0
	g.neovide_padding_left = 0
	-- set transparent
	g.neovide_transparency = 0.95
	g.transparency = 0.95
	-- hidden mouse
	g.neovide_hide_mouse_when_typing = true
	-- rate
	g.neovide_refresh_rate = 60
	-- quit
	g.neovide_confirm_quit = true
	-- remember window sizw
	g.neovide_remember_window_size = true
	-- touch deadzone
	g.neovide_touch_deadzone = 6.0
	-- set title
	opt.title = true
end

-- ui for everforest
g.everforest_background = "soft"
g.everforest_dim_inactive_windows = 0
g.everforest_ui_contrast = "high"

-- tab set
o.tabstop = 4 -- A TAB character looks like 4 spaces
o.expandtab = true -- Pressing the TAB key will insert spaces instead of a TAB character
o.softtabstop = 4 -- Number of spaces inserted instead of a TAB character
o.shiftwidth = 4 -- Number of spaces inserted when indenting
