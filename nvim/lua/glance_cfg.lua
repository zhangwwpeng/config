-- glance.nvim 的窗口配置
-- 颜色在 colors/bamboo_bamboo.lua 的 glance 块里（底色跟 NormalFloat 一致）
-- 这里负责让两个浮窗的 winblend 跟 vim.g.float_win_blend 同步
local M = {}

function M.setup()
    require("glance").setup({})

    -- -- list 浮窗的 buffer filetype 是 Glance，建窗后再保一次底
    -- vim.api.nvim_create_autocmd("FileType", {
    --     group = vim.api.nvim_create_augroup("GlanceWinblend", { clear = true }),
    --     pattern = "Glance",
    --     callback = function()
    --         local w = vim.api.nvim_get_current_win()
    --         if vim.api.nvim_win_get_config(w).relative ~= "" then
    --             vim.wo[w].winblend = blend()
    --         end
    --     end,
    --     desc = "glance: keep list float in sync with float_win_blend",
    -- })
end

return M
