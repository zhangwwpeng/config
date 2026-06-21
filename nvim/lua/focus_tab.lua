local M = {}

local focus_tab_name = "focus_windows"
local origin_tab
local origin_buf

local RESTRICTED_KEYS = {
    "<leader><leader>",
    "<leader>e",
    "<Tab>",
    "<C-o>",
    "<C-i>",
    "<C-w>",
}

local restricted_by_buf = {}

function M.deny()
    vim.notify("not allowed in focus_windows", vim.log.levels.ERROR)
end

function M.goto_focus_tab()
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        if vim.t[tab].tab_name == focus_tab_name then
            vim.api.nvim_set_current_tabpage(tab)
            return tab
        end
    end

    vim.cmd("tabnew")
    vim.t.tab_name = focus_tab_name
    vim.api.nvim_set_current_buf(origin_buf)
end

function M.is_focus_tab()
    local tab = vim.api.nvim_get_current_tabpage()
    if vim.t[tab].tab_name == focus_tab_name then
        vim.api.nvim_set_current_tabpage(tab)
        return true
    else
        return false
    end
end

function M.disable_restrictions()
    local bufnr = vim.api.nvim_get_current_buf()
    local maps = restricted_by_buf[bufnr]
    if not maps then
        return
    end
    for _, map in ipairs(maps) do
        pcall(vim.keymap.del, map.mode, map.lhs, { buffer = bufnr })
    end
    restricted_by_buf[bufnr] = nil
end

function M.enable_restrictions()
    local bufnr = vim.api.nvim_get_current_buf()

    local maps = {}
    for _, lhs in ipairs(RESTRICTED_KEYS) do
        for _, mode in ipairs({ "n", "x", "v", "o" }) do
            vim.keymap.set(mode, lhs, M.deny, { buffer = bufnr, desc = "blocked in focus_windows" })
            maps[#maps + 1] = { mode = mode, lhs = lhs }
        end
    end
    restricted_by_buf[bufnr] = maps
end

function M.toggle()
    local cur_tab = vim.api.nvim_get_current_tabpage()
    origin_buf = vim.api.nvim_get_current_buf()

    if M.is_focus_tab() then
        M.disable_restrictions()
        vim.api.nvim_set_current_tabpage(origin_tab)
        return
    end

    origin_tab = cur_tab

    M.goto_focus_tab()
    M.enable_restrictions()
end

function M.setup()
    vim.keymap.set({ "n", "v" }, "<C-f>", function()
        M.toggle()
    end, { desc = "Toggle focus_windows tab" })
end

return M
