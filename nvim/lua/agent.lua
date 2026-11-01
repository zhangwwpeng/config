-- pi-agent / claude code 的统一入口
--   * 两者只能启动一个：命令面板里启动时检查另一个是否在跑
--   * <C-;> 一套键位：自动分发给正在运行的那个（keymaps.lua）
local M = {}

---@class AgentBackend
---@field name string
---@field running fun(): boolean
---@field start fun()
---@field in_win fun(): boolean 当前窗口是不是它的浮窗
---@field visible fun(): boolean 浮窗是否开着
---@field focus fun()
---@field hide fun()
---@field send_selection fun() x 模式下把选区发过去并进入浮窗

---@type table<string, AgentBackend>
local backends = {
    pi = {
        name = "pi-agent",
        running = function()
            local pi = package.loaded["pi-agent"]
            return pi ~= nil and pi.server ~= nil
        end,
        start = function()
            require("pi_agent_cfg").setup()
            require("pi_diff").ask_enable()
            require("pi-agent").start()
        end,
        visible = function()
            local flt = require("pi-agent.surfaces.nvim_flt")
            return flt.win_id ~= nil and vim.api.nvim_win_is_valid(flt.win_id)
        end,
        in_win = function()
            local flt = require("pi-agent.surfaces.nvim_flt")
            return flt.win_id ~= nil
                and vim.api.nvim_win_is_valid(flt.win_id)
                and vim.api.nvim_get_current_win() == flt.win_id
        end,
        focus = function()
            require("pi-agent").focus()
        end,
        hide = function()
            require("pi-agent").close()
        end,
        send_selection = function()
            require("pi-agent").paste_selection_contents()
            require("pi-agent").focus()
        end,
    },
    claude = {
        name = "claude",
        running = function()
            local cc = package.loaded["claudecode"]
            return cc ~= nil and cc.state ~= nil and cc.state.server ~= nil
        end,
        start = function()
            require("claude_cfg").setup()
            require("claudecode.terminal").open()
        end,
        visible = function()
            return require("claude_cfg").visible()
        end,
        in_win = function()
            return require("claude_cfg").in_win()
        end,
        focus = function()
            require("claudecode.terminal").open()
        end,
        hide = function()
            require("claude_cfg").hide()
        end,
        send_selection = function()
            -- ClaudeCodeSend 会自己识别 visual 选区；focus_after_send = true，发完自动进浮窗
            vim.cmd("ClaudeCodeSend")
        end,
    },
}

---@return AgentBackend?
local function active()
    for _, b in pairs(backends) do
        if b.running() then
            return b
        end
    end
end

---命令面板入口：启动 pi / claude，另一个在跑就拒绝
---@param name "pi"|"claude"
function M.start(name)
    local b = backends[name]
    local cur = active()
    if cur and cur ~= b then
        vim.notify(("%s 已经在运行，pi 和 claude 只能启动一个"):format(cur.name), vim.log.levels.WARN)
        return
    end
    require("terminal").hide_float() -- 同时只留一个全屏浮窗
    b.start()
    require("imselect").switch("zh")
end

---n/t <C-;>：在浮窗里就隐藏，否则打开 / 聚焦
function M.toggle()
    local b = active()
    if not b then
        vim.notify("没有启动 agent：<C-p> 命令面板里选 piagent start / claude start", vim.log.levels.WARN)
        return
    end
    if b.in_win() then
        b.hide()
        require("imselect").to_en()
    else
        require("terminal").hide_float() -- 同时只留一个全屏浮窗
        b.focus()
        require("imselect").switch("zh")
    end
end

---x <C-;>：把选区发给正在运行的 agent
function M.send_selection()
    local b = active()
    if not b then
        vim.notify("没有启动 agent：<C-p> 命令面板里选 piagent start / claude start", vim.log.levels.WARN)
        return
    end
    require("terminal").hide_float()
    b.send_selection()
    require("imselect").switch("zh")
end

---隐藏正在运行的 agent 的浮窗（进程继续跑），给浮动终端让位
function M.hide_float()
    local b = active()
    if b and b.visible() then
        b.hide()
    end
end

return M
