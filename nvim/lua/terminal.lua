local M = {}
local win = -1
local term_buf = -1
local layout_status = "float"

---@param w integer
---@return boolean 是否为已经打开的浮动窗口
local function is_float(w)
    return vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_config(w).relative ~= ""
end

---浮动终端窗口的几何：small 为 40% 高、垂直居中，large 为 90% 高、顶部对齐
---@param size "large"|"small"
---@return table
local function float_geometry(size)
    local small = size == "small"
    local width = math.floor(vim.o.columns * 0.9)
    local height = small and math.floor(vim.o.lines * 0.4) or math.floor(vim.o.lines * 0.9)
    return {
        relative = "editor",
        width = width,
        height = height,
        col = math.floor((vim.o.columns - width) / 2),
        row = small and 2 or math.floor((vim.o.lines - height) / 2) - 1,
    }
end

---打开终端窗口
---@param size "large"|"small" 浮动窗口的大小，仅 float 布局有效
local function open_term_win(size)
    if not vim.api.nvim_buf_is_valid(term_buf) then
        term_buf = vim.api.nvim_win_get_buf(0)
    end
    if layout_status == "float" then
        local config = float_geometry(size)
        config.style = "minimal"
        config.border = "rounded"
        config.focusable = false
        win = vim.api.nvim_open_win(term_buf, false, config)
    else
        local width = math.floor(vim.o.columns * 0.4)
        local height = math.floor(vim.o.lines * 0.4)
        local win_config = {
            win = -1,
            split = layout_status,
            height = height,
            width = width,
        }
        win = vim.api.nvim_open_win(term_buf, true, win_config)
        vim.wo.number = false
        vim.wo.signcolumn = "no"
    end
    vim.api.nvim_set_current_win(win)
    if vim.bo.buftype == "terminal" then
        vim.cmd("startinsert")
    end
end

---记住终端窗口里显示的终端 buffer，隐藏窗口前调用
---（窗口里显示的不是终端时保持原值，比如 picker 把文件放进了这个窗口）
local function remember_term_buf()
    if not vim.api.nvim_win_is_valid(win) then
        return
    end
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "terminal" then
        term_buf = buf
    end
end

function M.toggle_term_win()
    if not vim.api.nvim_win_is_valid(win) then
        open_term_win("large")
    else
        remember_term_buf()
        vim.api.nvim_win_hide(win)
    end
end

---把浮动终端窗口缩成小窗，给 picker 之类的浮层让出空间
---（原地改大小，不重建窗口；分屏布局本来就不大、或窗口没打开时什么都不做）
---@return boolean 是否缩小了
function M.resize_term_win()
    if not is_float(win) then
        return false
    end
    vim.api.nvim_win_set_config(win, float_geometry("small"))
    return true
end

---把浮动终端窗口恢复成大窗，picker 之类的浮层关掉后调用
---@return boolean 是否恢复了
function M.restore_term_win()
    if not is_float(win) then
        return false
    end
    vim.api.nvim_win_set_config(win, float_geometry("large"))
    return true
end

---当前窗口是否为本模块的浮动终端窗口
---@return boolean
function M.in_float_win()
    return is_float(win) and vim.api.nvim_get_current_win() == win
end

function M.swap_term_win()
    if layout_status == "float" then
        layout_status = "below"
    elseif layout_status == "below" then
        layout_status = "left"
    elseif layout_status == "left" then
        layout_status = "above"
    elseif layout_status == "above" then
        layout_status = "right"
    elseif layout_status == "right" then
        layout_status = "float"
    end
    vim.notify("swap term win to " .. layout_status)
    if not vim.api.nvim_win_is_valid(win) then
        open_term_win("large")
    else
        remember_term_buf()
        vim.api.nvim_win_hide(win)
        open_term_win("large")
    end
end

function M.setup() end

return M
