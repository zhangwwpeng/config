local M = {}

local state = {
    win = nil,
    float_bufnr = nil,
    source_bufnr = nil,
    virtual_lines_paused = false,
    anchor_bufnr = nil,
    anchor_lnum = nil,
}

local shadow_ns = vim.api.nvim_create_namespace("CodePreviewShadow")

local function set_virtual_lines_active(active)
    if active then
        vim.diagnostic.config({ virtual_lines = { current_line = true } })
    else
        vim.diagnostic.config({ virtual_lines = false })
    end
end

local function clear()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end
    if state.source_bufnr and vim.api.nvim_buf_is_valid(state.source_bufnr) then
        vim.api.nvim_buf_clear_namespace(state.source_bufnr, shadow_ns, 0, -1)
    end
    if state.virtual_lines_paused then
        set_virtual_lines_active(true)
    end
    state.win = nil
    state.float_bufnr = nil
    state.source_bufnr = nil
    state.virtual_lines_paused = false
    state.anchor_bufnr = nil
    state.anchor_lnum = nil
end

local function normalize_message(msg)
    msg = tostring(msg or ""):gsub("\r", " "):gsub("\n", " ")
    msg = msg:gsub("%s+", " ")
    return vim.trim(msg)
end

local function to_list(value)
    if value == nil then
        return {}
    end
    if type(value) == "table" then
        local out = {}
        for _, item in ipairs(value) do
            local normalized = normalize_message(item)
            if normalized ~= "" then
                out[#out + 1] = normalized
            end
        end
        return out
    end
    local normalized = normalize_message(value)
    if normalized == "" then
        return {}
    end
    return { normalized }
end

local function append_section(virt_lines, title, hl, messages)
    if #messages == 0 then
        return
    end
    virt_lines[#virt_lines + 1] = { title = title, hl = hl }
    for _, msg in ipairs(messages) do
        virt_lines[#virt_lines + 1] = { text = "  - " .. msg }
    end
end

local function build_virt_lines(payload)
    local info_list = to_list(payload.info)
    local error_list = to_list(payload.error)
    local msg_list = to_list(payload.msg or payload.msm)
    local warn_list = to_list(payload.warn)
    local suggestion_list = to_list(payload.suggestion)

    local lines = {}
    if #info_list + #error_list + #msg_list + #warn_list + #suggestion_list == 0 then
        return lines
    end

    append_section(lines, "ERROR", "DiagnosticError", error_list)
    append_section(lines, "WARN", "DiagnosticWarn", warn_list)
    append_section(lines, "INFO", "DiagnosticInfo", info_list)
    append_section(lines, "MESSAGE", "Normal", msg_list)
    append_section(lines, "SUGGESTION", "DiagnosticHint", suggestion_list)
    return lines
end

local function plain_lines(sections)
    local lines = {}
    for _, item in ipairs(sections) do
        if item.title then
            lines[#lines + 1] = { text = item.title, hl = item.hl }
        else
            lines[#lines + 1] = { text = item.text, hl = "Normal" }
        end
    end
    return lines
end

local function get_covered_buffer_lines(cur_win, row, height)
    local top_lnum = vim.fn.line("w0", cur_win)
    local bot_lnum = vim.fn.line("w$", cur_win)
    local visible_start = row + 1
    local visible_end = row + height

    local covered = {}
    for wline = visible_start, visible_end do
        local lnum = top_lnum + wline - 1
        if lnum >= top_lnum and lnum <= bot_lnum then
            local text = normalize_message(vim.fn.getline(lnum))
            if text == "" then
                text = " "
            end
            covered[#covered + 1] = text
        end
    end

    -- In some edge cases (window bottom / redraw timing), the mapping above may
    -- under-count by one. Top up one extra visible line when possible.
    if #covered < height then
        local next_lnum = top_lnum + visible_end
        if next_lnum <= bot_lnum then
            local text = normalize_message(vim.fn.getline(next_lnum))
            covered[#covered + 1] = (text == "" and " " or text)
        end
    end
    return covered
end

local function render_shadow_lines(source_bufnr, cursor_lnum, covered_lines)
    if #covered_lines == 0 then
        return
    end

    local virt_lines = {
        { { string.rep("-", 20) .. " covered code " .. string.rep("-", 20), "Comment" } },
    }
    for _, text in ipairs(covered_lines) do
        virt_lines[#virt_lines + 1] = { { "| " .. text, "Comment" } }
    end

    vim.api.nvim_buf_set_extmark(source_bufnr, shadow_ns, cursor_lnum, 0, {
        virt_lines = virt_lines,
        virt_lines_above = false,
        hl_mode = "combine",
    })
end

local function open_float(sections, cursor_lnum)
    local cur_win = vim.api.nvim_get_current_win()
    local source_bufnr = vim.api.nvim_get_current_buf()
    local body_lines = plain_lines(sections)

    local win_width = vim.api.nvim_win_get_width(cur_win)
    local win_height = vim.api.nvim_win_get_height(cur_win)
    local cursor_win_line = vim.fn.winline()

    local width = math.max(1, win_width)
    local sep = string.rep("─", math.max(1, width - 1))
    local lines = { { text = sep, hl = "WinSeparator" } }
    vim.list_extend(lines, body_lines)
    lines[#lines + 1] = { text = sep, hl = "WinSeparator" }
    local total_lines = #lines

    local height = math.min(total_lines, math.max(3, win_height - 1))

    local below_space = win_height - cursor_win_line
    local row
    if below_space >= height then
        row = cursor_win_line
    else
        row = math.max(0, cursor_win_line - 1 - height)
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].modifiable = true
    local render = vim.list_slice(lines, 1, height)
    local render_text = {}
    for _, item in ipairs(render) do
        render_text[#render_text + 1] = item.text
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, render_text)
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = "code_preview"

    for i, item in ipairs(render) do
        if i > height then
            break
        end
        if item.hl and item.hl ~= "Normal" then
            vim.api.nvim_buf_add_highlight(buf, 0, item.hl, i - 1, 0, -1)
        end
    end

    local win = vim.api.nvim_open_win(buf, false, {
        relative = "win",
        win = cur_win,
        width = width,
        height = height,
        row = row,
        col = 0,
        anchor = "NW",
        style = "minimal",
        border = "none",
        noautocmd = true,
        zindex = 70,
    })

    vim.wo[win].wrap = false
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].cursorline = false
    vim.wo[win].signcolumn = "no"
    vim.wo[win].winhighlight = "NormalFloat:Normal"

    state.win = win
    state.float_bufnr = buf
    state.source_bufnr = source_bufnr
    state.virtual_lines_paused = true
    state.anchor_bufnr = source_bufnr
    state.anchor_lnum = cursor_lnum
    set_virtual_lines_active(false)

    local covered_lines = get_covered_buffer_lines(cur_win, row, height)
    render_shadow_lines(source_bufnr, cursor_lnum, covered_lines)
end

local function resolve_target_lnum(line, bufnr)
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    if line_count <= 0 then
        return 0
    end

    if type(line) ~= "number" then
        local cursor_lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
        return math.max(0, math.min(cursor_lnum, line_count - 1))
    end

    -- API uses 1-based line number by default.
    local target = math.floor(line) - 1
    return math.max(0, math.min(target, line_count - 1))
end

--- Preview structured content under current line.
--- payload fields: info, error, msg/msm, warn, suggestion
---@param payload table
function M.preview(payload)
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
    M.preview_at(cursor_line, payload)
end

--- Preview structured content at a specific line.
--- line: 1-based line number
--- payload fields: info, error, msg/msm, warn, suggestion
---@param line number
---@param payload table
function M.preview_at(line, payload)
    clear()

    local bufnr = vim.api.nvim_get_current_buf()
    local target_lnum = resolve_target_lnum(line, bufnr)
    local sections = build_virt_lines(payload or {})
    if #sections == 0 then
        vim.notify("No preview content", vim.log.levels.INFO)
        return
    end

    -- Keep rendering anchored to current view, but preserve close logic by target line.
    open_float(sections, target_lnum)
end

--- Build payload from current-line diagnostics and preview it.
function M.preview_current_line()
    local bufnr = vim.api.nvim_get_current_buf()
    local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
    local diags = vim.diagnostic.get(bufnr, { lnum = lnum })

    local payload = {
        error = {},
        warn = {},
        info = {},
        suggestion = {},
    }
    for _, d in ipairs(diags) do
        local message = d.source and (d.source .. ": " .. (d.message or "")) or d.message
        if d.severity == vim.diagnostic.severity.ERROR then
            payload.error[#payload.error + 1] = message
        elseif d.severity == vim.diagnostic.severity.WARN then
            payload.warn[#payload.warn + 1] = message
        elseif d.severity == vim.diagnostic.severity.INFO then
            payload.info[#payload.info + 1] = message
        else
            payload.suggestion[#payload.suggestion + 1] = message
        end
    end
    M.preview_at(lnum + 1, payload)
end

function M.setup()
    local group = vim.api.nvim_create_augroup("CodePreview", { clear = true })
    vim.api.nvim_create_autocmd("CursorMoved", {
        group = group,
        callback = function()
            if not state.win or not vim.api.nvim_win_is_valid(state.win) then
                return
            end
            local bufnr = vim.api.nvim_get_current_buf()
            local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
            if bufnr ~= state.anchor_bufnr or lnum ~= state.anchor_lnum then
                clear()
            end
        end,
    })
    vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
        group = group,
        callback = clear,
    })
end

return M
