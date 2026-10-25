------------------------------------------------------------------------
-- vim oion set
------------------------------------------------------------------------
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
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
vim.g.mapleader = " " -- set to leader key
vim.g.maplocalleader = "\\" -- disable maplocalleader

vim.o.inccommand = "split" -- Preview substitutions live, as you type!
vim.o.scrolloff = 10
vim.o.confirm = true
vim.o.jumpoptions = "stack" -- better CTRL-O CTRL-I
vim.o.autowrite = true -- auto write when "make" "last" "first" etc..
vim.o.autoread = true -- auto read when file change
vim.o.number = true -- 显示行号
vim.o.wrap = false -- 行内不折叠
vim.o.cmdheight = 0 -- 设置cmd height高度
vim.o.showcmdloc = "last" -- cmdloc的位置
vim.o.showtabline = 0 -- tab栏
vim.o.cursorline = true -- 当前行高亮
vim.o.splitbelow = true -- 窗口打开位置
vim.o.splitright = true -- 窗口打开位置
vim.o.tabstop = 4 -- 一个 tab 显示为 4 个空格
vim.o.shiftwidth = 0 -- 首行缩进时用 4 个空格
vim.o.softtabstop = 4 -- 插入模式按 Tab = 4 个空格
vim.o.expandtab = true -- Tab 转换为空格
vim.o.incsearch = true -- search as characters are entered
vim.o.ignorecase = true -- ignore case in searches by default
vim.o.smartcase = true -- but make it case sensitive if an uppercase is entered
vim.o.mouse = "a" -- mouse on
vim.o.undofile = true -- undo file
-- vim.o.wildmenu = false --  disable self cmp mini
-- vim.o.wildmode = "" --disable self cmp mini
vim.o.list = true -- 显示tab字符
vim.o.listchars = "tab:» ,nbsp:+,trail:·"
vim.o.virtualedit = "block"
vim.o.wildignorecase = true
vim.o.swapfile = false
vim.o.shortmess = "aoOTIcF"
vim.o.sidescrolloff = 5
vim.o.pumheight = 15
vim.o.pummaxwidth = 30
-- vim.o.pumborder = "rounded"
-- vim.o.fillchars = 'trunc:…'
vim.o.linebreak = true
vim.o.smoothscroll = true
-- vim.o.textwidth = 80
-- vim.o.colorcolumn = "+0"
-- vim.o.winborder = "rounded"
-- vim.o.laststatus = 0
vim.o.signcolumn = "yes"
-- vim.opt.signcolumn = "yes"
-- vim.opt.statuscolumn = "%C%=%l %s"
vim.o.updatetime = 600

-- 设置折叠方法为表达式 (expr)
-- 用 vim.o（全局默认）而不是 vim.wo[0][0]（只作用于启动窗口），否则 :tabnew 出来的
-- 窗口会退回 foldmethod=manual，树解析折叠失效（focus_tab 就是 tabnew）。
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldmethod = "expr"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
-- local messagesopt_full = "hit-enter,history:500,maxheight:50,pager:<CR>,progress:,timeout:2000"
-- vim.o.messagesopt = "hit-enter,history:500,progress:"

vim.cmd.colorscheme("bamboo_bamboo")
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
    vim.keymap.set("t", "<D-v>", function()
        vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
    end, { noremap = true, silent = true })

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
    vim.g.neovide_floating_blur_amount_x = 5.0
    vim.g.neovide_floating_blur_amount_y = 5.0

    -- float showdown
    vim.g.neovide_floating_shadow = true
    vim.g.neovide_floating_z_height = 10
    vim.g.neovide_light_angle_degrees = 45
    vim.g.neovide_light_radius = 5
    vim.g.neovide_floating_corner_radius = 0.5

    -- background not opacity , windows opacity
    vim.g.neovide_opacity = 0.8
    vim.g.neovide_show_border = true

    -- disable some animal
    vim.g.neovide_scroll_animation_length = 0
    vim.g.neovide_cursor_animation_length = 0
    vim.g.neovide_cursor_short_animation_length = 0
    vim.g.neovide_cursor_trail_size = 0
    vim.g.neovide_cursor_animate_in_insert_mode = false
    vim.g.neovide_cursor_animate_command_line = false
    -- vim.g.neovide_cursor_vfx_mode = "pixiedust"
    -- vim.g.neovide_cursor_vfx_opacity = 500.0
    -- vim.g.neovide_cursor_vfx_particle_lifetime = 5
    -- vim.g.neovide_cursor_vfx_particle_density = 1
    -- vim.g.neovide_cursor_vfx_particle_speed = 10.0

    -- new feature
    vim.g.neovide_progress_bar_enabled = true
    vim.g.neovide_progress_bar_height = 5.0
    vim.g.neovide_progress_bar_animation_speed = 200.0
    vim.g.neovide_progress_bar_hide_delay = 0.2
    vim.g.neovide_cursor_hack = false

    -- alt
    vim.g.neovide_input_macos_option_key_is_meta = "both"

    -- 输入法
    vim.g.neovide_input_ime = true
    vim.g.neovide_hide_mouse_when_typing = true

    vim.g.experimental_layer_grouping = true
    -- vim.g.neovide_scroll_animation_far_lines = 1000

    -- scrollbar
    -- vim.g.neovide_system_scrollbar = true
end

------------------------------------------------------------------------
-- cwd / $PWD
------------------------------------------------------------------------
-- nvim 的 :cd 只改进程 cwd，不改环境变量 $PWD。终端里 zsh 会替我们维护 PWD，
-- 但 neovide 直接把自己的 PWD 透给 nvim 子进程，之后就不再管了（neovide 源码里
-- 没有 DirChanged 处理，它的 cwd 是进程级、启动时定死）。所以 neovide 下 :cd 之后
-- $PWD 还是启动目录，凡是读 env PWD 的插件/子进程都会看到旧目录。这里手动同步。
local function sync_pwd()
    vim.env.PWD = vim.uv.cwd()
end
vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, { callback = sync_pwd })

------------------------------------------------------------------------
-- lazy load plugin
------------------------------------------------------------------------
vim.schedule(function()
    -- loading the clipboard provider at startup costs a few ms
    -- vim.o.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" -- Sync with system clipboard
    vim.o.quickfixtextfunc = require("quickfix").quickfixtextfunc
    vim.cmd.packadd("nohlsearch")
    vim.cmd.packadd("nvim.undotree")
    vim.cmd("clearjumps")
    vim.t.tab_title = "main"
    vim.cmd("redrawtabline")
    vim.pack.add({
        { src = "https://github.com/L3MON4D3/LuaSnip", version = vim.version.range("2.*") },
        { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("*") },
        "https://github.com/mfussenegger/nvim-lint",
        "https://github.com/stevearc/conform.nvim",
        "https://github.com/folke/flash.nvim",
        "https://github.com/esmuellert/codediff.nvim",
        "https://github.com/juniorsundar/refer.nvim",
        "https://github.com/folke/lazydev.nvim",
        "https://github.com/stevearc/overseer.nvim",
        "https://github.com/zhangwwpeng/pi-agent.nvim",
        "https://github.com/nvim-mini/mini.diff",
        "https://github.com/milanglacier/minuet-ai.nvim",
        "https://github.com/cursortab/cursortab.nvim",
        "https://github.com/obsidian-nvim/obsidian.nvim",
        "https://github.com/ellisonleao/gruvbox.nvim",
        "https://github.com/nvim-treesitter/nvim-treesitter-context",
        "https://github.com/neanias/everforest-nvim",
        "https://github.com/ribru17/bamboo.nvim",
        "https://github.com/folke/tokyonight.nvim",
    })
    require("grep")
    require("run")
    require("code_lint").setup()
    require("code_format").setup()
    require("code_lsp").setup()
    require("code_edit").setup()
    require("code_treesitter").setup()
    require("code_snip").setup()
    require("code_completion").setup()
    require("code_git").setup()
    require("focus_tab").setup()
    require("cmd_panel").setup()
    require("code_picker").setup()
    require("indent")
    require("imselect").setup()
    require("dir").setup()
    require("terminal").setup()
    require("pi-agent").setup()
    require("pi_diff").setup()
    require("flash_cfg")
    require("keymaps")
    require("ui").setup()
    require("markdown_tabfmt").setup()
    require("markdown_hlcode").setup()
    require("ai").setup()
    require("obsidian_cfg").setup()
    require("treesitter_context_cfg").setup()
    require("side_bar").setup()
end)
