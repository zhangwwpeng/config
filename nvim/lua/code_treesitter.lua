local M = {}

function M.setup()
    vim.treesitter.language.register("bash", { "sh" })
    vim.filetype.add({
        extension = {
            v = "systemverilog",
        },
    })

    --  treesitter
    vim.api.nvim_create_autocmd("FileType", {
        pattern = {
            "c",
            "systemverilog",
            "python",
            "sh",
            "markdown",
            "json",
            "yaml",
            "toml",
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
