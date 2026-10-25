-- Colorscheme: :colorscheme bamboo
-- kitty terminal palette: ~/.config/kitty/themes/bamboo.conf
if vim.g.colors_name then
    vim.cmd("hi clear")
end

vim.o.termguicolors = true
vim.g.colors_name = "bamboo_bamboo"

local pal = {
    bg_drak2 = "#030902",
    bg_drak1 = "#131912",
    bg = "#232922",
    bg_dark = "#282828",
    bg_alt = "#30312d",
    bg_light1 = "#333333",
    bg_light2 = "#565656",
    bg_light3 = "#404040",
    bg_light4 = "#aaaaaa",
    bg_light5 = "#aaaaaa",
    fg = "#bdaa86",
    fg_dim = "#928374",
    fg_dim2 = "#626354",
    fg_light1 = "#eb8f3b",
    black = "#000000",
    blue = "#9d7cd8",
    blue_light1 = "#9bbcb5",
    green = "#6A9955",
    green_light1 = "#8fb573",
    red = "#e75a7c",
    red_light = "#dc4f62",
    orange = "#f0945d",
    purple = "#e49cb1",
    yellow = "#e2c792",
    yellow_light = "#ceba49",
    gray_dim = "#636761",
    gray = "#838781",
    gray_light1 = "#928374",
    muted_aqua = "#83a598",
    aqua = "#83c092",
    white = "#ece1c0", -- 7  white

    diff_added_word = "#1A4905",
    diff_removed_word = "#131912",
    diff_change_word = "#444444"
}

local terminal_colors = {
    "#171f17", -- 0  black
    "#dc4f62", -- 1  red
    "#81af58", -- 2  green
    "#ceba49", -- 3  yellow
    "#409cdc", -- 4  blue
    "#a09af8", -- 5  purple
    "#68baae", -- 6  cyan
    "#ECE1C0", -- 7  white
    "#5a5e5a", -- 8  bright black
    "#dc4f62", -- 9  bright red
    "#81af58", -- 10 bright green
    "#ceba49", -- 11 bright yellow
    "#409cdc", -- 12 bright blue
    "#a09af8", -- 13 bright purple
    "#68baae", -- 14 bright cyan
    "#fff8f0", -- 15 bright white
}

for i = 0, 15 do
    vim.g["terminal_color_" .. i] = terminal_colors[i + 1]
end

local hl = vim.tbl_deep_extend("force", {
    Normal = { fg = pal.bg_light4, bg = pal.bg },
    NormalNC = { link = "Normal" },
    NormalFloat = { bg = pal.bg_drak1 },
    Terminal = { link = "Normal" },
    EndOfBuffer = { link = "Normal" },
    Folded = { bg = pal.gray_light1, fg = pal.black },
    SignColumn = { bg = pal.bg, fg = pal.gray },
    CursorLine = { fg = nil, bg = pal.bg_light1 },
    Cursor = { fg = nil, bg = pal.white },
    Visual = { bg = pal.bg_light3 },
    lCursor = { link = "Cursor" },
    CursorIM = { link = "Cursor" },
    CursorColumn = { link = "CursorLine" },
    ColorColumn = { link = "CursorLine" },
    VisualNOS = { link = "CursorLine" },
    LineNr = { fg = pal.gray },
    CursorLineNr = { link = "LineNr" },
    StatusLine = { fg = pal.gray },
    StatusLineNC = { link = "StatusLine" },
    StatusLineTerm = { link = "StatusLine" },
    StatusLineTermNC = { link = "StatusLine" },
    WinSeparator = { fg = pal.bg_light2, bg = "NONE", bold = true },
    Search = { fg = pal.yellow_light, reverse = true },
    CurSearch = { fg = pal.red_light, reverse = true },
}, {
    Comment = { fg = pal.fg_dim },
    Function = { fg = pal.blue },
    String = { fg = pal.green },
    PreProc = { fg = pal.purple },
    Constant = { fg = pal.orange },
    Delimiter = { fg = pal.gray_dim },
    Operator = { fg = pal.gray },
    Type = { fg = pal.orange },
    Special = { link = "Delimiter" },
    -- Title = { fg = pal.orange },
    Directory = { fg = pal.blue },
    Title = { fg = pal.fg_dim },
}, {
    ["@variable"] = { fg = pal.fg },
    ["@variable.member"] = { fg = pal.muted_aqua },
    ["@variable.parameter"] = { fg = pal.red },
    -- ["@variable.parameter.python"] = { link = "@variable" },
    ["@variable.builtin"] = { link = "@variable" },
    ["@keyword"] = { fg = pal.gray },
    ["@keyword.function"] = { link = "@keyword" },
    ["@keyword.return"] = { link = "@keyword" },
    ["@function.call"] = { link = "Function" },
    ["@function.builtin"] = { link = "Function" },
    -- ["@constructor"] = { fg = pal.test },
    ["@module.builtin"] = { fg = pal.fg },
    ["@property"] = { link = "@variable.member" },
    ["@spell"] = { link = "Comment" },
    ["@nospell"] = { link = "Comment" },
    ["@constructor.lua"] = { link = "Delimiter" },
    ["@constructor.python"] = { link = "Function" },
    ["@constructor.systemverilog"] = { fg = pal.orange },
    ["@type.builtin"] = { link = "Type" },
    ["@attribute"] = { fg = pal.orange },
}, {
    -- indnet
    IndentLine = { fg = pal.bg_light2 },
    IndentLineCurrent = { link = "IndentLine" },
    -- Tsconstructor
    TreesitterContext = { bg = pal.bg_drak1, underline = true, sp = pal.gray },
    TreesitterContextLineNumber = { bg = pal.bg_drak1 },
    -- blink
    BlinkCmpLabel = { fg = pal.gray },
    BlinkCmpLabelMatch = { fg = pal.orange },
    BlinkCmpKind = { fg = pal.gray, reverse = true },
    BlinkCmpMenu = { link = "NormalFloat" },
    BlinkCmpMenuBorder = { link = "FloatBorder" },
    BlinkCmpDocBorder = { link = "FloatBorder" },
    BlinkCmpSignatureHelpBorder = { link = "FloatBorder" },
    BlinkCmpMenuSelection = { link = "CursorLine" },
    BlinkCmpLabelDetail = { link = "LspInlayHint" },
    BlinkCmpLabelDescription = { link = "LspInlayHint" },

    -- cursortab
    -- 插件用 hl_mode="combine" 只铺底色，前景色会沿用语法色，字形边缘会和底色混出脏色。
    -- 这里 fg / bg 都写死（且不带 bold/italic/reverse），整块只有两种颜色。
    CursorTabDeletion = { fg = nil, bg = pal.diff_removed_word, strikethrough = true },
    CursorTabAddition = { fg = nil, bg = pal.diff_added_word },
    CursorTabModification = { fg = nil, bg = pal.diff_added_word },
    CursorTabCompletion = { fg = nil, bg = pal.diff_added_word },
    CursorTabJumpSymbol = { fg = pal.green, reverse = true },
    CursorTabJumpText = { fg = pal.green, reverse = true },

    -- mini diff
    MiniDiffSignAdd = { fg = pal.gray },
    MiniDiffSignChange = { fg = pal.gray },
    MiniDiffSignDelete = { fg = pal.gray },
    MiniDiffOverChange = { fg = pal.red_light,reverse = true },
    MiniDiffOverContext = { link = "Normal" },
    MiniDiffOverDelete = { fg = pal.gray, bg = pal.diff_removed_word, strikethrough = true },
    MiniDiffOverAdd = { bg = pal.diff_added_word },
}, {
    DiagnosticError = { fg = pal.gray },
    DiagnosticWarn = { fg = pal.gray },
    DiagnosticInfo = { fg = pal.gray },
    DiagnosticHint = { fg = pal.gray },
    DiagnosticSignError = { fg = pal.gray },
    DiagnosticSignWarn = { fg = pal.grey },
    DiagnosticSignInfo = { fg = pal.gray },
    DiagnosticSignHint = { fg = pal.gray },
    LspInlayHint = { fg = pal.fg_dim2, italic = true },
})

for group_name, group_settings in pairs(hl) do
    vim.api.nvim_set_hl(0, group_name, group_settings)
end
