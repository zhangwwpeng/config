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

if vim.g.neovide then
	-- windows blur
	vim.g.neovide_window_blurred = false
	-- float shadow
	vim.g.neovide_floating_shadow = true
	vim.g.neovide_floating_z_height = 10
	vim.g.neovide_light_angle_degrees = 45
	vim.g.neovide_light_radius = 5
	-- hide mouse
	vim.g.neovide_hide_mouse_when_typing = true
	-- layer grouping
	vim.g.experimental_layer_grouping = true
	-- options
	vim.g.neovide_input_macos_option_key_is_meta = "both"
	-- animal
	vim.g.neovide_cursor_animation_length = 0
	vim.g.neovide_cursor_vfx_mode = ""
end
