local python_lsp = require("python_lsp")

return {
    cmd = { "pyrefly", "lsp" },
    filetypes = { "python" },
    root_dir = python_lsp.root_dir,
    on_attach = function(client, _)
        client.server_capabilities.semanticTokensProvider = false
        client.server_capabilities.codeActionProvider = false
        client.server_capabilities.hoverProvider = false
        client.server_capabilities.inlayHintProvider = false
        client.server_capabilities.referencesProvider = false
        client.server_capabilities.signatureHelpProvider = false
        client.server_capabilities.workspaceSymbolProvider = false
        client.server_capabilities.implementationProvider = false
        client.server_capabilities.callHierarchyProvider = false
    end,
    settings = {},
}
