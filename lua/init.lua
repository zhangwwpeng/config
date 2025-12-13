------------------------------------------------------------------------
-- vim option set
------------------------------------------------------------------------
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
    -- vim.notify("main_bg set to " .. color, vim.log.levels.INFO)
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
-- key mapping
------------------------------------------------------------------------
local map = vim.keymap.set
local unmap = vim.keymap.del

-- save file
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
map({ "i", "x", "n", "s" }, "<C-q>", "<cmd>q<cr><esc>", { desc = "Save File and Quit nvim" })

-- ui move
map("n", "<Up>", "<cmd>resize -2<CR>", { desc = "Remove windows up" })
map("n", "<Down>", "<cmd>resize +2<CR>", { desc = "Remove windows down" })
map("n", "<Left>", "<cmd>vertical resize -2<CR>", { desc = "Remove windows left" })
map("n", "<Right>", "<cmd>vertical resize +2<CR>", { desc = "Remove windows right" })

-- yazi
map({ "n", "v" }, "<leader>e", "<cmd>Yazi toggle<cr>", { desc = "Open yazi at the current file" })

-- comment
local comment_opts = { desc = "comment keybinding", remap = true }
map("n", "<C-/>", "gcc", comment_opts)
map("x", "<C-/>", "gc", comment_opts)
map("i", "<C-/>", function()
    vim.cmd.normal("gcc")
end, comment_opts)

-- code format
map({ "i", "n", "v" }, "<C-l>", function()
    require("conform").format({ async = true })
end, { desc = "Formate Code" })

-- cmd
map("c", "<C-a>", "<Home>", { noremap = true })

------------------------------------------------------------------------
-- Start Load LSP
------------------------------------------------------------------------
vim.lsp.enable({
    "lua_ls", -- lua
    "perlnavigator", -- perl
})

------------------------------------------------------------------------
-- install plugin
------------------------------------------------------------------------
vim.pack.add({
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") },
    { src = "https://github.com/stevearc/conform.nvim" },
    { src = "https://github.com/folke/snacks.nvim" },
    { src = "https://github.com/folke/noice.nvim" },
    { src = "https://github.com/MunifTanjim/nui.nvim" },
})

------------------------------------------------------------------------
-- Plugin config
------------------------------------------------------------------------
-- require('nvim-treesitter').install({ 'systemverilog', 'c', 'python', 'shell' }):wait(300000) -- wait max. 5 minutes
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "systemverilog", "c", "python", "shell" },
    callback = function()
        vim.treesitter.start()
    end,
})
require("snacks").setup({
    input = {
        icon = " ",
        icon_hl = "SnacksInputIcon",
        icon_pos = "left",
        prompt_pos = "title",
        win = { style = "input" },
        expand = true,
    },
})
require("blink.cmp").setup({
    -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
    -- 'super-tab' for mappings similar to vscode (tab to accept)
    -- 'enter' for enter to accept
    -- 'none' for no mappings
    --
    -- All presets have the following mappings:
    -- C-space: Open menu or open docs if already open
    -- C-n/C-p or Up/Down: Select next/previous item
    -- C-e: Hide menu
    -- C-k: Toggle signature help (if signature.enabled = true)
    --
    -- See :h blink-cmp-config-keymap for defining your own keymap
    keymap = {
        preset = "none",
        ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
        ["<C-n>"] = { "select_next", "fallback_to_mappings" },

        ["<C-y>"] = { "select_and_accept", "fallback" },

        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
    },

    appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = "mono",
    },

    -- (Default) Only show the documentation popup when manually triggered
    completion = {
        documentation = { auto_show = true },
        accept = {
            -- experimental auto-brackets support
            auto_brackets = {
                enabled = true,
            },
        },
        menu = {
            draw = {
                treesitter = { "lsp" },
            },
        },
        list = { selection = { preselect = false, auto_insert = true } },
    },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        providers = {
            path = {
                name = "Path",
                module = "blink.cmp.sources.path",
                score_offset = 3,
                opts = {
                    trailing_slash = false,
                    label_trailing_slash = true,
                    get_cwd = function(context)
                        return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
                    end,
                    show_hidden_files_by_default = false,
                },
            },
        },
    },

    -- significantly
    signature = { enabled = true },

    -- cmd line setting
    cmdline = {
        enabled = true,
        keymap = {
            preset = "cmdline",
            ["<Right>"] = false,
            ["<Left>"] = false,
        },
        completion = {
            list = { selection = { preselect = false } },
            menu = {
                auto_show = function(ctx)
                    return vim.fn.getcmdtype() == ":"
                end,
            },
            ghost_text = { enabled = true },
        },
    },

    -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
    -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
    -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
    --
    -- See the fuzzy documentation for more information
    fuzzy = { implementation = "prefer_rust_with_warning" },
})
require("conform").setup({
    -- Define your formatters
    formatters_by_ft = {
        lua = { "stylua" },
        perl = { "perltidy" },
        python = { "isort", "black" },
    },
    -- Set default options
    default_format_opts = {
        lsp_format = "never",
    },
    -- Set up format-on-save
    -- format_on_save = { timeout_ms = 500 },
    -- Customize formatters
    formatters = {
        shfmt = {
            append_args = { "-i", "2" },
        },
        stylua = {
            append_args = { "--indent-type", "Spaces" },
        },
    },
})
require("indent").setup()
require("vim._extui").enable({
    enable = true, -- Whether to enable or disable the UI.
    msg = { -- Options related to the message module.
        ---@type 'cmd'|'msg' Where to place regular messages, either in the
        ---cmdline or in a separate ephemeral message window.
        target = "cmd",
        timeout = 4000, -- Time a message is visible in the message window.
    },
})
require("noice").setup({
    cmdline = {
        enabled = true, -- enables the Noice cmdline UI
        view = "cmdline_popup", -- view for rendering the cmdline. Change to `cmdline` to get a classic cmdline at the bottom
        opts = {}, -- global options for the cmdline. See section on views
        ---@type table<string, CmdlineFormat>
        format = {
            -- conceal: (default=true) This will hide the text in the cmdline that matches the pattern.
            -- view: (default is cmdline view)
            -- opts: any options passed to the view
            -- icon_hl_group: optional hl_group for the icon
            -- title: set to anything or empty string to hide
            cmdline = { pattern = "^:", icon = "", lang = "vim" },
            search_down = { kind = "search", pattern = "^/", icon = "", lang = "regex" },
            search_up = { kind = "search", pattern = "^%?", icon = "", lang = "regex" },
            -- filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
            -- lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "", lang = "lua" },
            -- help = { pattern = "^:%s*he?l?p?%s+", icon = "" },
            input = { view = "cmdline_input", icon = "󰥻 " }, -- Used by input()
            lua = false, -- to disable a format, set to `false`
            filter = false,
            help = false,
        },
    },
    messages = { enabled = false },
    popupmenu = { enabled = false },
    redirect = { filter = {} },
    notify = { enabled = false },
    presets = { command_palette = true },
    health = { checker = true },
    lsp = { progress = { enabled = true }, hover = { enabled = false }, signature = { enabled = true } },
    documentation = { opts = { replace = true } },
})
