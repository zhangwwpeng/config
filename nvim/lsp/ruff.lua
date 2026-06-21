local python_lsp = require("python_lsp")

return {
    cmd = { "ruff", "server" },
    filetypes = { "python" },
    root_dir = python_lsp.root_dir,
    on_attach = function(client, _)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
        client.server_capabilities.hoverProvider = false
    end,
    init_options = {
        settings = {
            organizeImports = true,
            showSyntaxErrors = true,
            codeAction = {
                disableRuleComment = { enable = false },
                fixViolation = { enable = false },
            },
            format = { preview = false },
            lint = { enable = true },
        },
    },
}
