------------------------------------------------------------------------
-- key mapping
------------------------------------------------------------------------
local map = vim.keymap.set
local unmap = vim.keymap.del

-- save file
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- ui move
map("n", "<Up>", "<cmd>resize -2<CR>", { desc = "Remove windows up" })
map("n", "<Down>", "<cmd>resize +2<CR>", { desc = "Remove windows down" })
map("n", "<Left>", "<cmd>vertical resize -2<CR>", { desc = "Remove windows left" })
map("n", "<Right>", "<cmd>vertical resize +2<CR>", { desc = "Remove windows right" })

-- comment
local comment_opts = { desc = "comment keybinding", remap = true }
map("n", "<C-/>", "gcc", comment_opts)
map("x", "<C-/>", "gc", comment_opts)
map("i", "<C-/>", function()
    -- 空行（只有空白）直接插入注释符，继续在 insert 里写注释；非空行照旧 gcc
    if vim.api.nvim_get_current_line():match("^%s*$") then
        local cs = vim.bo.commentstring
        if cs == "" then
            cs = "// %s"
        end
        local leader = cs:match("^(.-)%%s") or cs
        leader = leader:gsub("%%%%", "%%") -- commentstring 里 %% 表示字面的 %
        vim.api.nvim_feedkeys(leader, "n", false)
        return
    end
    vim.cmd.normal("gcc")
end, comment_opts)

-- oopen term
map("n", "<leader>t", function()
    vim.cmd("terminal")
    vim.cmd("startinsert")
end, { desc = "Open term" })

-- picker
map({ "n" }, "<leader><leader>", function()
    local term = require("terminal")
    local opts = {}
    -- 浮动终端开着时缩成小窗给 picker 让位，picker 关闭后恢复
    if term.resize_term_win() then
        opts.on_close = term.restore_term_win
    end
    -- 在浮动终端窗口里打开时，自动在输入框填入 term，只留 term:// 的 buffer 可选
    if term.in_float_win() then
        opts.default_text = "term"
    end
    require("refer.providers.builtin").buffers(opts)
end, { desc = "Smart Find Files" })

map({ "n" }, "<leader>f", function()
    vim.cmd("keepjumps Refer Files")
end, { desc = "Smart Find Files" })

map({ "n" }, "<leader>g", function()
    vim.cmd("keepjumps Refer Grep")
end, { desc = "Smart Find Files" })

map({ "n" }, "<leader>o", function()
    vim.cmd("keepjumps Refer OldFiles")
end, { desc = "Smart Find Files" })

-- flash
map({ "n", "x", "o" }, "s", function()
    require("flash").jump()
end, { desc = "Flash" })
map({ "n", "x", "o" }, "S", function()
    require("flash").treesitter()
end, { desc = "Flash Treesitter" })

-- file explore
map("n", "<leader>e", function()
    local dir = vim.fn.expand("%:p:h")
    local ok = pcall(vim.cmd, "edit " .. vim.fn.fnameescape(dir))
    if not ok then
        vim.cmd("edit ./")
    end
end, { desc = "Open current file directory" })

map("n", "<leader>E", "<CMD>e ./<CR>", { desc = "Open parent directory" })

vim.api.nvim_create_autocmd("FileType", {
    pattern = "directory",
    callback = function(args)
        map("n", ".", function()
            require("dir").trigger_showdotfile()
        end, {
            buffer = args.buf,
            desc = "Reload directory",
        })
        map("n", "d", function()
            vim.async.run(function()
                require("dir").delete_file()
            end)
        end, {
            buffer = args.buf,
            desc = "Delete file or directory",
        })
        map("x", "d", function()
            vim.async.run(function()
                require("dir").delete_range_file()
            end)
        end, {
            buffer = args.buf,
            desc = "Delete files in range",
        })
        map("n", "a", function()
            require("dir").add_file()
        end, {
            buffer = args.buf,
            desc = "Add file or directory",
        })
        map("n", "A", function()
            require("dir").add_range_file()
        end, {
            buffer = args.buf,
            desc = "Add range file or directory",
        })
        map("n", "r", function()
            require("dir").rename_file()
        end, {
            buffer = args.buf,
            desc = "Rename file or directory",
        })
        map("x", "r", function()
            require("dir").range_rename_file()
        end, {
            buffer = args.buf,
            desc = "Rename file or directory",
        })
        map("n", "p", function()
            vim.async.run(function()
                require("dir").copy_file()
            end)
        end, {
            buffer = args.buf,
            desc = "Copy file or directory",
        })
    end,
})

-- emcal style
map({ "c", "n", "x" }, "<C-a>", "<Home>", { noremap = true })
map({ "c", "n", "x" }, "<C-e>", "<end>", { noremap = true })
map({ "i" }, "<C-a>", "<C-o>^", { noremap = true })
map({ "i" }, "<C-e>", "<C-o>$", { noremap = true })
map({ "i", "c" }, "<C-f>", "<Right>", { noremap = true })
map("c", "<C-;>", "<C-f>")
map({ "i", "c" }, "<C-b>", "<left>", { noremap = true })

-- increaml selection
map("x", "<Tab>", function()
    require("vim.treesitter._select").select_parent(vim.v.count1)
end, { desc = "Expand selection" })

map("x", "<S-Tab>", function()
    require("vim.treesitter._select").select_child(vim.v.count1)
end, { desc = "Shrink selection" })

-- cmd panel
map("n", "<C-p>", function()
    require("cmd_panel").panel_pick()
end, { desc = "Command panel pick" })

-- code format
map({ "n", "v" }, "<leader>l", function()
    require("code_format").run_all_formatters()
end, { desc = "Close float windows and format code" })

-- terminal
map({ "n", "t" }, "<C-t>", function()
    require("terminal").toggle_term_win()
end, { desc = "toggle terminal win" })

map({ "n" }, "<C-w>t", function()
    require("terminal").swap_term_win()
end, { desc = "change terminal win location" })

-- code runner
map({ "n" }, "<leader>r", "<CMD>OverseerRun<CR>", { desc = "code runner picker" })
map({ "n" }, "<leader>v", "<CMD>OverseerToggle<CR>", { desc = "code buffer view" })

-- ai
map({ "n", "t" }, "<C-;>", function()
    local flt = require("pi-agent.surfaces.nvim_flt")
    if flt.win_id ~= nil and vim.api.nvim_win_is_valid(flt.win_id) and vim.api.nvim_get_current_win() == flt.win_id then
        require("pi-agent").close()
        require("imselect").to_en()
    else
        require("pi-agent").focus()
        require("imselect").switch("zh")
    end
end, { desc = "focus ai agent" })

map({ "x" }, "<C-;>", function()
    require("pi-agent").paste_selection_contents()
    require("pi-agent").focus()
    require("imselect").switch("zh")
end, { desc = "pi: Paste range location", noremap = true, silent = true })

-- pi-agent buffer：<C-d>/<C-u> 改为整页滚动
vim.api.nvim_create_autocmd("FileType", {
    pattern = "pi-agent",
    callback = function(args)
        local function passthrough(bytes)
            return function()
                local job = vim.b[args.buf].terminal_job_id
                if job then
                    vim.api.nvim_chan_send(job, bytes)
                end
            end
        end

        local opts = { buffer = args.buf, silent = true, desc = "pi: full page scroll" }
        -- t 模式：nvim 会把特殊键翻译成终端序列发给 pi
        vim.keymap.set("t", "<C-d>", "<PageDown>", opts)
        vim.keymap.set("t", "<C-u>", "<PageUp>", opts)
        -- n 模式（terminal-normal）不会转发按键，手动发 PageDown/PageUp 的终端序列
        vim.keymap.set("n", "<C-d>", passthrough("\27[6~"), opts)
        vim.keymap.set("n", "<C-u>", passthrough("\27[5~"), opts)
    end,
})

map("n", "<leader>d", require("pi_diff").review, { desc = "pi: diff 本轮改动 (codediff)" })
map("n", "<leader>r", require("pi_diff").rollback, { desc = "pi: 回滚本轮改动" })

-- for copy
map("x", "Y", '"+y', { desc = "for system copy" })
map({ "n" }, "P", '"+P', { desc = "for system past" })
map({ "x" }, "P", '"+P', { desc = "for system past" })

-- tab change
map("n", "H", "gT", { desc = "Previous tab" })
map("n", "L", "gt", { desc = "Next tab" })

vim.api.nvim_create_autocmd("TabEnter", {
    callback = function()
        vim.notify("Switch to tab " .. vim.api.nvim_tabpage_get_number(0), vim.log.levels.INFO)
    end,
})

-- buf change
map("n", "J", "<cmd>b#<cr>", { desc = "jump buf" })
map("n", "D", "<cmd>bd<cr>", { desc = "delete buf" })

-- surrand change
vim.keymap.set("x", "a", function()
    local srow, scol = unpack(vim.fn.getpos("v"), 2, 3)
    local erow, ecol = unpack(vim.fn.getpos("."), 2, 3)

    vim.cmd("normal! \27")
    local mode = vim.fn.visualmode()

    local char = vim.fn.getcharstr()
    if char == "\27" or char == "" then
        return
    end

    local pairs = {
        ["("] = ")",
        ["["] = "]",
        ["{"] = "}",
    }
    local close = pairs[char] or char

    if srow > erow or (srow == erow and scol > ecol) then
        srow, erow, scol, ecol = erow, srow, ecol, scol
    end

    srow, erow = srow - 1, erow - 1
    scol, ecol = scol - 1, ecol - 1

    if mode == "V" then
        scol = 0
        local line = vim.api.nvim_buf_get_lines(0, erow, erow + 1, false)[1] or ""
        ecol = #line
    else
        ecol = ecol + 1
    end

    vim.api.nvim_buf_set_text(0, erow, ecol, erow, ecol, { close })
    vim.api.nvim_buf_set_text(0, srow, scol, srow, scol, { char })
end, { desc = "Surround selection with a pair" })

map("x", "m", function()
    local api = vim.api
    local fn = vim.fn

    local char = fn.getcharstr()

    local pairs = {
        ['"'] = '"',
        ["'"] = "'",
        ["("] = ")",
        ["["] = "]",
        ["{"] = "}",
    }

    local close = pairs[char]
    if not close then
        return
    end

    -- 记录 Visual 选择的起止位置
    local s = fn.getpos("v")
    local e = fn.getpos(".")

    local srow, scol = s[2] - 1, s[3] - 1
    local erow, ecol = e[2] - 1, e[3] - 1

    -- 退出 Visual 模式，获取选择类型
    local mode = fn.visualmode()
    vim.cmd("normal! \27")

    -- 保证起点在前，终点在后
    if srow > erow or (srow == erow and scol > ecol) then
        srow, erow = erow, srow
        scol, ecol = ecol, scol
    end

    if mode == "V" then
        -- 行选择：在首行从左向右找开符号
        local first_line = api.nvim_buf_get_lines(0, srow, srow + 1, false)[1] or ""

        local old_open, open_col

        for i = 1, #first_line do
            local c = first_line:sub(i, i)

            if pairs[c] then
                old_open = c
                open_col = i - 1
                break
            end
        end

        if not old_open then
            return
        end

        -- 根据开符号确定旧闭符号
        local old_close = pairs[old_open]

        -- 在末行从右向左找对应闭符号
        local last_line = api.nvim_buf_get_lines(0, erow, erow + 1, false)[1] or ""

        local close_col

        for i = #last_line, 1, -1 do
            if last_line:sub(i, i) == old_close then
                close_col = i - 1
                break
            end
        end

        if not close_col then
            return
        end

        -- 先替换右侧，再替换左侧，避免列位置变化
        api.nvim_buf_set_text(0, erow, close_col, erow, close_col + 1, { close })
        api.nvim_buf_set_text(0, srow, open_col, srow, open_col + 1, { char })
    else
        -- 字符选择：从选区首字符开始找开符号
        local first_line = api.nvim_buf_get_lines(0, srow, srow + 1, false)[1] or ""
        local old_open, open_col

        for i = scol + 1, #first_line do
            local c = first_line:sub(i, i)

            if pairs[c] then
                old_open = c
                open_col = i - 1
                break
            end
        end

        if not old_open then
            return
        end

        -- 根据开符号找到对应的旧闭符号
        local old_close = pairs[old_open]
        local last_line = api.nvim_buf_get_lines(0, erow, erow + 1, false)[1] or ""
        local close_col

        for i = math.min(ecol + 1, #last_line), 1, -1 do
            if last_line:sub(i, i) == old_close then
                close_col = i - 1
                break
            end
        end

        if not close_col then
            return
        end

        -- 先替换右侧，再替换左侧
        api.nvim_buf_set_text(0, erow, close_col, erow, close_col + 1, { close })
        api.nvim_buf_set_text(0, srow, open_col, srow, open_col + 1, { char })
    end
end, { desc = "Surround: change surrounding symbols" })

local undotree = require("undotree")

vim.keymap.set("n", "<leader>u", function()
    undotree.open({
        command = "topleft 40vnew",
    })
end, { desc = "Open undotree" })

vim.api.nvim_create_autocmd("FileType", {
    pattern = "nvim-undotree",
    callback = function(args)
        map("n", "q", "<cmd>close<cr>", {
            buffer = args.buf,
            desc = "Close undotree",
        })
        map("n", "<CR>", function()
            vim.cmd("b#")
            local file = vim.api.nvim_buf_get_name(0)
            local tmp = "/tmp/nvimundofile"
            vim.cmd("q")
            vim.uv.fs_copyfile(file, tmp)
            vim.cmd("CodeDiff file " .. tmp .. " " .. file)
        end, {
            buffer = args.buf,
            desc = "diff view undotree",
        })
    end,
})

-- lua file
vim.api.nvim_create_autocmd("FileType", {
    pattern = "lua",
    once = true,
    callback = function()
        vim.pack.add({
            { src = "https://github.com/folke/lazydev.nvim" },
        })
        require("lazydev").setup()
        -- 没有 client attach 时 `lsp restart` 会写一条 E5805 错误并打断 FileType 回调，先判断是否存在 client
        if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
            vim.cmd("lsp restart")
        end
    end,
})

-- for C-o C-i
map("n", "gg", "<cmd>keepjumps normal! gg<CR>")
map("n", "G", "<cmd>keepjumps normal! G<CR>")
map("n", "n", "<cmd>keepjumps normal! n<CR>")
map("n", "N", "<cmd>keepjumps normal! N<CR>")

-- in the visual mode , p always replace the register
map("x", "p", "P", {
    desc = "Paste without overwriting register",
})

-- map x mode , O get vsiaul test then search in chrome
map("x", "O", function()
    -- getregion() 返回的是 List（每行一项），必须 concat 成字符串
    local text = table.concat(vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), {
        type = vim.fn.mode(), -- "v" / "V" / "\22"，保证 block/line 模式也对
    }), "\n")
    -- 用 rfc2396：默认的 rfc3986 不会转义 & + = / ; : @ $ ,，会破坏 query
    local url = "https://www.google.com/search?q=" .. vim.uri_encode(text, "rfc2396")
    vim.ui.open(url) -- 异步、跨平台、不闪屏
    vim.cmd("normal! gv") -- 可选：保留选区
end, { desc = "Search selection in Chrome" })
