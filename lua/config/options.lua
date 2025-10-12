local opt = vim.opt
local glb = vim.g

------------------------------------------------------------------------
-- Set to leader key
------------------------------------------------------------------------
glb.mapleader = " "
glb.maplocalleader = "\\"

------------------------------------------------------------------------
-- Disable nvim plugin
------------------------------------------------------------------------
-- glb.loaded_gzip = 1
-- glb.loaded_matchit = 1
-- glb.loaded_matchparen = 1
-- glb.loaded_netrwPlugin = 1
-- glb.loaded_tarPlugin = 1
-- glb.loaded_tutor = 1
-- glb.loaded_zipPlugin = 1

------------------------------------------------------------------------
-- Enable auto write
------------------------------------------------------------------------
opt.autowrite = true
opt.autoread = true

------------------------------------------------------------------------
-- Sync with system clipboard
------------------------------------------------------------------------
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"

------------------------------------------------------------------------
-- UI setting
------------------------------------------------------------------------
opt.number = false -- 显示行号
opt.wrap = false -- 行内不折叠
opt.list = true -- 显示tab字符
opt.cmdheight = 0 -- 设置cmd height高度
opt.laststatus = 3 -- 设置stat line永远一行
opt.showcmdloc = "statusline" -- cmdloc的位置
opt.showtabline = 0 -- tab栏
opt.cursorline = true -- 当前行高亮
opt.splitbelow = true -- 窗口打开位置
opt.splitright = true -- 窗口打开位置
opt.winborder = "rounded" -- 窗口圆角
opt.relativenumber = false -- 相对行号

glb.zen_mode = true -- 设置启动开启zen mode

------------------------------------------------------------------------
-- Tab setting
------------------------------------------------------------------------
opt.tabstop = 4 -- 一个 tab 显示为 4 个空格
opt.shiftwidth = 0 -- 首行缩进时用 4 个空格
opt.softtabstop = 4 -- 插入模式按 Tab = 4 个空格
opt.expandtab = true -- Tab 转换为空格

------------------------------------------------------------------------
-- Search setting
------------------------------------------------------------------------
opt.incsearch = true -- search as characters are entered
opt.hlsearch = false -- do not highlight matches
opt.ignorecase = true -- ignore case in searches by default
opt.smartcase = true -- but make it case sensitive if an uppercase is entered

------------------------------------------------------------------------
-- tab setting
------------------------------------------------------------------------
vim.t.name = "Editor"

------------------------------------------------------------------------
-- State line config
------------------------------------------------------------------------
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
-- Mouse support
------------------------------------------------------------------------
opt.mouse = "a"

------------------------------------------------------------------------
-- Other basic config
------------------------------------------------------------------------
opt.undofile = true
glb.bigfile_size = 1024 * 1024 * 1.5 -- 1.5 MB

------------------------------------------------------------------------
-- Close tab cmp in cmd line
------------------------------------------------------------------------
opt.wildmenu = false
opt.wildmode = ""
