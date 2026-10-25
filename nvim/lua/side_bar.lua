local M = {}

---@class SideBarSlot
---@field win integer
---@field buf integer

---@type { top: SideBarSlot, bottom: SideBarSlot, group: integer? }
local state = {
    top = { win = -1, buf = -1 },
    bottom = { win = -1, buf = -1 },
    group = nil,
}

---左侧上下两栏 float（侧边栏）：宽度占屏幕 1/4，高度撑满整个屏幕，上下 6:4
local opts = {
    width_ratio = 0.25, -- 宽度 = 屏幕宽度 * width_ratio，靠左
    height_ratio = 0.6, -- 上栏占高度的比例，下栏拿剩下的（默认 6:4）
    top_height = nil, -- 填了就用固定内容行数，忽略 height_ratio
    bottom_height = nil,
    border = "bottom", -- "bottom"=只画最下面一根线 | "rounded"/"single"=完整边框 | "none"
    -- 配色：和 code_picker 一致，全部走 NormalFloat（colorscheme 里 NormalFloat = bg_drak1），
    -- 不这样的话 FloatBorder 会带上别的配色
    winhl = table.concat({
        "Normal:NormalFloat",
        "FloatBorder:NormalFloat",
        "WinSeparator:NormalFloat",
    }, ","),
    keymap = "<leader>9",
}

------------------------------------------------------------------------
-- 几何计算
------------------------------------------------------------------------

---@return boolean 是否有上/下/左/右边框
local function has_side_border()
    local b = opts.border
    return b ~= false and b ~= "none" and b ~= "bottom"
end

---某一边框的配置
---border 顺序：左上、上、右上、右、右下、下、左下、左
---@return string|string[]|nil border nvim_open_win 的 border 配置
---@return integer pad_y 上下边框各占的行数
---@return integer pad_x 左右边框各占的列数
local function border_config()
    local b = opts.border
    if b == false or b == "none" then return nil, 0, 0 end
    if b == "bottom" then return { "", "", "", "", "", "─", "", "" }, 1, 0 end
    return b, 2, 2
end

---两栏的尺寸：宽度靠左取 width_ratio，高度撑满屏幕，上下 6:4
---@return integer width 内容宽度
---@return integer col 左边界列
---@return table top { row, height }
---@return table bottom { row, height }
local function geometry()
    local pad_y, pad_x = select(2, border_config())
    local width = math.max(2, math.floor(vim.o.columns * opts.width_ratio) - pad_x * 2)
    local col = 0 -- 靠左

    -- 可用总行数（留出命令行那一行）
    local total = math.max(4, vim.o.lines - vim.o.cmdheight)

    local top_h, bottom_h
    if opts.top_height and opts.bottom_height then
        top_h, bottom_h = opts.top_height, opts.bottom_height
    else
        local top_span = math.floor(total * opts.height_ratio) -- 上栏总占行数（含下边框）
        top_h = math.max(1, top_span - pad_y)
        bottom_h = math.max(1, total - top_span - pad_y)
    end

    local top_span = top_h + pad_y -- 上栏内容 + 下边框，下栏紧接着它开始
    return width, col, { row = 0, height = top_h }, { row = top_span, height = bottom_h }
end

------------------------------------------------------------------------
-- buffer / window
------------------------------------------------------------------------

---@param slot SideBarSlot
---@param title string
local function ensure_buf(slot, title)
    if vim.api.nvim_buf_is_valid(slot.buf) then return end
    local buf = vim.api.nvim_create_buf(false, false)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].swapfile = false
    vim.bo[buf].undolevels = -1
    vim.bo[buf].modifiable = false
    pcall(vim.api.nvim_buf_set_name, buf, "side_bar://" .. title)
    slot.buf = buf
end

---@param slot SideBarSlot
---@param title string
---@param width integer
---@param col integer
---@param geo table { row, height }
local function open_win(slot, title, width, col, geo)
    local border = border_config()
    local config = {
        relative = "editor",
        row = geo.row,
        col = col,
        width = width,
        height = geo.height,
        style = "minimal",
        zindex = 50,
        focusable = false, -- 不抢焦点，也不参与 <C-w> 窗口跳转
        noautocmd = true,
    }
    if border then config.border = border end
    -- title 需要完整边框才画得出来
    if has_side_border() then
        config.title = title
        config.title_pos = "center"
    end
    slot.win = vim.api.nvim_open_win(slot.buf, false, config)
    -- nvim_open_win 不接受 winhl，只能开完再设
    vim.wo[slot.win].winhl = opts.winhl
end

---@param slot SideBarSlot
---@return boolean
local function is_open(slot)
    return vim.api.nvim_win_is_valid(slot.win)
end

---两栏都开着时按新尺寸重排
local function layout()
    if not (is_open(state.top) and is_open(state.bottom)) then return end
    local width, col, top_geo, bottom_geo = geometry()
    for _, item in ipairs({
        { slot = state.top, geo = top_geo },
        { slot = state.bottom, geo = bottom_geo },
    }) do
        if is_open(item.slot) then
            vim.api.nvim_win_set_config(item.slot.win, {
                relative = "editor",
                row = item.geo.row,
                col = col,
                width = width,
                height = item.geo.height,
            })
        end
    end
end

------------------------------------------------------------------------
-- 内容设置
------------------------------------------------------------------------

---把用户传进来的东西统一成行数组：字符串按 \n 拆，数字转字符串
---@param v string|string[]|number|nil
---@return string[]
local function to_lines(v)
    if v == nil then return {} end
    if type(v) == "number" then return { tostring(v) } end
    if type(v) == "string" then
        local lines = vim.split(v:gsub("\r\n", "\n"), "\n", { plain = true })
        -- 末尾的换行会产生一个空行，去掉
        if #lines > 1 and lines[#lines] == "" then table.remove(lines) end
        return lines
    end
    local out = {}
    for _, item in ipairs(v) do
        out[#out + 1] = tostring(item)
    end
    return out
end

---@param side "top"|"bottom"|"left"|"right"
---@return SideBarSlot?
local function slot_of(side)
    -- 兼容旧的两栏左右调用
    if side == "left" then side = "top" elseif side == "right" then side = "bottom" end
    return state[side]
end

---设置某一栏的内容（每栏行数见 geometry，超出的行显示不下）
---@param side "top"|"bottom"|"left"|"right"
---@param lines string|string[]
function M.set_content(side, lines)
    local slot = slot_of(side)
    if not slot then return end
    ensure_buf(slot, side == "left" and "top" or side == "right" and "bottom" or side)
    vim.bo[slot.buf].modifiable = true
    vim.api.nvim_buf_set_lines(slot.buf, 0, -1, false, to_lines(lines))
    vim.bo[slot.buf].modifiable = false
end

---输出到两栏：上栏显示 top，下栏显示 bottom；没打开时会自动打开
---@param top string|string[] 上栏内容，可用 \n 分行
---@param bottom string|string[] 下栏内容，可用 \n 分行
function M.output(top, bottom)
    M.set_content("top", top)
    M.set_content("bottom", bottom)
    if not M.is_open() then
        M.open()
    end
end

------------------------------------------------------------------------
-- 打开 / 关闭
------------------------------------------------------------------------

---打开左侧上下两个 float（宽度 1/4、撑满高度、上下 6:4），不改变当前焦点
function M.open()
    local width, col, top_geo, bottom_geo = geometry()
    ensure_buf(state.top, "top")
    ensure_buf(state.bottom, "bottom")

    if is_open(state.top) and is_open(state.bottom) then
        layout()
        return
    end
    M.close()

    local cur_win = vim.api.nvim_get_current_win()
    open_win(state.top, "side_bar", width, col, top_geo)
    open_win(state.bottom, "side_bar", width, col, bottom_geo)

    -- 焦点还给原来的窗口
    if vim.api.nvim_win_is_valid(cur_win) and vim.api.nvim_get_current_win() ~= cur_win then
        vim.api.nvim_set_current_win(cur_win)
    end
end

function M.close()
    for _, slot in pairs({ state.top, state.bottom }) do
        if is_open(slot) then
            pcall(vim.api.nvim_win_close, slot.win, true)
        end
        slot.win = -1
    end
end

---@return boolean
function M.is_open()
    return is_open(state.top) or is_open(state.bottom)
end

function M.toggle()
    if M.is_open() then
        M.close()
    else
        M.open()
    end
end

------------------------------------------------------------------------
-- setup
------------------------------------------------------------------------

function M.setup(user_opts)
    opts = vim.tbl_deep_extend("force", opts, user_opts or {})

    if state.group then
        pcall(vim.api.nvim_del_augroup_by_id, state.group)
    end
    state.group = vim.api.nvim_create_augroup("SideBar", { clear = true })
    vim.api.nvim_create_autocmd("VimResized", {
        group = state.group,
        callback = function()
            layout()
        end,
    })
    -- 窗口被别的操作关掉时同步状态
    vim.api.nvim_create_autocmd("WinClosed", {
        group = state.group,
        callback = function(ev)
            local w = tonumber(ev.match)
            for _, slot in pairs({ state.top, state.bottom }) do
                if slot.win == w then slot.win = -1 end
            end
        end,
    })

    vim.keymap.set("n", opts.keymap, M.toggle, { desc = "Toggle side bar (2 floats, left 1/4)" })

    -- 示例内容，实际用 M.output / M.set_content 覆盖
    ensure_buf(state.top, "top")
    ensure_buf(state.bottom, "bottom")
    M.set_content("top", { " side_bar top (6)" })
    M.set_content("bottom", { " side_bar bottom (4)" })
end

return M
