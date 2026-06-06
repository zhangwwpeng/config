------------------------------------------------------------------------
-- auto cmd
------------------------------------------------------------------------
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    callback = function()
        -- try_lint without arguments runs the linters defined in `linters_by_ft`
        -- for the current filetype
        require("lint").try_lint()

        -- You can call `try_lint` with a linter name or a list of names to always
        -- run specific linters, independent of the `linters_by_ft` configuration
        require("lint").try_lint("typos")
    end,
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
