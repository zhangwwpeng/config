------------------------------------------------------------------------
-- Load vim.opt setting and auto commands
------------------------------------------------------------------------

-- require("config.util")
-- require("config.vim.options")
-- require("config.autocmds")
require("config.keymaps")

------------------------------------------------------------------------
-- Start Load LSP
------------------------------------------------------------------------
vim.lsp.enable({
    "lua_ls", -- lua
    "perlnavigator", -- perl
})

------------------------------------------------------------------------
-- vim option set
------------------------------------------------------------------------
vim.g.mapleader = " " -- set to leader key
vim.g.maplocalleader = "\\" -- disable maplocalleader
vim.g.bigfile_size = 1024 * 1024 * 1.5 -- 1.5 MB
vim.o.list = true -- signal visual
vim.o.inccommand = 'split' -- Preview substitutions live, as you type!
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
vim.opt.winborder = "rounded" -- 窗口圆角
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
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

------------------------------------------------------------------------
-- stateline
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
    "%<", -- 截断
    "%-.80F", -- 文件路径
    "%m%r", -- 文件buf属性
    "%=", -- 分割
    "%.S", -- cmd显示
    "  %{v:lua.current_macro_status()}", -- 展示宏录制
    "  %.(%l  ALL:%L%)", -- 行数
    "  %{v:lua.current_tab_name()}", -- 展示tab的名字
    "  %3.p%%", -- 百分比
}
vim.o.statusline = table.concat(statusline, "")

------------------------------------------------------------------------
-- colorscheme
------------------------------------------------------------------------
local function vim_highlights(highlights)
    for group_name, group_settings in pairs(highlights) do
        vim.api.nvim_set_hl(0, group_name, group_settings)
    end
end

vim.api.nvim_create_user_command("USERsetbg", function(opts)
    vim.g.main_bg = opts.args
    -- vim.notify("main_bg set to " .. color, vim.log.levels.INFO)
    color = {
        debug = '#ffffff', -- for debug color
        bg = '#000000',
        fg = '#f2e9d2',
        blue = '#6dceeb'
    }
    common = {
        -- main windows
        Normal = { fg = color.fg, bg = color.bg },   -- active windows下配色
        NormalNC = { link = 'Normal' },   -- non active windows下配色
        NormalFloat = { link = 'Normal' },   -- float windows下配色
        Terminal = { link = 'Normal' },   -- Terminal 配色
        EndOfBuffer = { link = 'Normal' }, -- end buf 配色
        -- FloatBorder = { fg = color.fg , bg = color.bg }, -- 浮动窗口外边 already link normalflaot
        -- FloatTitle = { bg = c.main_bg }, -- already link tittle
        -- FloatFooter = { bg = c.main_bg }, -- already link float title
        -- Fold
        -- FoldColumn = { fg = c.main_blue, bg = c.main_bg }, -- 折叠的符号 already link SignColumn
        Folded = { fg = color.blue, bg = color.bg }, -- 折叠的那一行
        SignColumn = { bg = color.debug, fg = color.debug }, -- 符号

        -- TODO:
        CursorLine = { fg = none , bg = color.debug}, -- 当前行高亮
        Visual = { fg = none , bg = color.debug },
        Cursor = { fg = color.bg, bg = color.fg }, -- Cursour
        lCursor = { link = 'Cursor' },
        CursorIM = { link = 'Cursor' },
        CursorColumn = { link = 'CursorLine' },
        ColorColumn = { link = 'CursorLine' },
        VisualNOS = { link = 'CursorLine' },

        CursorLineNr = { fg = colo.debug }, -- 左侧行的颜色
        LineNr = { fg = color.debug }
        -- LineNrAbove = { links = LineNr }, -- already link linenr
        -- LineNrBelow = { links = LineNr }, -- already link linenr
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
    vim_highlights(common)
end, {
    nargs = 1, -- 必须传一个参数
})

vim.cmd('USERsetbg #123456')
