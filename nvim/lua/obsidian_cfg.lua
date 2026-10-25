local M = {}

function M.setup()
    require("obsidian").setup({
        legacy_commands = false, -- this will be removed in 4.0.0
        workspaces = {
            {
                name = "personal",
                path = "~/vaults/obsidian/doc",
            },
        },
    })
end

return M
