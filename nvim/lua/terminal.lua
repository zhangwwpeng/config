local M = {}
local win = -1
local term_buf = -1
local layout_status = "float"
local term_shrunk = false ---@type boolean 浮窗当前是否缩成小窗（给 picker 让位）

---@param w integer
---@return boolean 是否为已经打开的浮动窗口
local function is_float(w)
    return vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_config(w).relative ~= ""
end

---浮动终端窗口的几何
---large：铺满 editor（扣掉命令行高度，cmdheight=0 时就是整屏）
---small：全宽 40% 高、贴顶，给 picker 之类的浮层让出下方空间
---@param size "large"|"small"
---@return table
local function float_geometry(size)
    local small = size == "small"
    local height = small and math.floor(vim.o.lines * 0.6) - 2 or (vim.o.lines - vim.o.cmdheight)
    return {
        title = "terminal",
        title_pos = "center",
        relative = "editor",
        width = vim.o.columns,
        height = math.max(height, 1),
        col = 0,
        row = 0,
    }
end

---打开终端窗口
---确保有一个可用的终端 buffer：优先复用已有终端，其次复用当前窗口里的终端，
---都没有时新建一个隐藏终端（不能直接把当前普通文件 buffer 当终端用）。
---@param buf integer
---@return boolean 是否为 shell 还在运行的终端 buffer（shell 里 exit 之后 buffer 还在，但已经不能用了）
local function is_live_term(buf)
    if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "terminal" then
        return false
    end
    local job = vim.b[buf].terminal_job_id
    return job ~= nil and vim.fn.jobwait({ job }, 0)[1] == -1
end

---pi / claude 的终端 buffer（不能被 <C-t> 借去当浮动终端）
---@param buf integer
---@return boolean
local function is_agent_buf(buf)
    return vim.b[buf].agent_terminal == true or vim.bo[buf].filetype == "pi-agent"
end

local function ensure_term_buf()
    if is_live_term(term_buf) then
        return
    end
    -- 记住的终端 shell 已退出：删掉这个死 buffer，下面会新开一个
    if vim.api.nvim_buf_is_valid(term_buf) and vim.bo[term_buf].buftype == "terminal" then
        pcall(vim.api.nvim_buf_delete, term_buf, { force = true })
    end
    local cur = vim.api.nvim_win_get_buf(0)
    if is_live_term(cur) and not is_agent_buf(cur) then
        term_buf = cur
        return
    end
    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_call(buf, function()
        vim.fn.jobstart(vim.o.shell, { term = true }) -- termopen() 已 deprecated
    end)
    term_buf = buf
end

---@param size? "large"|"small" 浮动窗口的大小，仅 float 布局有效，默认 large
local function open_term_win(size)
    ensure_term_buf()
    if layout_status == "float" then
        -- 同时只留一个全屏浮窗：先把 pi / claude 的浮窗收起来（进程继续跑）
        require("agent").hide_float()
        local config = float_geometry(size or "large")
        config.style = "minimal"
        config.border = "none"
        config.focusable = false
        win = vim.api.nvim_open_win(term_buf, false, config)
        term_shrunk = false -- 新建/重开的浮窗一律是 large，避免 term_shrunk 卡在 true
        -- winblend 由 init.lua 的 WinNew autocmd 统一设置，这里不用再管；
        -- 分屏布局是普通窗口，也不会被那个 autocmd 碰到（保持完全不透明）
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
    if vim.bo[buf].buftype == "terminal" and not is_agent_buf(buf) then
        term_buf = buf
    end
end

---隐藏浮动终端（分屏布局不算浮窗，不动），给 agent 浮窗让位
function M.hide_float()
    if is_float(win) then
        remember_term_buf()
        vim.api.nvim_win_hide(win)
    end
end

function M.toggle_term_win()
    if not vim.api.nvim_win_is_valid(win) then
        open_term_win()
    else
        remember_term_buf()
        vim.api.nvim_win_hide(win)
    end
end

---当前窗口是否为本模块的浮动终端窗口
---@return boolean
function M.in_float_win()
    return is_float(win) and vim.api.nvim_get_current_win() == win
end

---把浮动终端窗口缩成小窗，给 picker 之类的浮层让出空间
---（原地改大小，不重建窗口；分屏布局本来就不大、或窗口没打开时什么都不做）
---@return boolean 是否缩小了
function M.resize_term_win()
    if not is_float(win) then
        return false
    end
    vim.api.nvim_win_set_config(win, float_geometry("small"))
    term_shrunk = true
    return true
end

---把浮动终端窗口恢复成全屏，picker 之类的浮层关掉后调用
---@return boolean 是否恢复了
function M.restore_term_win()
    if not is_float(win) then
        return false
    end
    vim.api.nvim_win_set_config(win, float_geometry("large"))
    term_shrunk = false
    return true
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
        open_term_win()
    else
        remember_term_buf()
        vim.api.nvim_win_hide(win)
        open_term_win()
    end
end

---large 是全屏浮窗，不会跟着窗口大小自动变，resize 时重新贴一次（小窗状态不动）
function M.setup()
    vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
            if is_float(win) and not term_shrunk then
                vim.api.nvim_win_set_config(win, float_geometry("large"))
            end
        end,
        desc = "keep fullscreen float term covering the editor",
    })
end

return M
