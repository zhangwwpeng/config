------------------------------------------------------------------------
-- vim option set
------------------------------------------------------------------------
--- forbiden plugin
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_gzip = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_getscript = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_vimball = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_logiPat = 1
vim.g.loaded_rrhelper = 1
vim.g.loaded_netrwPlugin = 1
vim.g.c_syntax_for_h = 1
vim.g.mapleader = " " -- set to leader key
vim.g.maplocalleader = "\\" -- disable maplocalleader
vim.g.bigfile_size = 1024 * 1024 * 1.5 -- 1.5 MB
vim.o.list = true -- signal visual
vim.o.inccommand = "split" -- Preview substitutions live, as you type!
vim.o.scrolloff = 10
vim.o.confirm = true
vim.o.jumpoptions = "stack" -- better CTRL-O CTRL-I
vim.opt.autowrite = true -- auto write when "make" "last" "first" etc..
vim.opt.autoread = true -- auto read when file change
vim.opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" -- Sync with system clipboard
vim.opt.number = true -- 显示行号
vim.opt.wrap = false -- 行内不折叠
vim.opt.list = true -- 显示tab字符
vim.opt.cmdheight = 0 -- 设置cmd height高度
vim.opt.laststatus = 3 -- 设置stat line永远一行
vim.opt.showcmdloc = "statusline" -- cmdloc的位置
vim.opt.showtabline = 0 -- tab栏
vim.opt.cursorline = true -- 当前行高亮
vim.opt.splitbelow = true -- 窗口打开位置
vim.opt.splitright = true -- 窗口打开位置
-- vim.opt.winborder = "rounded" -- 窗口圆角
vim.opt.tabstop = 4 -- 一个 tab 显示为 4 个空格
vim.opt.shiftwidth = 0 -- 首行缩进时用 4 个空格
vim.opt.softtabstop = 4 -- 插入模式按 Tab = 4 个空格
vim.opt.expandtab = true -- Tab 转换为空格
vim.opt.incsearch = true -- search as characters are entered
vim.opt.ignorecase = true -- ignore case in searches by default
vim.opt.smartcase = true -- but make it case sensitive if an uppercase is entered
vim.opt.mouse = "a" -- mouse on
vim.opt.undofile = true -- undo file
vim.opt.wildmenu = false --  disable self cmp
vim.opt.wildmode = "" --disable self cmp
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

------------------------------------------------------------------------
-- stateline & flod
------------------------------------------------------------------------
vim.t.name = "Editor"
function _G.current_tab_name()
    return vim.t[vim.fn.tabpagenr()].name or ("Tab " .. vim.fn.tabpagenr())
end
function _G.current_macro_status()
    local reg = vim.fn.reg_recording()
    if reg ~= "" then
        return "recording @" .. reg
    else
        return ""
    end
end
local statusline = {
    "▊ ",
    "%<", -- 截断
    "%-.80F", -- 文件路径
    "%m%r", -- 文件buf属性
    "%=", -- 分割
    "%.S", -- cmd显示
    "  %{v:lua.current_macro_status()}", -- 展示宏录制
    "  %.(%l  ALL:%L%)", -- 行数
    "  %{v:lua.current_tab_name()}", -- 展示tab的名字
    "  %3.p%%", -- 百分比
    " ▊",
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
------------------------------------------------------------------------
-- colorscheme
------------------------------------------------------------------------
local function vim_highlights(highlights)
    for group_name, group_settings in pairs(highlights) do
        vim.api.nvim_set_hl(0, group_name, group_settings)
    end
end

vim.api.nvim_create_user_command("Settheme", function(opts)
    color = {
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
    common = {
        -- main windows
        Normal = { fg = color.bg_light3, bg = color.bg }, -- active windows下配色
        NormalNC = { link = "Normal" }, -- non active windows下配色
        NormalFloat = { link = "Normal" }, -- float windows下配色
        Terminal = { link = "Normal" }, -- Terminal 配色
        EndOfBuffer = { link = "Normal" }, -- end buf 配色
        -- FloatBorder = { fg = color.fg , bg = color.bg }, -- 浮动窗口外边 already link normalflaot
        -- FloatTitle = { bg = c.main_bg }, -- already link tittle
        -- FloatFooter = { bg = c.main_bg }, -- already link float title
        -- Fold
        -- FoldColumn = { fg = c.main_blue, bg = c.main_bg }, -- 折叠的符号 already link SignColumn
        Folded = { bg = color.gray_light1, fg = color.dark }, -- 折叠的那一行
        SignColumn = { bg = color.debug, fg = color.debug }, -- 符号
        CursorLine = { fg = none, bg = color.bg_light1 }, -- 当前行高亮
        Cursor = { fg = color.bg, bg = color.white }, -- Cursour
        Visual = { bg = color.bg_light2 }, -- v mode
        lCursor = { link = "Cursor" },
        CursorIM = { link = "Cursor" },
        CursorColumn = { link = "CursorLine" },
        ColorColumn = { link = "CursorLine" },
        VisualNOS = { link = "CursorLine" },
        LineNr = { fg = color.gray },
        CursorLineNr = { link = "LineNr" }, -- 左侧行的颜色
        -- LineNrAbove = { links = LineNr }, -- already link linenr
        -- LineNrBelow = { links = LineNr }, -- already link linenr

        -- statusline
        StatusLine = { fg = color.gray, bg = color.bg },
        StatusLineNC = { links = StatusLine },
        StatusLineTerm = { links = StatusLine },
        StatusLineTermNC = { links = StatusLine },
        -- TODO:
        -- Conceal = { color.debug } -- Conceal signal

        -- Not use
        -- DiffAdd             = { fg = c.none, bg = c.de_diff_add },
        -- DiffChange          = { fg = c.none, bg = c.de_diff_change },
        -- DiffDelete          = { fg = c.none, bg = c.de_diff_delete },
        -- DiffText            = { fg = c.none, bg = c.de_diff_text },
        -- DiffAdded           = colors.Green,
        -- DiffRemoved         = colors.Red,
        -- DiffFile            = colors.Cyan,
        -- DiffIndexLine       = colors.Grey,
    }
    syntax = {
        Comment = { fg = color.bg_gray },
        Function = { fg = color.blue },
        String = { fg = color.green },
        PreProc = { fg = color.test },
        Constant = { fg = color.orange },
        Delimiter = { fg = color.gray },
        Operator = { fg = color.gray },
    }
    treesitter = {
        ["@variable"] = { fg = color.fg },
        ["@variable.member"] = { fg = color.fg },
        ["@keyword"] = { fg = color.bg_light3 },
        ["@keyword.function"] = { fg = color.bg_light3 },
        ["@keyword.return"] = { fg = color.bg_light3 },
        ["@function.call"] = { fg = color.blue },
        ["@function.builtin"] = { fg = color.blue },
        ["@constructor"] = { links = Delimiter },
        ["@module.builtin"] = { fg = color.fg },
        ["@property"] = { fg = color.bg_light3 },
    }
    vim_highlights(common)
    vim_highlights(syntax)
    vim_highlights(treesitter)
end, {})

vim.cmd("Settheme")

------------------------------------------------------------------------
-- neovide config
------------------------------------------------------------------------
if vim.g.neovide then
    -- for macos keybind
    -- Allow clipboard copy paste in neovim
    vim.keymap.set("n", "<D-s>", ":w<CR>") -- Save
    vim.keymap.set("v", "<D-c>", '"+y') -- Copy
    vim.keymap.set("n", "<D-v>", '"+P') -- Paste normal mode
    vim.keymap.set("v", "<D-v>", '"+P') -- Paste visual mode
    vim.keymap.set("c", "<D-v>", "<C-R>+") -- Paste command mode
    vim.keymap.set("i", "<D-v>", '<ESC>l"+Pli') -- Paste insert mode
    vim.api.nvim_set_keymap("", "<D-v>", "+p<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("!", "<D-v>", "<C-R>+", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("t", "<D-v>", "<C-R>+", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("v", "<D-v>", "<C-R>+", { noremap = true, silent = true })

    -- 控制缩放
    vim.g.neovide_scale_factor = 1.0
    local change_scale_factor = function(delta)
        vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
    end
    vim.keymap.set("n", "<C-+>", function()
        change_scale_factor(1.25)
    end)
    vim.keymap.set("n", "<C-_>", function()
        change_scale_factor(1 / 1.25)
    end)

    -- blur & opacity
    vim.g.neovide_window_blurred = true
    vim.g.neovide_floating_blur_amount_x = 2.0
    vim.g.neovide_floating_blur_amount_y = 2.0

    -- float showdown
    vim.g.neovide_floating_shadow = true
    vim.g.neovide_floating_z_height = 10
    vim.g.neovide_light_angle_degrees = 45
    vim.g.neovide_light_radius = 5
    vim.g.neovide_floating_corner_radius = 0.5

    -- background not opacity , windows opacity
    vim.g.neovide_opacity = 0.8
    vim.g.neovide_opacity_point = 1
    vim.g.neovide_show_border = true

    -- disable some animal
    vim.g.neovide_scroll_animation_length = 0
    vim.g.neovide_cursor_animate_command_line = flase
    vim.g.neovide_cursor_animation_length = 0
    vim.g.neovide_cursor_short_animation_length = 0

    -- new feature
    vim.g.neovide_progress_bar_enabled = true
    vim.g.neovide_progress_bar_height = 5.0
    vim.g.neovide_progress_bar_animation_speed = 200.0
    vim.g.neovide_progress_bar_hide_delay = 0.2
    vim.g.neovide_cursor_hack = flase

    -- alt
    vim.g.neovide_input_macos_option_key_is_meta = "only_left"

    -- 输入法
    vim.g.neovide_input_ime = true
end

------------------------------------------------------------------------
-- lazy load plugin
------------------------------------------------------------------------
vim.defer_fn(function()
    require("lazy_load")
end, 500) -- 单位：ms
