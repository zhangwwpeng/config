-- grug-far.nvim：搜索 & 替换（默认 ripgrep 引擎）
-- 依赖：rg（已装）。可选：devicons / mini.icons 显示文件图标；ast-grep 用 astgrep 引擎
-- 注意：buffer 内快捷操作走 <localleader>（你的 maplocalleader = "\\"）
-- 高亮：插件全部 default = true 链到 ModeMsg/Title/Comment/DiffText 等，跟色板基本兼容
local M = {}

function M.setup()
    require("grug-far").setup({
        -- 输入后多久开始搜（默认 500）
        debounceMs = 300,
        -- 结果区换行；关掉后长行横向滚动（跟你的 wrap=false 风格一致）
        wrap = false,
        -- 匹配太多时截断，防止大 repo 卡住
        maxSearchMatches = 2000,
    })
end

return M
