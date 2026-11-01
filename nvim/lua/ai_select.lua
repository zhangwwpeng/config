------------------------------------------------------------------------
-- ai_select: visual 选中文本 -> curl 发给 AI -> 左侧浮窗流式显示
------------------------------------------------------------------------
-- 数据流：
--   选区 + 当前 filetype + 行号  ->  先让用户输入补充要求（拼在 default_prompt 后面）
--   -> 拼成 user message
--   -> curl（OpenAI 兼容 /chat/completions，SSE 流式）
--   -> 解析 "data: {...}" 增量 -> 追加到左侧浮动窗口
--
-- 用法：
--   （键位见下面 defaults.keymaps，只有命令面板里执行 "enable ai" 之后才生效）
--   x A   对选区提问：输入的要求会和默认提示词合并后一起发送（留空只发默认）
--         选区可以是空的（空白行 / 没选中正文），照样提问
--         块 visual（<C-v>）下不触发，仍是原生的块尾追加
--   x H   同上，但不问输入，直接用默认提示词发出
--   n M   进入结果浮窗（滚动查看，q 关闭，r 重试）
--   :'<,'>AIAsk    同上（带 range；不带 range 就用当前行）
--   :'<,'>AIQuick  不问输入，直接用默认提示词发
--   :AICancel      取消当前请求并关窗
--
-- 浮窗内：q / <Esc> 关闭，r 重试，y 复制回答
--
-- 配置（init.lua）：
--   require("ai_select").setup({
--     api = {
--       endpoint = "https://api.deepseek.com/chat/completions",
--       model = "deepseek-chat",
--       api_key_env = "DEEPSEEK_API_KEY",
--     },
--     -- 固定提示词；用户输入的内容会拼在它后面，留空则只发它
--     default_prompt = "请解释下面选中的内容",
--   })
--
-- 其他 OpenAI 兼容服务只需换 endpoint/model/api_key_env：
--   OpenRouter: https://openrouter.ai/api/v1/chat/completions + OPENROUTER_API_KEY
--   本地代理:   http://127.0.0.1:15721/v1/chat/completions + api.key_required = false
------------------------------------------------------------------------

local M = {}

---@class AiSelectAction
---@field name string
---@field prompt string

------------------------------------------------------------------------
-- 默认配置
------------------------------------------------------------------------

local defaults = {
    api = {
        endpoint = "https://api.deepseek.com/chat/completions",
        model = "deepseek-chat",
        ---@type string|false 读哪个环境变量作为 Bearer token；false/"" 表示不带鉴权头
        api_key_env = "DEEPSEEK_API_KEY",
        ---@type boolean 找不到 key 时是否直接报错（本地代理可设 false）
        key_required = true,
        temperature = 0.3,
        max_tokens = 4096,
        timeout = 180,
        stream = true,
        ---@type table<string, string>
        extra_headers = {},
        ---@type table 合并进请求体的额外字段，例如 { reasoning_effort = "high" }
        extra_body = {},
    },
    system = "你是一名资深软件工程师。回答使用中文，代码、命令和标识符保持原样。"
        .. "只讨论用户选中的内容，不要臆造不存在的上下文；"
        .. "不确定的地方明确说明。"
        .. "不要使用Markdown语法, 使用 1、2、 3、列表或分段来组织回答。",
    ---@type string 固定提示词；用户输入的要求会拼在它后面，留空则只发它
    default_prompt = "这是nevim发送给你的选中内容，可能是一段代码，或是lsp的诊断信息或lsp的hover信息,"
        .. "你要去判断它的类型，代码一般是解释，lsp的诊断信息一般是分析，lsp的hover信息一般是解释，你不需要说出它的类型，只需要根据它的类型去分析或解释它，"
        .. "如果没有正文内容，或者正文内容是空白行，你直接回答提出的问题即可，不要说没有正文内容。",
    window = {
        width_ratio = 0.38,
        min_width = 40,
        height_offset = 4,
        border = "rounded",
        filetype = "markdown",
    },
    keymaps = {
        ask = "A",
        quick = "H",
        focus = "M",
    },
}

M.config = vim.deepcopy(defaults)

------------------------------------------------------------------------
-- 状态
------------------------------------------------------------------------

local state = {
    ---@type integer? 当前 job id
    job = nil,
    ---@type integer 请求代号：每次新请求 +1，迟到的回调靠它丢弃
    token = 0,
    ---@type integer? 结果 buffer
    buf = nil,
    ---@type integer? 结果浮窗
    win = nil,
    ---@type string 窗口标题
    title = " AI ",
    ---@type string[] 回答分片
    chunks = {},
    ---@type string? 等待模型时的占位文字
    placeholder = nil,
    ---@type string SSE 半行缓存
    pending = "",
    ---@type string[] 非 SSE 的整段 JSON
    raw = {},
    ---@type string[] curl stderr
    stderr = {},
    ---@type string? 解析出的错误
    error = nil,
    ---@type string 本次请求体临时文件
    body_file = nil,
    ---@type table? 上一次的上下文（r 重试要用）
    ctx = nil,
    ---@type AiSelectAction? 上一次的动作（r 重试要用）
    action = nil,
}

local render -- 前置声明，schedule_render 先用

------------------------------------------------------------------------
-- 渲染
------------------------------------------------------------------------

local function answer_text()
    return table.concat(state.chunks, "")
end

---重画结果 buffer，并在浮窗不是当前窗口时跟随到底部
render = function()
    local buf = state.buf
    if not (buf and vim.api.nvim_buf_is_valid(buf)) then
        return
    end

    local text = answer_text()
    if text == "" then
        text = state.placeholder or ""
    end

    local lines = vim.split(text, "\n", { plain = true })
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false

    local win = state.win
    if win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_get_current_win() ~= win then
        pcall(vim.api.nvim_win_set_cursor, win, { #lines, 0 })
    end
end

local render_scheduled = false
local function schedule_render()
    if render_scheduled then
        return
    end
    render_scheduled = true
    -- 流式 chunk 很密，60ms 合并一次，避免每个 token 都重写整个 buffer
    vim.defer_fn(function()
        render_scheduled = false
        render()
    end, 60)
end

local function set_content(text)
    state.chunks = { text }
    state.placeholder = nil
    render()
end

------------------------------------------------------------------------
-- 窗口 / buffer
------------------------------------------------------------------------

local function close_win_only()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        pcall(vim.api.nvim_win_close, state.win, true)
    end
    state.win = nil
end

local function stop_job()
    state.token = state.token + 1 -- 让所有在途回调失效
    if state.job then
        pcall(vim.fn.jobstop, state.job)
        state.job = nil
    end
    if state.body_file then
        pcall(vim.fn.delete, state.body_file)
        state.body_file = nil
    end
end

M.close = function()
    stop_job()
    close_win_only()
    state.ctx = nil
    state.action = nil
end

M.cancel = M.close

local function buf_keymaps(buf)
    local function map(lhs, fn, desc)
        vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, silent = true, desc = desc })
    end
    map("q", M.close, "[ai_select] close")
    map("<Esc>", M.close, "[ai_select] close")
    map("y", function()
        local text = answer_text()
        vim.fn.setreg("+", text)
        vim.notify("ai_select: 已复制 " .. #text .. " 字节", vim.log.levels.INFO)
    end, "[ai_select] yank answer")
    map("r", function()
        if state.ctx and state.action then
            M._start(state.ctx, state.action)
        end
    end, "[ai_select] retry")
end

local function ensure_buf()
    local buf = state.buf
    if buf and vim.api.nvim_buf_is_valid(buf) then
        return buf
    end
    buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = M.config.window.filetype
    vim.bo[buf].undolevels = -1
    state.buf = buf
    buf_keymaps(buf)
    return buf
end

local function open_win()
    local buf = ensure_buf()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        pcall(vim.api.nvim_win_set_config, state.win, { title = state.title })
        return state.win
    end

    local cols, rows = vim.o.columns, vim.o.lines
    local w = M.config.window
    local width = math.floor(cols * w.width_ratio)
    local height = rows - 2

    local win = vim.api.nvim_open_win(buf, false, {
        relative = "editor",
        anchor = "NW",
        row = 0,
        col = 0,
        width = width,
        height = height,
        style = "minimal",
        border = w.border,
        title = "Ai chat",
        title_pos = "center",
        zindex = 60,
    })

    vim.wo[win].wrap = true
    vim.wo[win].linebreak = false
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = "no"
    vim.wo[win].foldcolumn = "0"
    vim.wo[win].foldmethod = "manual"
    vim.wo[win].cursorline = false
    vim.wo[win].spell = false
    vim.wo[win].conceallevel = 0
    vim.wo[win].winblend = tonumber(vim.g.float_win_blend) or 0

    state.win = win
    return win
end

function M.toggle()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        M.close()
    elseif state.buf and vim.api.nvim_buf_is_valid(state.buf) and answer_text() ~= "" then
        open_win()
    else
        vim.notify("ai_select: 还没有结果，选中文本后按 " .. M.config.keymaps.ask, vim.log.levels.INFO)
    end
end

---进入结果浮窗（可以自由滚动；q 关闭，r 重试）
function M.focus()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_set_current_win(state.win)
    else
        M.toggle()
    end
end

function M.is_busy()
    return state.job ~= nil
end

function M.get_answer()
    return answer_text()
end

------------------------------------------------------------------------
-- 请求
------------------------------------------------------------------------

---固定提示词（用户没输入时用）
---@return string
local function default_prompt()
    local p = M.config.default_prompt
    if type(p) ~= "string" or vim.trim(p) == "" then
        return "请解释下面选中的内容。"
    end
    return p
end

---弹一个输入框拿用户的要求；输入会拼在固定提示词后面一起发送，留空 / 取消 就只发固定提示词
---@param ft string
---@param cb fun(action: AiSelectAction)
local function ask_prompt(ft, cb)
    local base = default_prompt()
    local label = ft ~= "" and ft or "text"
    vim.ui.input({ prompt = ("AI [%s] 补充要求（留空只用默认提示词）: "):format(label) }, function(input)
        local extra = vim.trim(input or "")
        if extra == "" then
            cb({ name = "默认", prompt = base })
        else
            cb({ name = "合并", prompt = base .. "\n\n" .. extra })
        end
    end)
end

---@param ctx table
---@param action AiSelectAction
---@return string
local function user_message(ctx, action)
    local ft = ctx.ft ~= "" and ctx.ft or "text"
    local fence = ft:gsub("[^%w_+.-]", "")
    if fence == "" then
        fence = "text"
    end
    local parts = {
        action.prompt,
        "",
        ("文件: %s"):format(ctx.path),
        ("类型: %s"):format(ft),
        ("行号: %d-%d"):format(ctx.line_start, ctx.line_end),
    }
    -- 选中内容可能为空（比如选了一行空白，或者只想要一个不依赖代码的回答）
    if ctx.text ~= "" then
        parts[#parts + 1] = ""
        parts[#parts + 1] = "```" .. fence
        parts[#parts + 1] = ctx.text
        parts[#parts + 1] = "```"
    else
        parts[#parts + 1] = "（没有选中正文，仅根据上面的问题回答）"
    end
    return table.concat(parts, "\n")
end

---@return table
local function build_body(ctx, action)
    local api = M.config.api
    local messages = {}
    if type(M.config.system) == "string" and M.config.system ~= "" then
        messages[#messages + 1] = { role = "system", content = M.config.system }
    end
    messages[#messages + 1] = { role = "user", content = user_message(ctx, action) }

    local body = {
        model = api.model,
        stream = api.stream ~= false,
        temperature = api.temperature,
        max_tokens = api.max_tokens,
        messages = messages,
    }
    if type(api.extra_body) == "table" and next(api.extra_body) ~= nil then
        body = vim.tbl_deep_extend("force", body, api.extra_body)
    end
    return body
end

---@param body_file string
---@return string[]
local function build_cmd(body_file)
    local api = M.config.api
    local cmd = {
        "curl",
        "-sS", -- 静默但保留错误输出
        "-N", -- 关闭 curl 自己的输出缓冲，SSE 才能实时到
        "--max-time",
        tostring(api.timeout),
        "-H",
        "Content-Type: application/json",
        "-H",
        "Accept: " .. (api.stream ~= false and "text/event-stream" or "application/json"),
    }

    local env = api.api_key_env
    if type(env) == "string" and env ~= "" then
        local key = vim.env[env]
        if type(key) == "string" and key ~= "" then
            cmd[#cmd + 1] = "-H"
            cmd[#cmd + 1] = "Authorization: Bearer " .. key
        end
    end

    for k, v in pairs(api.extra_headers or {}) do
        cmd[#cmd + 1] = "-H"
        cmd[#cmd + 1] = k .. ": " .. tostring(v)
    end

    cmd[#cmd + 1] = "--data-binary"
    cmd[#cmd + 1] = "@" .. body_file
    cmd[#cmd + 1] = api.endpoint
    return cmd
end

local function api_key_missing()
    local api = M.config.api
    local env = api.api_key_env
    if type(env) ~= "string" or env == "" or api.key_required == false then
        return false
    end
    local key = vim.env[env]
    return type(key) ~= "string" or key == ""
end

---从一条 OpenAI 兼容响应里取增量文本
---@param obj table
---@return string?
local function extract_text(obj)
    local choices = obj.choices
    if type(choices) ~= "table" then
        return nil
    end
    local first = choices[1]
    if type(first) ~= "table" then
        return nil
    end
    if type(first.delta) == "table" and type(first.delta.content) == "string" then
        return first.delta.content
    end
    if type(first.message) == "table" and type(first.message.content) == "string" then
        return first.message.content
    end
    if type(first.text) == "string" then
        return first.text
    end
    return nil
end

local function fail(msg)
    state.error = msg
end

---处理一行 stdout（SSE 的 "data: ..." 或整段 JSON）
---@param line string
local function handle_line(line)
    line = (line or ""):gsub("\r$", "")
    if line == "" then
        return
    end

    local payload = line:match("^data:%s?(.*)$")
    if payload == nil then
        -- 有的网关忽略 stream=true，直接返回整段 JSON
        if line:sub(1, 1) == "{" then
            state.raw[#state.raw + 1] = line
        end
        return
    end
    if payload == "[DONE]" then
        return
    end

    local ok, obj = pcall(vim.json.decode, payload)
    if not ok or type(obj) ~= "table" then
        return
    end

    if obj.error then
        local e = obj.error
        local msg = type(e) == "table" and (e.message or vim.inspect(e)) or tostring(e)
        fail(msg)
        return
    end

    local text = extract_text(obj)
    if text and text ~= "" then
        state.chunks[#state.chunks + 1] = text
        schedule_render()
    end
end

---把 jobstart 回调里按行切好的数据拼起来；最后一段可能是不完整的行
---@param data string[]
local function on_stdout(_, data)
    if not data or #data == 0 then
        return
    end
    data[1] = state.pending .. data[1]
    state.pending = ""

    -- 没有以空串结尾 => 最后一项还没收到换行，留到下一次回调
    if data[#data] ~= "" then
        state.pending = table.remove(data)
    end

    for _, line in ipairs(data) do
        handle_line(line)
    end
end

local function finalize(token, code)
    if state.token ~= token then
        return
    end
    state.job = nil

    if state.pending ~= "" then
        handle_line(state.pending)
        state.pending = ""
    end

    -- 非流式响应：整段 JSON 只在 on_exit 里解
    if #state.chunks == 0 and #state.raw > 0 then
        local ok, obj = pcall(vim.json.decode, table.concat(state.raw, ""))
        if ok and type(obj) == "table" then
            if obj.error then
                local e = obj.error
                fail(type(e) == "table" and (e.message or vim.inspect(e)) or tostring(e))
            else
                local text = extract_text(obj)
                if text and text ~= "" then
                    state.chunks[#state.chunks + 1] = text
                end
            end
        end
    end

    local text = answer_text()
    local stderr = table.concat(state.stderr, ""):gsub("%s+$", "")
    local err = state.error
    if not err and code ~= 0 then
        err = stderr ~= "" and stderr or ("curl 退出码 " .. code)
    end

    state.placeholder = nil
    if err and text == "" then
        set_content("❌ 请求失败\n\n" .. err)
        vim.notify("ai_select: " .. err, vim.log.levels.ERROR)
    elseif text == "" then
        set_content("❌ 模型没有返回内容" .. (stderr ~= "" and ("\n\n" .. stderr) or ""))
        vim.notify("ai_select: 模型没有返回内容", vim.log.levels.WARN)
    else
        render()
    end

    if state.body_file then
        local f = state.body_file
        state.body_file = nil
        vim.schedule(function()
            pcall(vim.fn.delete, f)
        end)
    end
end

---@param ctx table
---@param action AiSelectAction
function M._start(ctx, action)
    stop_job()

    state.ctx, state.action = ctx, action
    state.chunks, state.raw, state.stderr = {}, {}, {}
    state.pending, state.error = "", nil
    state.placeholder = "⏳ 请求中…"

    local ft = ctx.ft ~= "" and ctx.ft or "text"
    state.title = (" AI · %s · %s "):format(ft, action.name)
    open_win()
    render()

    local body = build_body(ctx, action)
    local body_file = vim.fn.tempname() .. ".json"
    local ok = pcall(vim.fn.writefile, { vim.json.encode(body) }, body_file)
    if not ok then
        set_content("❌ 无法写入临时请求文件: " .. body_file)
        return
    end
    state.body_file = body_file

    local token = state.token
    local job = vim.fn.jobstart(build_cmd(body_file), {
        stdout_buffered = false,
        on_stdout = function(_, data)
            if state.token ~= token then
                return
            end
            on_stdout(_, data)
        end,
        on_stderr = function(_, data)
            if state.token ~= token then
                return
            end
            for _, line in ipairs(data or {}) do
                state.stderr[#state.stderr + 1] = line .. "\n"
            end
        end,
        on_exit = function(_, code)
            finalize(token, code)
        end,
    })

    if job <= 0 then
        state.body_file = nil
        pcall(vim.fn.delete, body_file)
        set_content("❌ 无法启动 curl（jobstart 失败）")
        return
    end
    state.job = job
end

------------------------------------------------------------------------
-- 入口
------------------------------------------------------------------------

---@param start_row integer
---@param end_row integer
---@return string
local function lines_of_range(start_row, end_row)
    return table.concat(vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false), "\n")
end

---@return string, integer, integer
local function visual_selection()
    local s = vim.fn.getpos("v")
    local e = vim.fn.getpos(".")
    local mode = vim.fn.mode()
    local text = table.concat(vim.fn.getregion(s, e, { type = mode }), "\n")
    vim.cmd("normal! \27")

    local srow, erow = s[2], e[2]
    if srow > erow then
        srow, erow = erow, srow
    end
    return text, srow, erow
end

---收集当前片区的上下文（mode / range / 当前行，选区可以为空）
---@param range integer[]? {line1, line2}，命令行命令用
---@return table?
local function collect(range)
    if vim.fn.executable("curl") ~= 1 then
        vim.notify("ai_select: 找不到 curl", vim.log.levels.ERROR)
        return nil
    end
    if api_key_missing() then
        vim.notify(("ai_select: 环境变量 %s 未设置"):format(M.config.api.api_key_env), vim.log.levels.ERROR)
        return nil
    end

    local text, srow, erow
    local mode = vim.fn.mode()
    if mode == "v" or mode == "V" or mode == "\22" then
        local ok, t, s, e = pcall(visual_selection)
        if not ok then
            vim.notify("ai_select: 读取选区失败: " .. tostring(t), vim.log.levels.ERROR)
            return nil
        end
        text, srow, erow = t, s, e
    elseif range then
        srow, erow = range[1], range[2]
        text = lines_of_range(srow, erow)
    else
        srow = vim.api.nvim_win_get_cursor(0)[1]
        erow = srow
        text = lines_of_range(srow, srow)
    end

    -- 选区可以为空：空白行 / 只选了几个空格也照常提问
    text = vim.trim(text or "")

    local name = vim.api.nvim_buf_get_name(0)
    return {
        text = text,
        ft = vim.bo.filetype,
        path = name ~= "" and vim.fn.fnamemodify(name, ":~:.") or "[No Name]",
        line_start = srow,
        line_end = erow,
    }
end

---先弹输入框问用户要补充要求（留空只用默认提示词）
---@param range integer[]? {line1, line2}，命令行 :'<,'>AIAsk 用
function M.ask(range)
    local ctx = collect(range)
    if not ctx then
        return
    end
    ask_prompt(ctx.ft, function(action)
        M._start(ctx, action)
    end)
end

---直接发：不弹输入框，只用默认提示词（visual 模式用）
---@param range integer[]? {line1, line2}，命令行 :'<,'>AIQuick 用
function M.ask_quick(range)
    local ctx = collect(range)
    if not ctx then
        return
    end
    M._start(ctx, { name = "默认", prompt = default_prompt() })
end

---@param opts? table
function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

    local maps = M.config.keymaps
    vim.keymap.set("x", maps.ask, function()
        -- 块 visual（<C-v>）下把键原样交还给 nvim：默认 ask = "A"，不能盖掉 v_b_A 块尾追加
        -- （"n" = 不走映射直接执行内置命令；"i" = 插到输入队列最前，宏 / 快速输入时后续按键不会抢到前面）
        if vim.fn.mode() == "\22" then
            vim.api.nvim_feedkeys(maps.ask, "ni", false)
            return
        end
        M.ask()
    end, { desc = "[ai_select] 输入补充要求后问 AI（块 visual 下保留原生行为）" })
    vim.keymap.set("x", maps.quick, function()
        M.ask_quick()
    end, { desc = "[ai_select] 直接发送（用默认提示词，不问输入）" })
    -- vim.keymap.set("n", maps.ask, function()
    --     M.toggle()
    -- end, { desc = "[ai_select] 打开/关闭结果浮窗" })
    vim.keymap.set("n", maps.focus, function()
        M.toggle()
    end, { desc = "[ai_select] 聚焦结果浮窗" })

    local function cmd_range(c)
        return c.range > 0 and { c.line1, c.line2 } or nil
    end
    vim.api.nvim_create_user_command("AIAsk", function(c)
        M.ask(cmd_range(c))
    end, { range = true, desc = "ai_select: 问 AI（可用 range）" })
    vim.api.nvim_create_user_command("AIQuick", function(c)
        M.ask_quick(cmd_range(c))
    end, { range = true, desc = "ai_select: 不问输入，直接用默认提示词发（可用 range）" })
    vim.api.nvim_create_user_command("AICancel", function()
        M.close()
    end, { desc = "ai_select: 取消请求并关窗" })

    -- 退出时不留下 curl 子进程和临时请求文件
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("AiSelect", { clear = true }),
        callback = stop_job,
        desc = "[ai_select] stop curl on exit",
    })
end

M._state = state -- 调试/测试用

return M
