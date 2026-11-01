local M = {}

local vault = "~/vaults/obsidian/doc"

function M.setup()
    -- vault 只在本机有；其他机器（Linux 服务器等）上没有这个目录就不启用
    if vim.fn.isdirectory(vim.fn.expand(vault)) == 0 then
        return
    end
    require("obsidian").setup({
        legacy_commands = false, -- this will be removed in 4.0.0
        workspaces = {
            {
                name = "personal",
                path = vault,
            },
        },
    })
end

return M
