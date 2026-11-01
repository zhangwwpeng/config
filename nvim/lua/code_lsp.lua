local M = {}

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
        "bashls", -- bash / sh
        "make_ls", -- makefile
        "ruff", -- python: lint / organize imports
        "basedpyright", -- python: type checking
        "pyrefly", -- python: completion / navigation
        "systemverilog", -- verilog,systemverilog
    })

    -- inlay hint 全局开启一次即可（不需要每次 attach 都调）
    vim.lsp.inlay_hint.enable(true)

    -- 关闭所有 server 的 semantic tokens，高亮统一交给 treesitter
    vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client and client.server_capabilities.semanticTokensProvider then
                client.server_capabilities.semanticTokensProvider = nil
            end
        end,
    })

    vim.lsp.codelens.enable(true)

    -- 诊断显示配置统一在 ui.lua 的 M.setup() 里设置，这里不要再调用 vim.diagnostic.config：
    -- 它是顶层浅合并，两处都设会互相覆盖（比如 virtual_text 整张表被替换）。

    -- -- 1. 创建一个独立的自动命令组，防止重复注册
    -- local diag_insert_group = vim.api.nvim_create_augroup("LspDiagInsertToggle", { clear = true })

    -- -- 2. 进入 Insert 模式时：隐藏当前 buffer 的诊断展示
    -- vim.api.nvim_create_autocmd("InsertEnter", {
    --     group = diag_insert_group,
    --     pattern = "*",
    --     callback = function(args)
    --         vim.diagnostic.hide(nil, args.buf)
    --     end,
    -- })
    --
    -- -- 3. 离开 Insert 模式（回到 Normal 模式）时：恢复当前 buffer 的诊断展示
    -- vim.api.nvim_create_autocmd("InsertLeave", {
    --     group = diag_insert_group,
    --     pattern = "*",
    --     callback = function(args)
    --         vim.diagnostic.show(nil, args.buf)
    --     end,
    -- })
end

return M
