local M = {}

---@class CmdPanelItem
---@field cmd_name string
---@field desc? string
---@field cmd fun()
---@field cmd_pre? fun()
---@field cmd_post? fun()

---@type CmdPanelItem[]
local cmd_table = {}

---@type table<string, CmdPanelItem>
local cmd_index = {}

---@param item CmdPanelItem
local function exec(item)
    item.cmd()
end

local uv = vim.uv or vim.loop
local e = vim.fn.fnameescape

------------------------------------------------------------------------
-- session
------------------------------------------------------------------------

local session_dir = vim.fn.stdpath("state") .. "/sessions/"
local session_file = vim.fs.joinpath(vim.fn.stdpath("cache") --[[@as string]], "restart.vim")

---@class Session
local session = {}
M.session = session

function session.current()
    local name = vim.fn.getcwd():gsub("[\\/:]+", "%%")
    return session_dir .. name .. ".vim"
end

function session.start()
    vim.fn.mkdir(session_dir, "p")
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("persistence", { clear = true }),
        callback = function()
            local bufs = vim.tbl_filter(function(b)
                if
                    vim.bo[b].buftype ~= ""
                    or vim.tbl_contains({ "gitcommit", "gitrebase", "jj" }, vim.bo[b].filetype)
                then
                    return false
                end
                return vim.api.nvim_buf_get_name(b) ~= ""
            end, vim.api.nvim_list_bufs())
            if #bufs < 3 then
                return
            end
            session.save()
        end,
    })
end

function session.save()
    vim.cmd("mks! " .. e(session.current()))
end

--- @param last boolean
function session.load(last)
    ---@type string
    local file
    if last then
        file = session.last()
    else
        file = session.current()
    end
    if file and vim.fn.filereadable(file) ~= 0 then
        vim.cmd("silent! source " .. e(file))
    end
end

---@return string[]
function session.list()
    local sessions = vim.fn.glob(session_dir .. "*.vim", true, true)
    table.sort(sessions, function(a, b)
        return uv.fs_stat(a).mtime.sec > uv.fs_stat(b).mtime.sec
    end)
    return sessions
end

function session.last()
    return session.list()[1]
end

function session.select()
    ---@type { session: string, dir: string, branch?: string }[]
    local items = {}
    local have = {} ---@type table<string, boolean>
    for _, s in ipairs(session.list()) do
        if uv.fs_stat(s) then
            local file = s:sub(#session_dir + 1, -5)
            local dir, branch = unpack(vim.split(file, "%%", { plain = true }))
            dir = dir:gsub("%%", "/")
            if jit.os:find("Windows") then
                dir = dir:gsub("^(%w)/", "%1:/")
            end
            if not have[dir] then
                have[dir] = true
                items[#items + 1] = { session = s, dir = dir, branch = branch }
            end
        end
    end
    vim.ui.select(items, {
        prompt = "Select a session: ",
        format_item = function(item)
            return vim.fn.fnamemodify(item.dir, ":p:~")
        end,
    }, function(item)
        if item then
            vim.fn.chdir(item.dir)
            session.load(false)
        end
    end)
end

function session.setup()
    -- load session
    session.start()
    M.registry_cmd({
        cmd_name = "save session",
        desc = "save current session",
        cmd = function()
            session.save()
        end,
    })
    M.registry_cmd({
        cmd_name = "load session",
        desc = "load session",
        cmd = function()
            session.select()
        end,
    })
    M.registry_cmd({
        cmd_name = "last session",
        desc = "load last session",
        cmd = function()
            session.load(true)
        end,
    })
    M.registry_cmd({
        cmd_name = "session open dir",
        desc = "open session dir",
        cmd = function()
            require("oil").open(session_dir)
        end,
    })
    M.registry_cmd({
        cmd_name = "restart",
        desc = "restart session",
        cmd = function()
            vim.cmd("restart")
        end,
    })
    M.registry_cmd({
        cmd_name = "piagent start",
        desc = "pi start",
        cmd = function()
            if require("pi_diff").ask_enable() then
                require("pi-agent").start()
            end
        end,
    })
end

------------------------------------------------------------------------
-- Plugin Manger
------------------------------------------------------------------------

local plugin_manger = {}
M.plugin_manger = plugin_manger

---@param plug vim.pack.PlugData
local function delete_plugin(plug)
    local name = plug.spec.name
    local msg = ("Delete plugin '%s'?"):format(name)
    if plug.active then
        msg = msg
            .. "\nIt is loaded in this session. Remove its spec from"
            .. "\ninit.lua and restart to delete it for good, otherwise"
            .. "\nit is reinstalled on the next start."
    end
    if vim.fn.confirm(msg, "&Delete\n&Cancel", 2) ~= 1 then
        return
    end

    -- del() refuses to touch an active plugin unless forced
    local ok, err = pcall(vim.pack.del, { name }, { force = plug.active })
    if not ok then
        vim.notify("delete plugin failed: " .. tostring(err), vim.log.levels.ERROR)
    elseif plug.active then
        vim.notify(("plugin '%s' deleted, remove its spec from init.lua"):format(name), vim.log.levels.WARN)
    end
end

function plugin_manger.delete()
    local plugs = vim.pack.get(nil, { info = false })
    if #plugs == 0 then
        vim.notify("no plugin managed by vim.pack", vim.log.levels.WARN)
        return
    end
    table.sort(plugs, function(a, b)
        return a.spec.name < b.spec.name
    end)
    vim.ui.select(plugs, {
        prompt = "Delete plugin: ",
        format_item = function(plug)
            return plug.spec.name .. (plug.active and "  (loaded)" or "")
        end,
    }, function(plug)
        if plug then
            delete_plugin(plug)
        end
    end)
end

function plugin_manger.setup()
    M.registry_cmd({
        cmd_name = "update all plugin",
        desc = "update all plugin",
        cmd = function()
            vim.pack.update()
        end,
    })
    M.registry_cmd({
        cmd_name = "delete plugin",
        desc = "delete some plugin",
        cmd = function()
            plugin_manger.delete()
        end,
    })
end

------------------------------------------------------------------------
-- CMD panel
------------------------------------------------------------------------
function M.setup()
    session.setup()
    plugin_manger.setup()
end

---@param cmd CmdPanelItem
function M.registry_cmd(cmd)
    cmd_table[#cmd_table + 1] = cmd
    cmd_index[cmd.cmd_name] = cmd
end

function M.panel_pick()
    vim.ui.select(cmd_table, {
        prompt = "Command: ",
        format_item = function(item)
            if item.desc and item.desc ~= "" then
                return item.cmd_name .. " │ " .. item.desc
            end
            return item.cmd_name
        end,
        preview_item = function(item)
            if item.desc and item.desc ~= "" then
                return { item.cmd_name, "", item.desc }
            end
            return { item.cmd_name }
        end,
    }, function(item)
        if item then
            exec(item)
        end
    end)
end

return M
