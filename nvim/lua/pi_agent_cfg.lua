-- pi-agent + pi_diff 的配置入口
--
-- surface 用 nvim_flt（Neovim 浮动窗口），几何跟 terminal.lua 的浮窗保持一致：
--   width / height 传 <=1 的比例（1 = 铺满 editor，内部会扣掉 cmdheight）
--   winblend 取 init.lua 里的 vim.g.float_win_blend（surface 自己会写 winblend，
--   会覆盖 init.lua 的 WinNew autocmd，所以必须显式传）
-- 详见 pi-agent.nvim/lua/pi-agent/surfaces/nvim_flt.lua 的 M.win_config()
local M = {}

function M.setup()
    local pi = require("pi-agent")
    pi.setup({
        surface = pi.get_surface("nvim_flt").configure({
            width = 1, -- 比例（<=1）或绝对列数：1 = 铺满
            height = 1, -- 1 = 铺满（内部扣掉 cmdheight）
            border = "none",
            winblend = tonumber(vim.g.float_win_blend) or 0,
        }),
    })

    require("pi_diff").setup()
end

return M
