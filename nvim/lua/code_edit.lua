local M = {}

local keys = {
    ["("] = { pair = "()" },
    ["["] = { pair = "[]" },
    ["{"] = { pair = "{}" },

    ['"'] = { pair = '""' },
    ["'"] = { pair = "''" },
    ["`"] = { pair = "``" },

    ["<cr>"] = {},
    ["<space>"] = {},
    ["<bs>"] = {},
}

local QUOTES = { ['"'] = true, ["'"] = true, ["`"] = true }

---get pair in cursor
---@param mode string
---@return string
local function get_pair(mode)
    local line = mode == "i" and vim.api.nvim_get_current_line() or "_" .. vim.fn.getcmdline()
    local col = mode == "i" and vim.api.nvim_win_get_cursor(0)[2] or vim.fn.getcmdpos()

    return line:sub(col, col + 1)
end

---check if is a pair
---@param pair string
---@return boolean
local function is_pair(pair)
    for _, val in pairs(keys) do
        if pair == val.pair then
            return true
        end
    end
    return false
end

---disable some key in special file
---@param key string
---@param val table
---@return string
local function ft_pair_enable(key, val)
    local ft = vim.bo.filetype

    if ft == "verilog" or ft == "systemverilog" then
        if key == "'" or key == "`" then
            return key
        else
            return val.pair .. "<Left>"
        end
    else
        return val.pair .. "<Left>"
    end
end

---add or delete pairs in cursor
---@param key string the key or pair char
---@param val table {close: boolean, pair: string}
---@return string
local function update_pairs(key, val)
    local mode = vim.fn.mode()
    local pair = get_pair(mode)

    if key == "<cr>" and mode == "i" and is_pair(pair) then
        return "<cr><c-o>O"
    elseif key == "<space>" and mode == "i" and is_pair(pair) then
        return "<space><space><left>"
    elseif key == "<bs>" and is_pair(pair) then
        return "<bs><del>"
    elseif QUOTES[key] then
        local before, after = pair:sub(1, 1), pair:sub(2, 2)
        -- 光标下就是同一个引号：跳过去，而不是再插一对（'abc|' 里敲 ' -> 'abc'|）
        if after == key then
            return "<Right>"
        end
        -- 紧跟在字母/数字后面（don't、it's、x'）：不配对
        -- 注：cmdline 下 get_pair 会在行首补 "_"，所以这里只认 %w，不认 "_"
        if before:match("%w") then
            return key
        end
        return ft_pair_enable(key, val)
    elseif val.pair then
        return ft_pair_enable(key, val)
    end

    return key
end

function M.setup()
    for key, val in pairs(keys) do
        -- <cr>/<space>/<bs> must NOT be mapped in command-line mode: those keys
        -- are what trigger `cnoreabbrev` expansion (e.g. `:grep` -> `:Grep`).
        -- Mapping them in `c` mode swallows the keypress and the abbreviation
        -- never fires. Pair characters are still mapped in cmdline mode.
        local modes = (key == "<cr>" or key == "<space>" or key == "<bs>") and { "i" } or { "i", "c" }
        vim.keymap.set(modes, key, function()
            vim.schedule(function()
                vim.cmd("redraw")
            end)
            return update_pairs(key, val)
        end, { noremap = true, expr = true })
    end
end

return M
