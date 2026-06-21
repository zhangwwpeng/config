local python_lsp = require("python_lsp")

return {
    cmd = { "basedpyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_dir = python_lsp.root_dir,
    on_attach = function(client, _)
        client.server_capabilities.completionProvider = false
        client.server_capabilities.documentHighlightProvider = false
        client.server_capabilities.documentSymbolProvider = false
        client.server_capabilities.semanticTokensProvider = false
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
        client.server_capabilities.definitionProvider = false
        client.server_capabilities.declarationProvider = false
        client.server_capabilities.typeDefinitionProvider = false
        client.server_capabilities.renameProvider = false
    end,
    settings = {
        basedpyright = {
            disableOrganizeImports = true,
            analysis = {
                autoImportCompletions = true,
                autoSearchPaths = true,
                diagnosticMode = "openFilesOnly",
                useLibraryCodeForTypes = true,
                diagnosticSeverityOverrides = {
                    reportUnknownMemberType = "none",
                    reportUnusedCallResult = "none",
                },
                exclude = {
                    "**/.venv",
                    "**/venv",
                    "**/__pycache__",
                    "**/dist",
                    "**/build",
                },
            },
        },
    },
}
