local M = {}

function M.setup()
    vim.treesitter.language.register("bash", { "sh" })

    --  treesitter
    vim.api.nvim_create_autocmd("FileType", {
        pattern = {
            "c",
            -- "verilog",
            "python",
            "rust",
            "sh",
            "markdown",
            "json",
            "yaml",
            "toml",
            "just",
            "make",
            "tcl",
            "bash",
        },
        callback = function()
            vim.treesitter.start()
        end,
    })
end

return M
