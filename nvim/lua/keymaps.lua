------------------------------------------------------------------------
-- key mapping
------------------------------------------------------------------------
local map = vim.keymap.set

-- save file
map({ "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- ui move
map("n", "<Up>", "<cmd>resize -2<CR>", { desc = "Resize window: height -2" })
map("n", "<Down>", "<cmd>resize +2<CR>", { desc = "Resize window: height +2" })
map("n", "<Left>", "<cmd>vertical resize -2<CR>", { desc = "Resize window: width -2" })
map("n", "<Right>", "<cmd>vertical resize +2<CR>", { desc = "Resize window: width +2" })

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

-- open term
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
end, { desc = "Find buffers" })

map({ "n" }, "<leader>f", function()
    vim.cmd("keepjumps lua require('code_picker').files()") -- 支持 `搜索词; -参数`，见 code_picker.lua
end, { desc = "Find files" })

map({ "n" }, "<leader>g", function()
    vim.cmd("keepjumps Refer Grep")
end, { desc = "Live grep" })

map({ "n" }, "<leader>o", function()
    vim.cmd("keepjumps Refer OldFiles")
end, { desc = "Recent files" })

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

---目录 buffer 的文件操作键位
---@param args { buf: integer }
local function setup_directory_keymaps(args)
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
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "directory",
    callback = setup_directory_keymaps,
})

-- emacs style
map({ "c" }, "<C-a>", "<Home>", { noremap = true })
map({ "c", "x" }, "<C-e>", "<end>", { noremap = true })
map({ "n", "o" }, "<C-e>", "$", { noremap = true })
-- n：光标下是数字就照常 <C-a> 加一（计数会保留），否则跳到行首
map("n", "<C-a>", function()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    return vim.api.nvim_get_current_line():sub(col + 1, col + 1):match("%d") and "<C-a>" or "^"
end, { expr = true, desc = "Increment number under cursor, or go to line start" })
map("o", "<C-a>", "^", { desc = "Line start (first non-blank)" })
map({ "i" }, "<C-a>", "<C-o>^", { noremap = true })
map({ "i" }, "<C-e>", "<C-o>$", { noremap = true })
map({ "i", "c" }, "<C-f>", "<Right>", { noremap = true })
map("c", "<C-;>", "<C-f>")
map({ "i", "c" }, "<C-b>", "<left>", { noremap = true })

-- incremental selection
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
end, { desc = "Format code (conform + sv_format)" })

-- terminal
map({ "n", "t" }, "<C-t>", function()
    require("terminal").toggle_term_win()
end, { desc = "toggle terminal win" })

map({ "n" }, "<C-w>t", function()
    require("terminal").swap_term_win()
end, { desc = "change terminal win location" })

-- code runner
map({ "n" }, "<leader>r", "<CMD>Rerun<CR>", { desc = "code run last command" })

vim.cmd([[cnoreabbrev <expr> run (getcmdtype() ==# ':' && getcmdline() ==# 'run') ? 'Run' : 'run']])

-- ai
map({ "n", "t" }, "<C-;>", function()
    require("agent").toggle()
end, { desc = "Toggle AI agent float (pi / claude)" })

map({ "x" }, "<C-;>", function()
    require("agent").send_selection()
end, { desc = "Send selection to AI agent (pi / claude)", silent = true })

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
        -- n 模式（terminal-normal）不会把按键转发给终端：<C-c> 手发一个 Esc 给 pi（中断当前回复）
        vim.keymap.set("n", "<C-c>", passthrough("\27"), {
            buffer = args.buf,
            silent = true,
            desc = "pi: interrupt (send Esc)",
        })
    end,
})

-- for copy
map("x", "Y", '"+y', { desc = "for system copy" })
-- P：从系统剪贴板粘到光标后面（等价于 "<Right>"+P，但后者在空行/行尾会失败）
map("n", "P", '"+p', { desc = "Paste from system clipboard" })
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

-- macro / file info：q 让给了“看文件信息”，录制宏换到 Q，<C-q> 重放上一次宏
---@param bytes integer 负值（取不到大小）返回 "-"
---@return string 人类可读的大小，如 "1.2 KB" / "3.4 MB"
local function human_size(bytes)
    if bytes < 0 then
        return "-"
    end

    local units = { "B", "KB", "MB", "GB", "TB" }
    local n, i = bytes, 1
    while n >= 1024 and i < #units do
        n = n / 1024
        i = i + 1
    end

    if i == 1 then
        return n .. " B"
    end

    return n < 100 and ("%.1f %s"):format(n, units[i]) or ("%.0f %s"):format(n, units[i])
end

map("n", "<C-q>", "@@", { desc = "repeat macro" })

-- “上次执行过的宏”寄存器：Neovim 没有现成变量（v:register 恒为 "，reg_recorded() 只是上次*录制*的），
-- 所以拦一次 n 模式的 @，把寄存器名记下来。计数不用自己回传，映射天然会保留。
map("n", "@", function()
    local reg = vim.fn.getcharstr()
    if reg == "" or reg:byte() == 27 then
        return ""
    end
    if reg ~= "@" then -- @@ 时保持上一个
        vim.g.last_macro_reg = reg
    end
    return "@" .. reg
end, { expr = true, desc = "Run macro (remember register)" })

---上次执行过的宏寄存器；没跑过就退回本次会话录制的宏
---@return string?
local function last_macro_reg()
    local reg = vim.g.last_macro_reg
    if reg == nil or reg == "" then
        reg = vim.fn.reg_recorded()
    end
    return (reg ~= nil and reg ~= "") and reg or nil
end

map("x", "<C-q>", function()
    local reg = last_macro_reg()
    -- 没宏可放，或不是行选择（非 V 时保留 v_Q 的默认行为）
    if reg == nil or vim.fn.mode() ~= "V" then
        return "Q"
    end
    return ":normal! @" .. reg .. "<CR>"
end, { silent = true, expr = true, desc = "Replay last executed macro on selected lines" })
map("n", "Q", "q", { desc = "Record macro (was q)" })
map("n", "q", function()
    -- -- 正在录制宏时，q 应该停录制（normal! 绕过映射，才是内置的 q）
    -- if vim.fn.reg_recording() ~= "" then
    --     vim.cmd("normal! q")
    --     return
    -- end

    local buf = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(buf)
    local path = name ~= "" and vim.fn.fnamemodify(name, ":~:.") or "[No Name]"

    local lines = vim.api.nvim_buf_line_count(buf)
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local size = name ~= "" and vim.fn.getfsize(name) or -1

    local clients = {}
    for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
        clients[#clients + 1] = c.name
    end

    table.sort(clients)

    local flags = table.concat(
        vim.tbl_filter(function(f)
            local on = ({
                modified = vim.bo[buf].modified,
                readonly = vim.bo[buf].readonly,
                new = name == "",
                terminal = vim.bo[buf].buftype == "terminal",
            })[f]
            return on and f or false
        end, { "modified", "readonly", "new", "terminal" }),
        ","
    )

    local info = {
        ("file    : %s"):format(path),
        ("ft      : %s    lines: %d    size: %s"):format(
            vim.bo[buf].filetype ~= "" and vim.bo[buf].filetype or "unknown",
            lines,
            human_size(size)
        ),
        ("cursor  : %d:%d (%d%%)"):format(row, col + 1, math.floor(row / lines * 100)),
        ("flags   : %s"):format(flags ~= "" and flags or "-"),
        ("lsp     : %s"):format(#clients > 0 and table.concat(clients, ", ") or "none"),
    }

    vim.notify(table.concat(info, "\n"), vim.log.levels.INFO, { title = "file info" })
end, { desc = "Print current file info" })

-- surround add
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

-- 原来绑在 x 模式的 m 上，但被文件末尾的 multicursor 映射（x m -> Q）覆盖，一直没生效；改到 M
map("x", "M", function()
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

-- for C-o C-i：这几个跳转不写 jumplist
-- 必须用 expr 把 v:count 拼进去：<cmd> 映射里的 normal! 拿不到计数，42G / 10gg / 3n 会失效
for _, key in ipairs({ "gg", "G", "n", "N" }) do
    map("n", key, function()
        local count = vim.v.count > 0 and vim.v.count or ""
        return "<cmd>keepjumps normal! " .. count .. key .. "<CR>"
    end, { expr = true, desc = "keepjumps " .. key })
end

-- in the visual mode , p always replace the register
map("x", "p", "P", {
    desc = "Paste without overwriting register",
})

-- x 模式 O：用默认浏览器 Google 搜索选中文本
map("x", "O", function()
    -- getregion() 返回的是 List（每行一项），必须 concat 成字符串
    local text = table.concat(
        vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), {
            type = vim.fn.mode(), -- "v" / "V" / "\22"，保证 block/line 模式也对
        }),
        "\n"
    )
    -- 用 rfc2396：默认的 rfc3986 不会转义 & + = / ; : @ $ ,，会破坏 query
    local url = "https://www.google.com/search?q=" .. vim.uri_encode(text, "rfc2396")
    vim.ui.open(url) -- 异步、跨平台、不闪屏
    vim.cmd("normal! gv") -- 可选：保留选区
end, { desc = "Search selection in browser" })

-- lsp glance
map("n", "gD", "<CMD>Glance definitions<CR>", { desc = "Glance definitions" })
map("n", "gr", "<CMD>Glance references<CR>", { desc = "Glance references" })
map("n", "gt", "<CMD>Glance type_definitions<CR>", { desc = "Glance type definitions" })
map("n", "gi", "<CMD>Glance implementations<CR>", { desc = "Glance implementations" })

--  multi-cursor
-- 0.13 内置 multicursor 在 Q 上；Q 已让给录制宏，所以把 multicursor 挪到 m（代价：失去 mark）
map({ "n", "x" }, "m", "Q", { desc = "Place/remove multicursor" })
map({ "n", "x" }, "m=", "q=", { desc = "Multicursor q=" })

map({ "n" }, "<leader>m", "m", { desc = "Set mark (native m)" })

-- jump
map({ "n" }, "gI", "g;g;", { desc = "jump last last edit" })

-- <leader>M：列出 <leader>m 打的 mark（当前 buffer 的 a-z + 全局 A-Z），选中后跳过去
map("n", "<leader>M", function()
    local items = {}
    local function add(mark, buf, lnum, col, file)
        local text = ""
        if buf ~= 0 and vim.api.nvim_buf_is_loaded(buf) then
            text = vim.trim(vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] or "")
        end
        items[#items + 1] = {
            mark = mark,
            label = ("%s  %s:%d:%d  %s"):format(mark, vim.fn.fnamemodify(file, ":~:."), lnum, col + 1, text),
        }
    end
    local cur = vim.api.nvim_get_current_buf()
    for _, m in ipairs(vim.fn.getmarklist(cur)) do
        local mark = m.mark:sub(2)
        if mark:match("^%l$") then
            add(mark, cur, m.pos[2], m.pos[3] - 1, vim.api.nvim_buf_get_name(cur))
        end
    end
    for _, m in ipairs(vim.fn.getmarklist()) do
        local mark = m.mark:sub(2)
        if mark:match("^%u$") then
            add(mark, m.pos[1], m.pos[2], m.pos[3] - 1, m.file)
        end
    end
    if #items == 0 then
        vim.notify("没有 mark（用 <leader>m{a-z/A-Z} 打）", vim.log.levels.WARN)
        return
    end
    vim.ui.select(items, {
        prompt = "Marks",
        format_item = function(item)
            return item.label
        end,
    }, function(item)
        if item then
            -- ` 跳到 mark 的精确行列；全局 mark 会切到对应文件
            vim.cmd("normal! `" .. item.mark)
        end
    end)
end, { desc = "Pick a mark and jump" })

-- neogen
map({ "n" }, "<leader>/", function()
    require("neogen").generate()
end, { desc = "generate comment doc" })
