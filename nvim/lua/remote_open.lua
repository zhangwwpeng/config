-- 终端里 `vim / nvim file` 转发到父实例时的打开策略。
--
-- 以前用 `nvim --remote-tab-silent`，每敲一次就多一个 tab（tab 越攒越多，父实例的
-- 当前 tab 也被反复切换）。这里改成复用窗口：
--   * 优先复用上一次远程打开用过的窗口（普通窗口，非浮窗、非 terminal）
--   * 其次用当前 tab 里第一个可编辑窗口
--   * 都不存在时才 fallback 到 tabedit
-- 用 nvim_win_call 改 buffer，不切当前窗口/tab，所以终端浮层里的焦点不会被打断。
local M = {}

---@param win integer
---@return boolean
local function editable(win)
    if not vim.api.nvim_win_is_valid(win) then
        return false
    end
    if vim.api.nvim_win_get_config(win).relative ~= "" then
        return false -- 浮窗（终端浮层、picker 之类）
    end
    return vim.bo[vim.api.nvim_win_get_buf(win)].buftype ~= "terminal"
end

---@return integer?
local function target_win()
    local last = vim.g.remote_open_win
    if type(last) == "number" and editable(last) then
        return last
    end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if editable(win) then
            return win
        end
    end
end

---在父实例里打开文件（保持当前窗口/焦点不动）
---@param paths string|string[]
---@return boolean
function M.open(paths)
    if type(paths) == "string" then
        paths = { paths }
    end
    if #paths == 0 then
        return false
    end

    local win = target_win()
    for i, path in ipairs(paths) do
        local full = vim.fn.fnamemodify(path, ":p")
        if i == 1 and win then
            vim.api.nvim_win_call(win, function()
                vim.cmd.edit({ args = { full } })
            end)
        elseif i == 1 then
            -- 当前 tab 里没有可编辑窗口（例如当前窗口就是 terminal）
            vim.cmd.tabedit({ args = { full } })
            win = vim.api.nvim_get_current_win()
        else
            -- 多文件时其余文件只进 buffer 列表，不额外开窗口
            vim.fn.bufadd(full)
        end
    end

    vim.g.remote_open_win = win
    return true
end

return M
