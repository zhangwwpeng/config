------------------------------------------------------------------------
-- vim option set
------------------------------------------------------------------------
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
vim.g.mapleader = " " -- set to leader key
vim.g.maplocalleader = "\\" -- disable maplocalleader
vim.g.bigfile_size = 1024 * 1024 * 1.5 -- 1.5 MB
-- vim.opt.inccommand = "split" -- Preview substitutions live, as you type!
vim.opt.scrolloff = 10
vim.opt.confirm = true
vim.opt.jumpoptions = "stack" -- better CTRL-O CTRL-I
vim.opt.autowrite = true -- auto write when "make" "last" "first" etc..
vim.opt.autoread = true -- auto read when file change
vim.opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" -- Sync with system clipboard
vim.opt.number = true -- 显示行号
vim.opt.wrap = false -- 行内不折叠
vim.opt.list = true -- 显示tab字符
vim.opt.cmdheight = 0 -- 设置cmd height高度
vim.opt.showcmdloc = "last" -- cmdloc的位置
vim.opt.showtabline = 0 -- tab栏
vim.opt.cursorline = true -- 当前行高亮
vim.opt.splitbelow = true -- 窗口打开位置
vim.opt.splitright = true -- 窗口打开位置
vim.opt.tabstop = 4 -- 一个 tab 显示为 4 个空格
vim.opt.shiftwidth = 0 -- 首行缩进时用 4 个空格
vim.opt.softtabstop = 4 -- 插入模式按 Tab = 4 个空格
vim.opt.expandtab = true -- Tab 转换为空格
vim.opt.incsearch = true -- search as characters are entered
vim.opt.ignorecase = true -- ignore case in searches by default
vim.opt.smartcase = true -- but make it case sensitive if an uppercase is entered
vim.opt.mouse = "a" -- mouse on
vim.opt.undofile = true -- undo file
-- vim.opt.wildmenu = false --  disable self cmp mini
-- vim.opt.wildmode = "" --disable self cmp mini
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.signcolumn = "number" -- lsp signal

-- 设置折叠方法为表达式 (expr)
vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.wo[0][0].foldmethod = "expr"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

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
    vim.g.neovide_cursor_animate_command_line = false
    vim.g.neovide_cursor_animation_length = 0
    vim.g.neovide_cursor_short_animation_length = 0

    -- new feature
    vim.g.neovide_progress_bar_enabled = true
    vim.g.neovide_progress_bar_height = 5.0
    vim.g.neovide_progress_bar_animation_speed = 200.0
    vim.g.neovide_progress_bar_hide_delay = 0.2
    vim.g.neovide_cursor_hack = false

    -- alt
    vim.g.neovide_input_macos_option_key_is_meta = "only_left"

    -- 输入法
    vim.g.neovide_input_ime = true
    vim.g.neovide_hide_mouse_when_typing = true
    vim.g.neovide_cursor_smooth_blink = true
end

------------------------------------------------------------------------
-- RPC init (lazy: child nvim processes spawn on first <C-t> / <C-,>)
------------------------------------------------------------------------

vim.api.nvim_create_autocmd("UIEnter", {
    once = true,
    callback = function()
        Flt_term_chan = -1
        Sub_term_chan = -1
        Remote_flt_term_buf = vim.api.nvim_create_buf(false, true)
        Remote_sub_term_buf = vim.api.nvim_create_buf(false, true)
        vim.g.flt_term_servrename = vim.v.servername .. "_flt"
        vim.g.sub_term_servrename = vim.v.servername .. "_sub"
    end,
})

------------------------------------------------------------------------
-- lazy load plugin
------------------------------------------------------------------------
vim.schedule(function()
    vim.pack.add({
        { src = "https://github.com/L3MON4D3/LuaSnip", version = vim.version.range("2.*") },
        { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("*") },
        -- "https://github.com/nvim-mini/mini.cmdline",
        -- "https://github.com/nvim-mini/mini.completion",
        "https://github.com/mfussenegger/nvim-lint",
        "https://github.com/stevearc/conform.nvim",
        "https://github.com/folke/snacks.nvim",
        "https://github.com/folke/flash.nvim",
        "https://github.com/stevearc/oil.nvim",
        "https://github.com/esmuellert/codediff.nvim",
        "https://github.com/kevinhwang91/nvim-bqf",
    })
    require("session").setup()
    require("code_lint").setup()
    require("code_format").setup()
    require("code_lsp").setup()
    require("code_edit").setup()
    require("code_tressiter").setup()
    require("code_snip").setup()
    require("code_completion").setup()
    require("focus_tab").setup()
    require("cmd_panel").setup()
    require("vim._core.ui2").enable()
    require("bqf").setup()

    -- TODO
    require("config")
end)

------------------------------------------------------------------------
-- load plugin
------------------------------------------------------------------------

vim.pack.add({
    { src = "https://github.com/nvim-mini/mini.input" },
    { src = "https://github.com/nvim-mini/mini.nvim", version = "stable" },
    { src = "https://github.com/folke/lazydev.nvim" },
    { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
    { src = "https://github.com/tjgao/quickbuf.nvim" },
    { src = "https://github.com/rachartier/tiny-cmdline.nvim" },
})

vim.loader.enable()

require("ui2")
require("theme").setup()
require("ui").setup()
require("code_preview").setup()
require("keymaps")
require("aichat")
require("mini.pick").setup()
require("render-markdown").setup({
    render_modes = true,
    anti_conceal = { enabled = false },
    heading = {
        icons = { "一、", "二、", "三、", "四、", "五、", "六、" },
    },
    pipe_table = {
        -- border_enabled = false,
        border_virtual = true,
    },
    code = {
        border = "language",
    },
})

require("mini.input").setup({})
vim.ui.input = MiniInput.ui_input

------------------------------------------------------------------------
-- AI Diff command
------------------------------------------------------------------------
vim.api.nvim_create_user_command("AiDiff", function(opts)
    local session_name, cwd_path = unpack(opts.fargs)
    local root_path = vim.fn.expand("~/.cache/nvim/ai-diff/sessions") .. "/" .. session_name

    -- Scan root_path for snapshot files only
    local files = vim.fn.glob(root_path .. "/**/*", false, true)
    local pairs = {}
    for _, f in ipairs(files) do
        if vim.fn.isdirectory(f) == 0 then
            local rel = f:sub(#root_path + 2)
            local target = cwd_path .. "/" .. rel
            if vim.fn.filereadable(target) == 1 then
                pairs[#pairs + 1] = { f, target }
            end
        end
    end

    if #pairs == 0 then
        vim.notify("No snapshot files found in " .. root_path, vim.log.levels.WARN)
        vim.fn.system("touch /tmp/aidiff_" .. session_name)
        return
    end

    local lifecycle = require("codediff.ui.lifecycle")
    local original_tab = vim.api.nvim_get_current_tabpage()

    for _, pair in ipairs(pairs) do
        -- Switch away from diff tab to avoid toggle-close
        local cur = vim.api.nvim_get_current_tabpage()
        if lifecycle.get_session(cur) then
            vim.api.nvim_set_current_tabpage(original_tab)
        end

        vim.cmd("CodeDiff file " .. pair[1] .. " " .. pair[2])

        -- Block until diff view is loaded
        vim.wait(10000, function()
            local t = vim.api.nvim_get_current_tabpage()
            return lifecycle.get_session(t) ~= nil
        end, 10)
    end

    -- Signal shell that all diffs are ready
    vim.fn.system("touch /tmp/aidiff_" .. session_name)
end, {
    nargs = "+",
    desc = "AI Diff: review, accept, rollback, or list AI modification sessions",
})
