local M = {}

---picker 固定占 editor 高度的 40%（min = max，结果少时也不缩）
---@return { max_height: integer, min_height: integer }
local function picker_height()
    local lines = math.floor(vim.o.lines * 0.4)
    return { max_height = lines, min_height = lines }
end

------------------------------------------------------------------------
-- 输入框里给 rg / fd 传参数：`搜索词; -参数 ...`
--   init; -g '*.lua'        → rg -g '*.lua' -- init
--   init;-e lua             → fd -e lua，再用 init 模糊匹配
-- `;` 后面（可隔空格）紧跟 `-` 才算分隔符，所以 `a = b;`、`for (i = 0; i < n; i++)` 照常搜；
-- 真要搜 `; -` 时写成 `\;`。参数按 shell 规则处理引号，但不经过 shell（glob 不会被提前展开）。
------------------------------------------------------------------------

---按 shell 规则切参数：空白分隔，支持 '...' / "..." 和反斜杠转义
---@param s string
---@return string[]
local function shell_split(s)
    local args, cur, quote, i = {}, nil, nil, 1
    while i <= #s do
        local c = s:sub(i, i)
        if quote then
            if c == quote then
                quote = nil
            elseif c == "\\" and quote == '"' and i < #s then
                i = i + 1
                cur = cur .. s:sub(i, i)
            else
                cur = cur .. c
            end
        elseif c == "'" or c == '"' then
            quote, cur = c, cur or ""
        elseif c == "\\" and i < #s then
            i = i + 1
            cur = (cur or "") .. s:sub(i, i)
        elseif c:match("%s") then
            if cur then
                args[#args + 1], cur = cur, nil
            end
        else
            cur = (cur or "") .. c
        end
        i = i + 1
    end
    if cur then
        args[#args + 1] = cur
    end
    return args
end

---把输入拆成搜索词和后端参数
---@param query string
---@return string pattern
---@return string[] args
function M.split_query(query)
    local from = 1
    while true do
        local pos = query:find(";", from, true)
        if not pos then
            break
        end
        if query:sub(pos - 1, pos - 1) ~= "\\" and query:sub(pos + 1):match("^%s*%-") then
            local pattern = query:sub(1, pos - 1):gsub("%s+$", ""):gsub("\\;", ";")
            return pattern, shell_split(query:sub(pos + 1))
        end
        from = pos + 1
    end
    return (query:gsub("\\;", ";")), {}
end

---fd 的 Rust regex 转义（同 refer/providers/files.lua）
local function escape_fd_regex(s)
    return (s:gsub("([%.%+%*%?%[%]%(%)%{%}%|%^%$\\])", "\\%1"))
end

---Grep：refer 默认是 rg --vimgrep --smart-case -- <整串输入>
local function grep_command(query)
    local pattern, args = M.split_query(query)
    if pattern == "" then
        return nil -- 只写了参数还没写搜索词：先不搜
    end
    local cmd = { "rg", "--vimgrep", "--smart-case" }
    vim.list_extend(cmd, args)
    vim.list_extend(cmd, { "--", pattern })
    return cmd
end

---Files：照抄 refer 默认的 fd 命令，只是把参数插进去、模式只用搜索词部分
local function find_command(query)
    local pattern, args = M.split_query(query)
    local cmd = { vim.fn.executable("fdfind") == 1 and "fdfind" or "fd", "-H", "--type", "f", "--color", "never" }
    for _, dir in ipairs({ ".git", ".jj", "node_modules", ".cache" }) do
        vim.list_extend(cmd, { "--exclude", dir })
    end
    vim.list_extend(cmd, args)
    if pattern:find("/", 1, true) then
        local segs = vim.tbl_map(escape_fd_regex, vim.split(pattern, "/", { trimempty = true }))
        vim.list_extend(cmd, { "--full-path", "--", table.concat(segs, "[^/]*/.*") })
    elseif pattern ~= "" then
        vim.list_extend(cmd, { "--", pattern:sub(1, 2) })
    end
    return cmd
end

---<leader>f：refer 的模糊匹配默认用整串输入，`; -e lua` 也会被当成匹配内容把结果滤光，这里换成只用搜索词
function M.files()
    require("refer.providers.files").files({
        post_process = function(lines, query)
            return require("refer.fuzzy").filter(lines, (M.split_query(query)), { sorter = "lua" })
        end,
    })
end

function M.setup()
    require("refer").setup(vim.tbl_extend("force", picker_height(), {
        providers = {
            grep = { grep_command = grep_command },
            files = { find_command = find_command },
        },
        ui = {
            mark_char = "●",
            mark_hl = "String",
            input_position = "top", -- "top" or "bottom"
            reverse_result = false,
            winhighlight = "Normal:NormalFloat,SignColumn:NormalFloat,FloatBorder:NormalFloat,WinSeparator:NormalFloat,StatusLine:NormalFloat,StatusLineNC:NormalFloat",
            highlights = {
                prompt = "Title",
                selection = "CursorLine",
                header = "Type",
            },
        },
    }))
    require("refer").setup_ui_select()

    -- refer 把高度存成固定行数，窗口大小变了要重新算一次（setup 是 deep_extend 合并，只传高度即可）
    vim.api.nvim_create_autocmd("VimResized", {
        group = vim.api.nvim_create_augroup("ReferPickerHeight", { clear = true }),
        callback = function()
            require("refer").setup(picker_height())
        end,
        desc = "refer: keep picker height at 40% of editor",
    })
end

return M
