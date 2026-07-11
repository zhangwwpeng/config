local HOST = "127.0.0.1"
local PORT = 6666

local aichat_chan = nil
local function get_chan()
    if aichat_chan and aichat_chan > 0 then
        local alive = pcall(vim.api.nvim_get_chan_info, aichat_chan)
        if alive then
            return aichat_chan
        end
        aichat_chan = nil
    end
    local ok, chan = pcall(vim.fn.sockconnect, "tcp", HOST .. ":" .. PORT, { rpc = true })
    if ok and chan > 0 then
        aichat_chan = chan
        return chan
    end
    vim.notify(
        ("AI chat server is unavailable at %s:%d; start nvim/aichat_nvim/main.py first"):format(HOST, PORT),
        vim.log.levels.WARN
    )
end
local pick = require("mini.pick")

--- 获取当前 buffer 的 ai_session 变量
--- @return string|nil 返回字符串变量值，如果不存在返回 nil
local function get_ai_session_var()
    local buf = 0 -- 0 表示当前 buffer
    local _, value = pcall(vim.api.nvim_buf_get_var, buf, "aisession")
    return value
end

local function get_session()
    local file_path
    local session
    local payload = { op = "get_session" }
    local chan = get_chan()
    if not chan then
        return
    end
    local ok, response = pcall(vim.fn.rpcrequest, chan, "nvim_request", payload)
    if not ok then
        aichat_chan = nil
        vim.notify("AI chat request failed: " .. tostring(response), vim.log.levels.ERROR)
        return
    end
    if type(response) ~= "table" then
        vim.notify("AI chat returned an invalid session list: " .. tostring(response), vim.log.levels.ERROR)
        return
    end
    pick.start({
        source = {
            items = response,
            name = "aichat session select",
            choose = function(item)
                session = item
            end,
        },
    })
    if session == nil then
        return nil
    else
        file_path = session .. "/chat.md"
    end
    if vim.fn.filereadable(file_path) == 1 then
        return file_path
    end
end

local function sub_ai()
    vim.cmd("update")
    -- vim.bo.modifiable = false
    -- vim.bo.readonly = true
    -- vim.bo.wrap = true
    local session = get_ai_session_var()
    local payload = {
        op = "sub_ai",
        message = session,
        nvim_header = vim.v.servername,
        buf = vim.api.nvim_get_current_buf(),
    }
    -- local response = vim.fn.rpcrequest(aichat_chan, "nvim_request", payload)
    local chan = get_chan()
    if not chan then
        return
    end
    local ok, err = pcall(vim.fn.rpcnotify, chan, "nvim_request", payload)
    if not ok then
        aichat_chan = nil
        vim.notify("AI chat send failed: " .. tostring(err), vim.log.levels.ERROR)
        return
    end
    vim.notify("Send to server", vim.log.levels.INFO)
end

local function create_session()
    vim.ui.input({ prompt = "Session name: " }, function(name)
        if not name or name == "" then
            return
        end
        local chan = get_chan()
        if not chan then
            return
        end
        local payload = { op = "create_session", message = name }
        local ok, response = pcall(vim.fn.rpcrequest, chan, "nvim_request", payload)
        if not ok then
            aichat_chan = nil
            vim.notify("Create session failed: " .. tostring(response), vim.log.levels.ERROR)
            return
        end
        local level = tostring(response):match("^ERROR:") and vim.log.levels.ERROR or vim.log.levels.INFO
        vim.notify(tostring(response), level)
    end)
end

vim.keymap.set("n", "<leader>aa", create_session, { desc = "Create aichat session" })

vim.keymap.set("n", "<leader>s", function()
    local aibuf
    local file_path = get_session()
    if file_path == nil then
        return
    end
    if file_path then
        aibuf = vim.fn.bufadd(file_path)
        vim.fn.bufload(aibuf)
        local dir = vim.fn.fnamemodify(file_path, ":h")
        local last_dir = vim.fn.fnamemodify(dir, ":t")
        vim.b[aibuf].aisession = last_dir
        vim.cmd("set wrap")
        vim.api.nvim_set_current_buf(aibuf)

        -- some bingking
        vim.keymap.set("n", "P", function()
            vim.cmd("stopinsert")
            sub_ai()
        end, { buffer = aibuf, desc = "同步当前 Buffer 内容" })

        vim.keymap.set("n", "<C-a>", function()
            local models = { "DEEPSEEK", "CHATGPT", "GEMINI" }
            local line = vim.api.nvim_get_current_line()
            for i, model in ipairs(models) do
                local startp, endp = line:find(model, 1, true)
                if startp then
                    local next_model = models[i % #models + 1]
                    local new_line = line:sub(1, startp - 1) .. next_model .. line:sub(endp + 1)
                    vim.api.nvim_set_current_line(new_line)
                    return
                end
            end
        end, { buffer = aibuf, desc = "轮换 AI 模型 (DEEPSEEK/CHATGPT/GEMINI)" })
    else
        vim.notify("file not exist", vim.log.levels.ERROR)
    end
end, { desc = "to open aichat session" })
