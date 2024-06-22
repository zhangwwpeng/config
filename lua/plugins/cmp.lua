return {
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
