------------------------------------------------------------------------
-- colorscheme
------------------------------------------------------------------------
local function vim_highlights(highlights)
    for group_name, group_settings in pairs(highlights) do
        vim.api.nvim_set_hl(0, group_name, group_settings)
    end
end

vim.api.nvim_create_user_command("Settheme", function(opts)
    local color = {
        white = "#ffffff",
        dark = "#000000",
        bg = "#282828",
        bg_gray = "#928374",
        bg_yellow = "#e2c792",
        bg_light1 = "#484848",
        bg_light2 = "#666666",
        bg_light3 = "#aaaaaa",
        fg = "#bdaa86", -- ebdbb2
        fg_light1 = "#eb8f3b", -- ebdbb2
        blue = "#9d7cd8",
        blue_light1 = "#9bbcb5",
        green = "#6A9955",
        green_light1 = "#8fb573",
        gray = "#838781",
        gray_light1 = "#928374",
        red = "#e75a7c",
        orange = "#f0945d",
        purple = "#e49cb1",
        test = "#9d7cd8",
    }
    local common = {
        Normal = { fg = color.bg_light3, bg = color.bg },
        NormalNC = { link = "Normal" },
        NormalFloat = { link = "Normal" },
        Terminal = { link = "Normal" },
        EndOfBuffer = { link = "Normal" },
        Folded = { bg = color.gray_light1, fg = color.dark },
        SignColumn = { bg = color.bg, fg = color.gray },
        CursorLine = { fg = nil, bg = color.bg_light1 },
        Cursor = { fg = color.bg, bg = color.white },
        Visual = { bg = color.bg_light2 },
        lCursor = { link = "Cursor" },
        CursorIM = { link = "Cursor" },
        CursorColumn = { link = "CursorLine" },
        ColorColumn = { link = "CursorLine" },
        VisualNOS = { link = "CursorLine" },
        LineNr = { fg = color.gray },
        CursorLineNr = { link = "LineNr" },
        StatusLine = { fg = color.gray, bg = color.bg },
        StatusLineNC = { link = "StatusLine" },
        StatusLineTerm = { link = "StatusLine" },
        StatusLineTermNC = { link = "StatusLine" },
    }
    local syntax = {
        Comment = { fg = color.bg_gray },
        Function = { fg = color.blue },
        String = { fg = color.green },
        PreProc = { fg = color.test },
        Constant = { fg = color.orange },
        Delimiter = { fg = color.gray },
        Operator = { fg = color.gray },
    }
    local treesitter = {
        ["@variable"] = { fg = color.fg },
        ["@variable.member"] = { fg = color.fg },
        ["@keyword"] = { fg = color.bg_light3 },
        ["@keyword.function"] = { fg = color.bg_light3 },
        ["@keyword.return"] = { fg = color.bg_light3 },
        ["@function.call"] = { fg = color.blue },
        ["@function.builtin"] = { fg = color.blue },
        ["@constructor"] = { link = "Delimiter" },
        ["@module.builtin"] = { fg = color.fg },
        ["@property"] = { fg = color.bg_light3 },
    }
    local diagnostics = {
        DiagnosticError = { fg = color.red },
        DiagnosticWarn = { fg = color.orange },
        DiagnosticInfo = { fg = color.blue_light1 },
        DiagnosticHint = { fg = color.bg_light3 },
        DiagnosticVirtualTextError = { fg = color.red },
        DiagnosticVirtualTextWarn = { fg = color.orange },
        DiagnosticVirtualTextInfo = { fg = color.blue_light1 },
        DiagnosticVirtualTextHint = { fg = color.bg_light3 },
        DiagnosticSignError = { fg = color.red },
        DiagnosticSignWarn = { fg = color.orange },
        DiagnosticSignInfo = { fg = color.blue_light1 },
        DiagnosticSignHint = { fg = color.bg_light3 },
    }
    vim_highlights(common)
    vim_highlights(syntax)
    vim_highlights(treesitter)
    vim_highlights(diagnostics)
end, {})

vim.cmd("Settheme")

------------------------------------------------------------------------
-- Lsp config
------------------------------------------------------------------------

vim.diagnostic.config({
    virtual_text = true,
    virtual_lines = { current_line = true },
    underline = false,
    update_in_insert = false,

    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "", -- 错误图标（红中间白叉）
            [vim.diagnostic.severity.WARN] = "", -- 警告图标（黄叹号）
            [vim.diagnostic.severity.INFO] = "", -- 信息图标（蓝i）
            [vim.diagnostic.severity.HINT] = "󰌶 ", -- 暗示图标（绿灯泡）
        },
    },
})

------------------------------------------------------------------------
-- stateline & flod
------------------------------------------------------------------------
vim.t.name = "Editor"
function _G.current_tab_name()
    return vim.t[vim.fn.tabpagenr()].name or ("Tab " .. vim.fn.tabpagenr())
end
function _G.lsp_diagnostics()
    local counts = { [1] = 0, [2] = 0, [3] = 0, [4] = 0 }
    for _, d in ipairs(vim.diagnostic.get(0)) do
        counts[d.severity] = (counts[d.severity] or 0) + 1
    end
    if counts[1] + counts[2] + counts[3] + counts[4] == 0 then
        return ""
    end
    return string.format("  %d  %d  %d 󰌶 %d ", counts[1], counts[2], counts[3], counts[4])
end
local statusline = {
    "%-.80F", -- 文件路径
    "%m%r", -- 文件buf属性
    "%=", -- 分割
    "%{v:lua.lsp_diagnostics()}", -- LSP 诊断
    "%y %l,%c", -- 百分比
}
vim.o.statusline = table.concat(statusline, "")
-- 设置折叠方法和折叠符号
-- vim.opt.fillchars = { foldopen = "▾", foldsep = "│", foldclose = "▸" }
-- 全局函数，用于 foldtext
_G.fold_text = function()
    local line = vim.fn.getline(vim.v.foldstart) -- 折叠首行文本
    local folded = vim.v.foldend - vim.v.foldstart + 1 -- 折叠行数
    local width = vim.api.nvim_win_get_width(0)
    local suffix = string.format(" >>> %d lines", folded) -- 放到后面
    local avail = math.max(10, width - vim.fn.strdisplaywidth(suffix) - 5)
    local disp = vim.fn.strcharpart(line, 0, avail)
    if vim.fn.strdisplaywidth(line) > avail then
        disp = disp .. "…"
    end
    return disp .. suffix
end
vim.opt.foldtext = "v:lua.fold_text()"
