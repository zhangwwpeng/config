------------------------------------------------------------------------
-- Plugin config
------------------------------------------------------------------------
require("indent").setup({ char = "┃" })
require("imselect").setup()
-- require("delta").setup({})
require("terminal")

-- require("vim._core.ui2").enable({
--     enabled = true,
--     targets = "msg",
-- })
vim.api.nvim_create_autocmd("FileType", {
    pattern = "cmd",
    callback = function()
        local ui2 = require("vim._core.ui2")
        vim.schedule(function()
            local win = ui2.wins and ui2.wins.cmd
            if win and vim.api.nvim_win_is_valid(win) then
                local win_config = vim.api.nvim_win_get_config(win)
                local width = win_config.width or math.floor(vim.o.columns * 0.6)
                local height = win_config.height or 1
                local row = (vim.o.lines - height) / 2
                local col = (vim.o.columns - width) / 2
                pcall(vim.api.nvim_win_set_config, win, {
                    relative = "editor",
                    row = row,
                    col = col,
                    width = width,
                    height = height,
                    anchor = "NW",
                    border = "rounded",
                    style = "minimal",
                })
            end
        end)
    end,
})

require("snacks").setup({
    bigfile = { enabled = true },
    quickfile = { enabled = true },
    notifier = {
        enabled = false,
        style = "minimal",
        width = { min = 0, max = 0.4 },
    },
    picker = {
        enabled = true,
        layout = "ivy",
        layouts = {
            ivy = {
                layout = {
                    box = "vertical",
                    backdrop = true,
                    row = -1,
                    width = 0,
                    height = 0.8,
                    border = "top",
                    title = " {title} {live} {flags}",
                    title_pos = "left",
                    { win = "input", height = 1, border = "bottom" },
                    {
                        box = "horizontal",
                        { win = "list", border = "none" },
                        { win = "preview", title = "{preview}", width = 0.6, border = "left" },
                    },
                },
            },
        },
    },
})

require("flash").setup({
    search = {
        mode = function(str)
            return "\\<" .. str
        end,
    },
    highlight = {
        backdrop = false,
    },
    modes = {
        char = {
            highlight = {
                backdrop = false,
            },
        },
    },
})

local detail = false
require("oil").setup({
    keymaps = {
        -- ["g?"] = { "actions.show_help", mode = "n" },
        ["<CR>"] = "actions.select",
        ["<C-s>"] = false,
        ["<C-h>"] = false,
        ["<C-t>"] = false,
        ["<C-p>"] = "actions.preview",
        ["<C-q>"] = { "actions.close", mode = "n" },
        ["<C-l>"] = "actions.refresh",
        ["-"] = { "actions.parent", mode = "n" },
        -- ["_"] = { "actions.open_cwd", mode = "n" },
        -- ["`"] = { "actions.cd", mode = "n" },
        -- ["g~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
        -- ["gs"] = { "actions.change_sort", mode = "n" },
        -- ["gx"] = "actions.open_external",
        ["."] = { "actions.toggle_hidden", mode = "n" },
        -- ["g\\"] = { "actions.toggle_trash", mode = "n" },
        ["gd"] = {
            desc = "Toggle file detail view",
            callback = function()
                detail = not detail
                if detail then
                    require("oil").set_columns({ "icon", "permissions", "size", "mtime" })
                else
                    require("oil").set_columns({ "icon" })
                end
            end,
        },
    },
    win_options = {
        winbar = "%!v:lua.get_oil_winbar()",
    },
})

-- Declare a global function to retrieve the current directory
function _G.get_oil_winbar()
    local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
    local dir = require("oil").get_current_dir(bufnr)
    if dir then
        return vim.fn.fnamemodify(dir, ":~")
    else
        -- If there is no current directory (e.g. over ssh), just show the buffer name
        return vim.api.nvim_buf_get_name(0)
    end
end

require("quickbuf").setup({
    fuzzy_backend = "snacks",
})
vim.keymap.set("n", "<Tab>", "<cmd>QuickBuf<CR>", { desc = "QuickBuf" })
vim.keymap.set("n", "<leader>qt", "<cmd>QuickBufPinToggle<CR>", { desc = "Pin toggle" })
vim.keymap.set("n", "<S-h>", "<cmd>QuickBufPrevPinned<CR>", { desc = "Prev pinned buffer" })
vim.keymap.set("n", "<S-l>", "<cmd>QuickBufNextPinned<CR>", { desc = "Next pinned buffer" })

