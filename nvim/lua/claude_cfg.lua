-- claudecode.nvim 的配置入口（命令面板 "claude start" 时才 setup，见 agent.lua）
--
-- 终端用自定义 provider：全屏浮窗，几何和 terminal.lua / pi-agent 的浮窗一致，不依赖 snacks.nvim。
-- provider 接口见 claudecode.nvim/lua/claudecode/terminal/README.md 的 Provider contract。
local M = {}

local state = { buf = nil, win = nil, job = nil } ---@type { buf: integer?, win: integer?, job: integer? }

local function geometry()
    return {
        relative = "editor",
        row = 0,
        col = 0,
        width = vim.o.columns,
        height = math.max(vim.o.lines - vim.o.cmdheight, 1),
    }
end

local function buf_alive()
    return state.buf ~= nil and vim.api.nvim_buf_is_valid(state.buf)
end

local function win_visible()
    return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

---@param focus boolean
local function show(focus)
    if not win_visible() then
        local config = geometry()
        config.style = "minimal"
        config.border = "none"
        state.win = vim.api.nvim_open_win(state.buf, focus, config)
        vim.wo[state.win].winblend = tonumber(vim.g.float_win_blend) or 0
    elseif focus then
        vim.api.nvim_set_current_win(state.win)
    end
    if focus then
        vim.cmd("startinsert")
    end
end

local function hide()
    if win_visible() then
        vim.api.nvim_win_hide(state.win)
    end
    state.win = nil
end

local function reset()
    hide()
    if buf_alive() then
        pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
    end
    state.buf, state.job = nil, nil
end

---@class ClaudeFloatProvider 实现 claudecode 的 ClaudeCodeTerminalProvider 接口
local provider = {}

function provider.setup(_) end

function provider.open(cmd_string, env_table, effective_config, focus)
    focus = focus ~= false
    if buf_alive() then
        show(focus)
        return
    end
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].bufhidden = "hide" -- 窗口隐藏时 claude 进程继续跑
    vim.b[state.buf].agent_terminal = true -- terminal.lua 不会把它当成自己的终端借走
    show(focus) -- 先有窗口，终端才能拿到全屏的尺寸
    vim.api.nvim_buf_call(state.buf, function()
        state.job = vim.fn.jobstart(require("claudecode.utils").parse_command(cmd_string), {
            term = true,
            env = env_table,
            cwd = effective_config.cwd,
            on_exit = function()
                vim.schedule(function()
                    if effective_config.auto_close ~= false then
                        reset()
                    end
                end)
            end,
        })
    end)
    if not state.job or state.job <= 0 then
        vim.notify("claude 启动失败：" .. cmd_string, vim.log.levels.ERROR)
        reset()
        return
    end
    -- n 模式（terminal-normal）不会把按键转发给终端：<C-c> 手发一个 Esc 给 claude（中断当前回复），同 pi
    local job = state.job
    vim.keymap.set("n", "<C-c>", function()
        pcall(vim.api.nvim_chan_send, job, "\27")
    end, { buffer = state.buf, silent = true, desc = "claude: interrupt (send Esc)" })
end

function provider.close()
    if state.job then
        pcall(vim.fn.jobstop, state.job)
    end
    reset()
end

function provider.simple_toggle(cmd_string, env_table, effective_config)
    if win_visible() then
        hide()
    else
        provider.open(cmd_string, env_table, effective_config, true)
    end
end

function provider.focus_toggle(cmd_string, env_table, effective_config)
    if win_visible() and vim.api.nvim_get_current_win() == state.win then
        hide()
    else
        provider.open(cmd_string, env_table, effective_config, true)
    end
end

function provider.ensure_visible()
    if buf_alive() then
        show(false)
    end
end

function provider.get_active_bufnr()
    return buf_alive() and state.buf or nil
end

function provider.is_available()
    return true
end

---当前窗口是不是 claude 的浮窗
---@return boolean
function M.in_win()
    return win_visible() and vim.api.nvim_get_current_win() == state.win
end

---隐藏浮窗（进程继续跑）
M.hide = hide

---浮窗是否开着
M.visible = win_visible

local did_setup = false

function M.setup()
    if did_setup then
        return
    end
    did_setup = true

    require("claudecode").setup({
        auto_start = true,
        focus_after_send = true, -- x 模式 <C-;> 发送选区后直接进 claude 浮窗
        terminal = {
            provider = provider,
        },
        diff_opts = {
            -- 终端是全屏浮窗，diff 开在当前 tab 会被盖住；浮窗只属于创建它的 tab，新 tab 里看不到它
            open_in_new_tab = true,
            hide_terminal_in_new_tab = true,
        },
    })

    -- 全屏浮窗不会跟着窗口大小变，resize 时重贴一次
    vim.api.nvim_create_autocmd("VimResized", {
        group = vim.api.nvim_create_augroup("ClaudeFloat", { clear = true }),
        callback = function()
            if win_visible() then
                vim.api.nvim_win_set_config(state.win, geometry())
            end
        end,
        desc = "claude: keep fullscreen float covering the editor",
    })
end

return M
