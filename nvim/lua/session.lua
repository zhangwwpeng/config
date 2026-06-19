local M = {}

local uv = vim.uv or vim.loop
local e = vim.fn.fnameescape
local dir = vim.fn.stdpath("state") .. "/sessions/"

function M.current()
    local name = vim.fn.getcwd():gsub("[\\/:]+", "%%")
    return dir .. name .. ".vim"
end

function M.setup()
    M.start()
    require("cmd_panel").registry_cmd({
        cmd_name = "session save",
        desc = "save session to state ss",
        cmd = function()
            M.save()
        end,
    })
    require("cmd_panel").registry_cmd({
        cmd_name = "session load",
        desc = "load session from state ls",
        cmd = function()
            M.select()
        end,
    })
    require("cmd_panel").registry_cmd({
        cmd_name = "session last session",
        desc = "load last session from state lls",
        cmd = function()
            M.load(true)
        end,
    })
    require("cmd_panel").registry_cmd({
        cmd_name = "session open dir",
        desc = "open session dir",
        cmd = function()
            require("oil").open(dir)
        end,
    })
end

function M.start()
    vim.fn.mkdir(dir, "p")
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
            M.save()
        end,
    })
end

function M.save()
    vim.cmd("mks! " .. e(M.current()))
end

--- @param last boolean
function M.load(last)
    ---@type string
    local file
    if last then
        file = M.last()
    else
        file = M.current()
    end
    if file and vim.fn.filereadable(file) ~= 0 then
        vim.cmd("silent! source " .. e(file))
    end
end

---@return string[]
function M.list()
    local sessions = vim.fn.glob(dir .. "*.vim", true, true)
    table.sort(sessions, function(a, b)
        return uv.fs_stat(a).mtime.sec > uv.fs_stat(b).mtime.sec
    end)
    return sessions
end

function M.last()
    return M.list()[1]
end

function M.select()
    ---@type { session: string, dir: string, branch?: string }[]
    local items = {}
    local have = {} ---@type table<string, boolean>
    for _, session in ipairs(M.list()) do
        if uv.fs_stat(session) then
            local file = session:sub(#dir + 1, -5)
            local dir, branch = unpack(vim.split(file, "%%", { plain = true }))
            dir = dir:gsub("%%", "/")
            if jit.os:find("Windows") then
                dir = dir:gsub("^(%w)/", "%1:/")
            end
            if not have[dir] then
                have[dir] = true
                items[#items + 1] = { session = session, dir = dir, branch = branch }
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
            M.load(false)
        end
    end)
end

return M
