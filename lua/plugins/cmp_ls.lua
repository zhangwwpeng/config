return {
	"liubianshi/cmp-lsp-rimels",
	dependencies = {
		"neovim/nvim-lspconfig",
		"hrsh7th/nvim-cmp",
		"hrsh7th/cmp-nvim-lsp",
	},
	config = function()
		require("rimels").setup({})
	end,
}
