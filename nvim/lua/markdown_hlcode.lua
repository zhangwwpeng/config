-- markdown 代码块背景：给 ``` 围起来的 fenced_code_block 铺一块等宽的背景色
--
-- 用 decoration provider：每次重绘只给可见行画 ephemeral extmark，
-- 不需要 autocmd / timer，滚动、编辑、横向滚动、多窗口都由 nvim 自己驱动。
local M = {}

local api = vim.api
local ns = api.nvim_create_namespace("markdown_hlcode")

M.config = {
    hl_group = "MDCodeBlock",
    bg = "#333333", -- hl_group 没被配色定义时用的背景色
    padding_right = 4, -- 背景比最长行多出的列数
    min_width = 60, -- 背景右边界最少到第几列
    filetypes = { markdown = true, rmd = true },
}

local query ---@type vim.treesitter.Query?

---每个 buffer 缓存各代码块的背景右边界，changedtick 变了才重算（大代码块不用每次重绘都扫一遍）
---@type table<integer, { tick: integer, width: table<integer, integer> }>
local cache = {}

---@param buf integer
---@param srow integer 代码块首行（0-based）
---@param erow integer 代码块末行（0-based，含）
---@return integer 背景右边界（显示列）
local function block_width(buf, srow, erow)
    local tick = api.nvim_buf_get_changedtick(buf)
    local c = cache[buf]
    if not c or c.tick ~= tick then
        c = { tick = tick, width = {} }
        cache[buf] = c
    end
    if not c.width[srow] then
        local w = M.config.min_width
        for _, line in ipairs(api.nvim_buf_get_lines(buf, srow, erow + 1, false)) do
            w = math.max(w, vim.fn.strdisplaywidth(line))
        end
        c.width[srow] = w + M.config.padding_right
    end
    return c.width[srow]
end

---本轮重绘里各窗口的可见代码块行：win -> { leftcol, rows[row] = { indent, indent_w, width } }
local wins = {}

local function on_win(_, win, buf, toprow, botrow)
    if not M.config.filetypes[vim.bo[buf].filetype] or vim.b[buf].bigfile then
        return false
    end
    local ok, parser = pcall(vim.treesitter.get_parser, buf, "markdown", { error = false })
    if not ok or not parser then
        return false
    end
    parser:parse({ toprow, botrow + 1 })
    local tree = parser:trees()[1]
    if not tree then
        return false
    end
    query = query or vim.treesitter.query.parse("markdown", "(fenced_code_block) @block")

    local rows = {}
    for _, node in query:iter_captures(tree:root(), buf, toprow, botrow + 1) do
        local srow, _, erow, ecol = node:range()
        if ecol == 0 then
            erow = erow - 1 -- 节点结束在下一行行首时，那一行不属于代码块
        end
        local first = api.nvim_buf_get_lines(buf, srow, srow + 1, false)[1] or ""
        local indent = first:match("^%s*")
        local info = {
            indent = #indent, -- 背景从 ``` 的缩进处开始（列表里的代码块不铺到第 0 列）
            indent_w = vim.fn.strdisplaywidth(indent),
            width = block_width(buf, srow, erow),
        }
        for r = math.max(srow, toprow), math.min(erow, botrow) do
            rows[r] = info
        end
    end
    if next(rows) == nil then
        return false
    end
    wins[win] = { leftcol = vim.fn.getwininfo(win)[1].leftcol, rows = rows }
end

local function on_line(_, win, buf, row)
    local w = wins[win]
    local info = w and w.rows[row]
    if not info then
        return
    end
    local hl = M.config.hl_group
    local line = api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""

    -- 正文部分：缩进之后到行尾
    if #line > info.indent then
        api.nvim_buf_set_extmark(buf, ns, row, info.indent, { end_col = #line, hl_group = hl, ephemeral = true })
    end

    -- 行尾到右边界：用空格虚拟文本补齐（空行也从缩进处开始），横向滚动时扣掉 leftcol
    local start = math.max(vim.fn.strdisplaywidth(line), info.indent_w, w.leftcol)
    local n = info.width - start
    if n > 0 then
        api.nvim_buf_set_extmark(buf, ns, row, 0, {
            virt_text = { { string.rep(" ", n), hl } },
            virt_text_win_col = start - w.leftcol,
            ephemeral = true,
        })
    end
end

function M.setup(config)
    M.config = vim.tbl_deep_extend("force", M.config, config or {})

    local group = api.nvim_create_augroup("MarkdownHlCode", { clear = true })
    -- default = true：配色里定义了 hl_group 就用配色的；:colorscheme 会清掉高亮，所以要重设
    local function set_hl()
        api.nvim_set_hl(0, M.config.hl_group, { default = true, bg = M.config.bg })
    end
    set_hl()
    api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_hl })
    api.nvim_create_autocmd("BufWipeout", {
        group = group,
        callback = function(args)
            cache[args.buf] = nil
        end,
    })

    api.nvim_set_decoration_provider(ns, {
        on_start = function()
            wins = {}
        end,
        on_win = on_win,
        on_line = on_line,
    })
end

return M
