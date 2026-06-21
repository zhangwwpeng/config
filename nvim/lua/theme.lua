local palette = {
    -- bg_drak = "#131912",
    bg = "#232922",
    bg_dark = "#282828",
    bg_alt = "#30312d",
    bg_light1 = "#333333",
    bg_light2 = "#565656",
    bg_light3 = "#484848",
    bg_light4 = "#aaaaaa",
    fg = "#bdaa86",
    fg_dim = "#928374",
    fg_light1 = "#eb8f3b",
    white = "#ffffff",
    black = "#000000",
    blue = "#9d7cd8",
    blue_light1 = "#9bbcb5",
    green = "#6A9955",
    green_light1 = "#8fb573",
    red = "#e75a7c",
    orange = "#f0945d",
    purple = "#e49cb1",
    yellow = "#e2c792",
    gray = "#838781",
    gray_light1 = "#928374",
}

local function base(pal)
    return {
        Normal = { fg = pal.bg_light4, bg = pal.bg },
        NormalNC = { link = "Normal" },
        NormalFloat = { link = "Normal" },
        Terminal = { fg = pal.fg, bg = pal.white },
        EndOfBuffer = { link = "Normal" },
        Folded = { bg = pal.gray_light1, fg = pal.black },
        SignColumn = { bg = pal.bg, fg = pal.gray },
        CursorLine = { fg = nil, bg = pal.bg_light1 },
        Cursor = { fg = pal.bg, bg = pal.white },
        Visual = { bg = pal.bg_light3 },
        lCursor = { link = "Cursor" },
        CursorIM = { link = "Cursor" },
        CursorColumn = { link = "CursorLine" },
        ColorColumn = { link = "CursorLine" },
        VisualNOS = { link = "CursorLine" },
        LineNr = { fg = pal.gray },
        CursorLineNr = { link = "LineNr" },
        StatusLine = { fg = pal.gray, bg = pal.bg_alt },
        StatusLineNC = { link = "StatusLine" },
        StatusLineTerm = { link = "StatusLine" },
        StatusLineTermNC = { link = "StatusLine" },
        WinSeparator = { fg = pal.bg_light2, bg = "NONE", bold = true },
    }
end

local function syntax(pal)
    return {
        Comment = { fg = pal.fg_dim },
        Function = { fg = pal.blue },
        String = { fg = pal.green },
        PreProc = { fg = pal.purple },
        Constant = { fg = pal.orange },
        Delimiter = { fg = pal.gray },
        Operator = { fg = pal.gray },
        Type = { fg = pal.orange },
        Special = { link = "Delimiter" },
        -- Title = { fg = pal.orange },
        Directory = { fg = pal.blue },
    }
end

local function treesitter(pal)
    return {
        ["@variable"] = { fg = pal.fg },
        ["@variable.member"] = { fg = pal.fg },
        ["@keyword"] = { fg = pal.bg_light4 },
        ["@keyword.function"] = { fg = pal.bg_light4 },
        ["@keyword.return"] = { fg = pal.bg_light4 },
        ["@function.call"] = { fg = pal.blue },
        ["@function.builtin"] = { fg = pal.blue },
        ["@constructor"] = { link = "Delimiter" },
        ["@module.builtin"] = { fg = pal.fg },
        ["@property"] = { fg = pal.bg_light4 },
        ["@spell"] = { fg = pal.fg },
    }
end

local function plugin(pal)
    return {
        -- indnet
        IndentLine = { fg = pal.bg_light2, bold = true },
        IndentLineCurrent = { link = "IndentLine" },
    }
end

local function diagnostics(pal)
    return {
        DiagnosticError = { fg = pal.red },
        DiagnosticWarn = { fg = pal.orange },
        DiagnosticInfo = { fg = pal.blue_light1 },
        DiagnosticHint = { fg = pal.bg_light4 },
        DiagnosticVirtualTextError = { fg = pal.red },
        DiagnosticVirtualTextWarn = { fg = pal.orange },
        DiagnosticVirtualTextInfo = { fg = pal.blue_light1 },
        DiagnosticVirtualTextHint = { fg = pal.bg_light4 },
        DiagnosticSignError = { fg = pal.red },
        DiagnosticSignWarn = { fg = pal.orange },
        DiagnosticSignInfo = { fg = pal.blue_light1 },
        DiagnosticSignHint = { fg = pal.bg_light4 },
    }
end

local M = {}

M.colors = palette

-- Catppuccin Mocha terminal palette
local terminal_colors = {
    "#45475a", -- 0  black
    "#f38ba8", -- 1  red
    "#a6e3a1", -- 2  green
    "#f9e2af", -- 3  yellow
    "#89b4fa", -- 4  blue
    "#f5c2e7", -- 5  purple
    "#94e2d5", -- 6  cyan
    "#bac2de", -- 7  white
    "#585b70", -- 8  bright black
    "#f38ba8", -- 9  bright red
    "#a6e3a1", -- 10 bright green
    "#f9e2af", -- 11 bright yellow
    "#89b4fa", -- 12 bright blue
    "#f5c2e7", -- 13 bright purple
    "#bdaa86", -- 14 bright cyan
    "#cdd6f4", -- 15 bright white
}

function M.setup()
    local pal = palette
    vim.opt.fillchars:append({
        vert = "┃",
        horiz = "━",
    })
    for i = 0, 15 do
        vim.g["terminal_color_" .. i] = terminal_colors[i + 1]
    end
    local hl = vim.tbl_deep_extend("force", base(pal), syntax(pal), treesitter(pal), plugin(pal), diagnostics(pal))
    for group_name, group_settings in pairs(hl) do
        vim.api.nvim_set_hl(0, group_name, group_settings)
    end
end

return M
