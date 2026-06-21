M = {}

function M.setup()
    vim.filetype.add({
        extension = {
            tcl = "tcl",
            tk = "tcl",
            itcl = "tcl",
            tm = "tcl",
            irul = "tcl",
            irule = "tcl",
            iapp = "tcl",
            iappimpl = "tcl",
            impl = "tcl",
            apl = "tcl-apl",
            exp = "tcl",
        },
    })

    vim.lsp.enable({
        "lua_ls", -- lua
        "clangd", -- c / c++
        "rust_analyzer", -- rust
        "bashls", -- bash / sh
        "just", -- justfile
        "make_ls", -- makefile
        "tcl_lsp", -- tcl
        "ruff", -- python: lint / organize imports
        "basedpyright", -- python: type checking
        "pyrefly", -- python: completion / navigation
    })

    -- lsp close lsp highlight
    vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client and client.server_capabilities.semanticTokensProvider then
                client.server_capabilities.semanticTokensProvider = nil
            end
        end,
    })

    -- 1. 创建一个独立的自动命令组，防止重复注册
    local diag_insert_group = vim.api.nvim_create_augroup("LspDiagInsertToggle", { clear = true })

    -- 2. 进入 Insert 模式时：立刻隐藏（关闭）所有诊断视觉
    vim.api.nvim_create_autocmd("InsertEnter", {
        group = diag_insert_group,
        pattern = "*",
        callback = function()
            vim.diagnostic.show(
                nil,
                0,
                nil,
                { virtual_text = false, virtual_lines = false, underline = false, signs = false }
            )
        end,
    })

    -- 3. 离开 Insert 模式（回到 Normal 模式）时：重新完整显示诊断
    vim.api.nvim_create_autocmd("InsertLeave", {
        group = diag_insert_group,
        pattern = "*",
        callback = function()
            vim.diagnostic.show(nil, 0, nil, nil) -- 恢复你在 vim.diagnostic.config 里的默认全局配置
        end,
    })
end

return M
