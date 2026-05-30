return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        branch = "main",
        event = { "VeryLazy" },
        config = function()
            local parsers = {
                "c",
                "cpp",
                "lua",
                "python",
                "systemverilog",
                "perl",
            }
            require("nvim-treesitter").install(parsers)

            local filetypes = {}
            for _, parser in ipairs(parsers) do
                local filetype = vim.treesitter.language.get_filetypes(parser)[2]
                if filetype then
                    table.insert(filetypes, filetype)
                end
            end

            vim.api.nvim_create_autocmd("FileType", {
                pattern = filetypes,
                callback = function()
                    vim.treesitter.start()
                    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
                    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    -- vim.cmd("syntax off")
                end,
            })
        end,
    },
}
