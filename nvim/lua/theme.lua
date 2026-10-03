local palette = {
    -- bg_drak = "#131912",
    bg = "#232922",
    bg_dark = "#282828",
    bg_alt = "#30312d",
    bg_light1 = "#333333",
    bg_light2 = "#565656",
    bg_light3 = "#484848",
    bg_light4 = "#aaaaaa",
    bg_light5 = "#999999",
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

    diff_added_line = "#003300",
    diff_removed_line = "#110000",
    diff_added_word = "#00b000",
    diff_removed_word = "#b00000",
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
        Title = {fg = pal.fg_dim}
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

        -- Deleta
        DeltaDiffAddedLine = { bg = pal.diff_added_line },
        DeltaDiffRemovedLine = { bg = pal.diff_removed_line },
        DeltaDiffAddedWord = { bg = pal.diff_added_word },
        DeltaDiffRemovedWord = { bg = pal.diff_removed_word, strikethrough = true },

        -- cmp
        BlinkCmpMenu = { fg = pal.bg_light5 },
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

-- kitty terminal palette: ~/.config/kitty/themes/bamboo.conf
local terminal_colors = {
    "#171f17", -- 0  black
    "#dc4f62", -- 1  red
    "#81af58", -- 2  green
    "#ceba49", -- 3  yellow
    "#409cdc", -- 4  blue
    "#a09af8", -- 5  purple
    "#68baae", -- 6  cyan
    "#ece1c0", -- 7  white
    "#5a5e5a", -- 8  bright black
    "#dc4f62", -- 9  bright red
    "#81af58", -- 10 bright green
    "#ceba49", -- 11 bright yellow
    "#409cdc", -- 12 bright blue
    "#a09af8", -- 13 bright purple
    "#68baae", -- 14 bright cyan
    "#fff8f0", -- 15 bright white
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
