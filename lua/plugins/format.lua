return {
	"stevearc/conform.nvim",
	optional = true,
	opts = {
		formatters_by_ft = {
			["markdown"] = { { "prettierd", "prettier" }, "markdownlint", "markdown-toc" },
			["markdown.mdx"] = { { "prettierd", "prettier" }, "markdownlint", "markdown-toc" },
		},
	},
}
