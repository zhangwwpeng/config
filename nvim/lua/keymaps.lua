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
    vim.cmd.normal("gcc")
end, comment_opts)

-- buf bd
map({ "n" }, "<leader>d", function()
    vim.cmd("bd")
end, { desc = "Close buffer" })

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
    vim.cmd("Refer Files")
end, { desc = "Smart Find Files" })

map({ "n" }, "<leader>g", function()
    vim.cmd("Refer Grep")
end, { desc = "Smart Find Files" })

map({ "n" }, "<leader>o", function()
    vim.cmd("Refer OldFiles")
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

-- test
map("n", "<leader>0", function()
    require("code_preview").preview_current_line()
end, { desc = "Line diagnostic panel" })

-- emcal style
map({ "c", "n" }, "<C-a>", "<Home>", { noremap = true })
map({ "c", "n" }, "<C-e>", "<end>", { noremap = true })
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
map(
    { "n", "x" },
    "<leader>aa",
    require("pi-agent").paste_selection_location,
    { desc = "pi: Paste range location", noremap = true, silent = true }
)

map("n", "<leader>ad", require("pi_diff").review, { desc = "pi: diff 本轮改动 (codediff)" })
map("n", "<leader>ar", require("pi_diff").rollback, { desc = "pi: 回滚本轮改动" })

-- quickfix: dd / DD delete the buffer under the cursor, then drop its items
vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    callback = function(args)
        local function delete_buf_under_cursor()
            local info = vim.fn.getqflist({ idx = 0, items = 0 })
            local item = info.items[info.idx]
            if not item then
                return
            end
            local bufnr = item.bufnr
            if bufnr == 0 then
                bufnr = vim.fn.bufnr(item.filename)
            end
            if bufnr <= 0 or not vim.api.nvim_buf_is_valid(bufnr) then
                return
            end
            -- delete the buffer first so a refused bdelete keeps the list intact
            local ok, err = pcall(vim.cmd, "bdelete " .. bufnr)
            if not ok then
                vim.notify(err, vim.log.levels.WARN)
                return
            end
            -- rebuild the list without every entry pointing to that buffer
            local new_items, new_idx = {}, info.idx
            for i, it in ipairs(info.items) do
                local it_buf = it.bufnr
                if it_buf == 0 then
                    it_buf = vim.fn.bufnr(it.filename)
                end
                if it_buf == bufnr then
                    if i < info.idx then
                        new_idx = new_idx - 1
                    end
                else
                    new_items[#new_items + 1] = it
                end
            end
            new_idx = math.max(1, math.min(new_idx, #new_items))
            vim.fn.setqflist({}, "r", { items = new_items, idx = new_idx })
        end

        local opts = { buffer = args.buf, desc = "Delete buffer of quickfix item" }
        map("n", "DD", delete_buf_under_cursor, opts)
    end,
})
