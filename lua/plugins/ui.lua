return {
	-- configure LazyVim to load colorcheme
	{
		"ribru17/bamboo.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("bamboo").setup({
				dim_inactive = false,
				transparent = false,
				italic = false,
				lualine = { transparent = false },
				code_style = {
					comments = { italic = false },
					conditionals = { italic = false },
					namespaces = { italic = false },
					parameters = { italic = false },
				},
				highlights = {},
			})
			require("bamboo").load()
		end,
	},
	--  set colorscheme
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "catppuccin",
		},
	},
	-- set rounded for neo-tree
	{
		"nvim-neo-tree/neo-tree.nvim",
		opts = {
			popup_border_style = "rounded",
		},
	},
	-- telescope
	{
		"nvim-telescope/telescope.nvim",
		config = function()
			require("telescope").setup({
				defaults = {
					sorting_strategy = "ascending",
					layout_strategy = "bottom_pane",
					layout_config = {
						height = 30,
					},
					border = true,
					borderchars = {
						prompt = { "─", " ", " ", " ", "─", "─", " ", " " },
						results = { " " },
						preview = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
					},
				},
			})
		end,
	},
	-- cmp add round
	{
		"hrsh7th/nvim-cmp",
		opts = function(_, opts)
			opts.window = {
				completion = {
					border = "rounded",
				},
				documentation = {
					border = "rounded",
				},
			}
		end,
	},
	-- lsp add round
	{
		"folke/noice.nvim",
		opts = {
			presets = {
				lsp_doc_border = true, -- add a border to hover docs and signature help
			},
		},
	},
	-- which key
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			window = {
				border = "single", -- none, single, double, shadow
			},
			plugins = { spelling = true },
			defaults = {
				mode = { "n", "v" },
				["g"] = { name = "+goto" },
				["gs"] = { name = "+surround" },
				["z"] = { name = "+fold" },
				["]"] = { name = "+next" },
				["["] = { name = "+prev" },
				["<leader><tab>"] = { name = "+tabs" },
				["<leader>b"] = { name = "+buffer" },
				["<leader>c"] = { name = "+code" },
				["<leader>f"] = { name = "+file/find" },
				["<leader>g"] = { name = "+git" },
				["<leader>gh"] = { name = "+hunks", ["_"] = "which_key_ignore" },
				["<leader>q"] = { name = "+quit/session" },
				["<leader>s"] = { name = "+search" },
				["<leader>u"] = { name = "+ui" },
				["<leader>w"] = { name = "+windows" },
				["<leader>x"] = { name = "+diagnostics/quickfix" },
			},
		},
		config = function(_, opts)
			local wk = require("which-key")
			wk.setup(opts)
			wk.register(opts.defaults)
		end,
	},
	-- cmp
	{
		"hrsh7th/nvim-cmp",
		opts = function(_, opts)
			opts.window = {
				completion = {
					border = "rounded",
				},
				documentation = {
					border = "rounded",
				},
			}
		end,
	},
}
