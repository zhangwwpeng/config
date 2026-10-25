-- lua/code_aireview.lua
-- AI 代码审查（DeepSeek / OpenAI 兼容接口）
-- 结果写入 quickfix：:copen 查看，回车跳转
-- 依赖环境变量 DEEPSEEK_API_KEY
-- 用法：require("code_aireview")()  或绑定键位（见 keymaps.lua）

local function ai_review()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local filetype = vim.bo[bufnr].filetype
    local filename = vim.api.nvim_buf_get_name(bufnr)

    local code = table.concat(lines, "\n")
    if vim.trim(code) == "" then
        vim.notify("当前 buffer 是空的，没什么可审查的", vim.log.levels.WARN)
        return
    end

    local api_key = vim.env.DEEPSEEK_API_KEY
    if not api_key or api_key == "" then
        vim.notify("未找到环境变量 DEEPSEEK_API_KEY", vim.log.levels.ERROR)
        return
    end

    local payload = {
        model = "deepseek-chat",
        messages = {
            {
                role = "system",
                content = [[
你是代码审查助手。
审查用户提供的代码，只返回合法 JSON，不要 Markdown 代码块，不要任何解释文字。
格式：
{
  "reviews": [
    {
      "line": 1,
      "message": "问题说明"
    }
  ]
}
要求：
- 必须对应原始文件行号。
- message 用中文，简洁说明问题和修改建议。
没有问题时返回 {"reviews": []}。
]],
            },
            {
                role = "user",
                content = string.format(
                    "文件：%s\n语言：%s\n总行数：%d\n\n代码：\n%s",
                    filename,
                    filetype,
                    #lines,
                    code
                ),
            },
        },
        temperature = 0.1,
        max_tokens = 4096,
        stream = false,
        response_format = { type = "json_object" },
    }

    vim.notify("[ai-review] 正在分析…", vim.log.levels.INFO)

    vim.system(
        {
            "curl",
            "-sS",
            "--max-time",
            "120",
            "https://api.deepseek.com/v1/chat/completions",
            "-H",
            "Content-Type: application/json",
            "-H",
            "Authorization: Bearer " .. api_key,
            "-d",
            "@-",
        },
        {
            stdin = vim.json.encode(payload),
            text = true,
        },
        vim.schedule_wrap(function(result)
            local function fail(msg)
                vim.notify("[ai-review] " .. msg, vim.log.levels.ERROR)
            end

            if result.code ~= 0 then
                return fail(result.stderr ~= "" and result.stderr or "AI 请求失败")
            end

            local out = vim.trim(result.stdout or "")
            if out == "" then
                return fail("API 返回空响应")
            end

            local ok, response = pcall(vim.json.decode, out)
            if not ok or type(response) ~= "table" then
                return fail("AI API 返回的不是合法 JSON 响应")
            end

            if response.error then
                local e = response.error
                return fail("API 错误: " .. (type(e) == "table" and (e.message or vim.inspect(e)) or tostring(e)))
            end

            local content = response.choices
                and response.choices[1]
                and response.choices[1].message
                and response.choices[1].message.content

            if type(content) ~= "string" then
                return fail(vim.inspect(response):sub(1, 500))
            end

            -- 去掉可能的 ``` 围栏 / 前后废话，尽力取出 JSON 对象
            local json = vim.trim(content:gsub("^%s*```[%w_-]*%s*\n?", ""):gsub("\n?%s*```%s*$", ""))
            local decoded_ok, data = pcall(vim.json.decode, json)
            if not decoded_ok then
                local first, last = json:find("{", 1, true), json:reverse():find("}", 1, true)
                if first and last then
                    last = #json - last + 1
                    if last > first then
                        decoded_ok, data = pcall(vim.json.decode, json:sub(first, last))
                    end
                end
            end
            if not decoded_ok or type(data) ~= "table" then
                return fail("无法解析模型输出的 JSON: " .. json:sub(1, 300))
            end

            -- 只写 quickfix，不写 diagnostic
            local line_count = vim.api.nvim_buf_line_count(bufnr)
            local items = {}
            for _, r in ipairs(type(data.reviews) == "table" and data.reviews or {}) do
                local line = tonumber(r.line)
                local msg = r.message and vim.trim(tostring(r.message)) or ""
                if line and msg ~= "" and line >= 1 and line <= line_count then
                    items[#items + 1] = {
                        bufnr = bufnr,
                        lnum = line,
                        col = 1,
                        text = msg,
                    }
                end
            end

            if #items == 0 then
                vim.notify("[ai-review] 未发现问题", vim.log.levels.INFO)
                return
            end

            vim.fn.setqflist({}, " ", {
                title = "AI Review: " .. (filename ~= "" and vim.fn.fnamemodify(filename, ":t") or "[No Name]"),
                items = items,
            })
            vim.cmd("copen")
            vim.notify(("[ai-review] %d 条建议已写入 quickfix"):format(#items), vim.log.levels.INFO)
        end)
    )
end

return ai_review
