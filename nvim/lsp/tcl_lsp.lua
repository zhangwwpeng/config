return {
    cmd = {
        "python3",
        vim.fs.joinpath(vim.env.HOME, ".local", "bin", "tcl-lsp-server.pyz"),
    },
    filetypes = { "tcl", "tcl-apl" },
    root_markers = { ".git" },
    single_file_support = true,
    on_attach = function(client, _)
        client.server_capabilities.signatureHelpProvider = false
    end,
    settings = {
        tclLsp = {
            dialect = "tcl8.6",
            extraCommands = {},
            libraryPaths = {},
            formatting = {
                indentSize = 4,
                indentStyle = "spaces",
                braceStyle = "k_and_r",
                maxLineLength = 120,
            },
        },
    },
}
