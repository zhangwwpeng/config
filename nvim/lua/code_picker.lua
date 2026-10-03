local M = {}

local lines = math.floor(vim.o.lines * 0.4)

function M.setup()
    require("refer").setup({
        -- max_height_percent = 0.4,
        -- min_height = 0.4,
        max_height = lines,
        min_height = lines,
        ui = {
            mark_char = "●",
            mark_hl = "String",
            input_position = "top", -- "top" or "bottom"
            reverse_result = false,
            winhighlight = "Normal:Normal,FloatBorder:Normal,WinSeparator:Normal,StatusLine:Normal,StatusLineNC:Normal",
            highlights = {
                prompt = "Title",
                selection = "Visual",
                header = "WarningMsg",
            },
        },
    })
    require("refer").setup_ui_select()
end

return M
