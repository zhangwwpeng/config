local palette = {
    bg = "#232922",
    -- bg = "#282828",
    bg_alt = "#32302f",
    bg_light1 = "#484848",
    bg_light2 = "#666666",
    bg_light3 = "#aaaaaa",
    fg = "#bdaa86",
    fg_dim = "#928374",
    fg_light1 = "#eb8f3b",
    white = "#ffffff",
    black = "#000000",
    blue = "#9d7cd8",
    blue_light1 = "#9bbcb5",
    green = "#6A9955",
    green_light1 = "#8fb573",
    red = "#e75a7c",
    orange = "#f0945d",
    purple = "#e49cb1",
    yellow = "#e2c792",
    gray = "#838781",
    gray_light1 = "#928374",
}

local function base(pal)
    return {
        Normal = { fg = pal.bg_light3, bg = pal.bg },
        NormalNC = { link = "Normal" },
        NormalFloat = { link = "Normal" },
        Terminal = { fg = pal.bg_light3, bg = "NONE" },
        EndOfBuffer = { link = "Normal" },
        Folded = { bg = pal.gray_light1, fg = pal.black },
        SignColumn = { bg = pal.bg, fg = pal.gray },
        CursorLine = { fg = nil, bg = pal.bg_light1 },
        Cursor = { fg = pal.bg, bg = pal.white },
        Visual = { bg = pal.bg_light2 },
        lCursor = { link = "Cursor" },
        CursorIM = { link = "Cursor" },
        CursorColumn = { link = "CursorLine" },
        ColorColumn = { link = "CursorLine" },
        VisualNOS = { link = "CursorLine" },
        LineNr = { fg = pal.gray },
        CursorLineNr = { link = "LineNr" },
        StatusLine = { fg = pal.gray, bg = pal.bg },
        StatusLineNC = { link = "StatusLine" },
        StatusLineTerm = { link = "StatusLine" },
        StatusLineTermNC = { link = "StatusLine" },
    }
end

local function syntax(pal)
    return {
        Comment = { fg = pal.fg_dim },
        Function = { fg = pal.blue },
        String = { fg = pal.green },
        PreProc = { fg = pal.purple },
        Constant = { fg = pal.orange },
        Delimiter = { fg = pal.gray },
        Operator = { fg = pal.gray },
    }
end

local function treesitter(pal)
    return {
        ["@variable"] = { fg = pal.fg },
        ["@variable.member"] = { fg = pal.fg },
        ["@keyword"] = { fg = pal.bg_light3 },
        ["@keyword.function"] = { fg = pal.bg_light3 },
        ["@keyword.return"] = { fg = pal.bg_light3 },
        ["@function.call"] = { fg = pal.blue },
        ["@function.builtin"] = { fg = pal.blue },
        ["@constructor"] = { link = "Delimiter" },
        ["@module.builtin"] = { fg = pal.fg },
        ["@property"] = { fg = pal.bg_light3 },
    }
end

local function diagnostics(pal)
    return {
        DiagnosticError = { fg = pal.red },
        DiagnosticWarn = { fg = pal.orange },
        DiagnosticInfo = { fg = pal.blue_light1 },
        DiagnosticHint = { fg = pal.bg_light3 },
        DiagnosticVirtualTextError = { fg = pal.red },
        DiagnosticVirtualTextWarn = { fg = pal.orange },
        DiagnosticVirtualTextInfo = { fg = pal.blue_light1 },
        DiagnosticVirtualTextHint = { fg = pal.bg_light3 },
        DiagnosticSignError = { fg = pal.red },
        DiagnosticSignWarn = { fg = pal.orange },
        DiagnosticSignInfo = { fg = pal.blue_light1 },
        DiagnosticSignHint = { fg = pal.bg_light3 },
    }
end

---Boost saturation of a hex color. amount 0 = no change, 1 = fully saturated.
local function saturate_hex(hex, amount)
    if amount == 0 or not hex or #hex ~= 7 then
        return hex
    end
    local rr = tonumber(hex:sub(2, 3), 16) / 255
    local gg = tonumber(hex:sub(4, 5), 16) / 255
    local bb = tonumber(hex:sub(6, 7), 16) / 255
    if not rr or not gg or not bb then
        return hex
    end
    local cmax = math.max(rr, gg, bb)
    local cmin = math.min(rr, gg, bb)
    local l = (cmax + cmin) / 2
    if cmax == cmin then
        return hex -- gray, no saturation to boost
    end
    local d = cmax - cmin
    local s = l > 0.5 and d / (2 - cmax - cmin) or d / (cmax + cmin)
    s = math.min(1, s + amount * (1 - s))
    if s == 0 then
        return hex
    end
    local h
    if cmax == rr then
        h = ((gg - bb) / d) % 6
    elseif cmax == gg then
        h = (bb - rr) / d + 2
    else
        h = (rr - gg) / d + 4
    end
    h = h / 6
    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q
    local function to_rgb(t)
        if t < 0 then
            t = t + 1
        end
        if t > 1 then
            t = t - 1
        end
        if t < 1 / 6 then
            return p + (q - p) * 6 * t
        end
        if t < 1 / 2 then
            return q
        end
        if t < 2 / 3 then
            return p + (q - p) * (2 / 3 - t) * 6
        end
        return p
    end
    local nr = math.floor(to_rgb(h + 1 / 3) * 255 + 0.5)
    local ng = math.floor(to_rgb(h) * 255 + 0.5)
    local nb = math.floor(to_rgb(h - 1 / 3) * 255 + 0.5)
    return string.format("#%02X%02X%02X", nr, ng, nb)
end

local M = {}

M.colors = palette
M.saturation = 0

-- Catppuccin Mocha terminal palette
local terminal_colors = {
  "#45475a", -- 0  black
  "#f38ba8", -- 1  red
  "#a6e3a1", -- 2  green
  "#f9e2af", -- 3  yellow
  "#89b4fa", -- 4  blue
  "#f5c2e7", -- 5  purple
  "#94e2d5", -- 6  cyan
  "#bac2de", -- 7  white
  "#585b70", -- 8  bright black
  "#f38ba8", -- 9  bright red
  "#a6e3a1", -- 10 bright green
  "#f9e2af", -- 11 bright yellow
  "#89b4fa", -- 12 bright blue
  "#f5c2e7", -- 13 bright purple
  "#94e2d5", -- 14 bright cyan
  "#cdd6f4", -- 15 bright white
}

function M.load()
  local pal = palette
  local amt = M.saturation
  for i = 0, 15 do
    vim.g["terminal_color_" .. i] = terminal_colors[i + 1]
  end
  local hl = vim.tbl_deep_extend("force", base(pal), syntax(pal), treesitter(pal), diagnostics(pal))
  for group_name, group_settings in pairs(hl) do
    if group_settings.link then
    elseif amt > 0 and group_settings.fg then
      group_settings.fg = saturate_hex(group_settings.fg, amt)
    end
    vim.api.nvim_set_hl(0, group_name, group_settings)
  end
end

---Increase foreground color saturation. 0 = default, 1 = fully saturated.
---Background colors are preserved.
---@param amount number 0–1
function M.saturate(amount)
    M.saturation = math.min(1, math.max(0, amount))
    M.load()
end

return M
