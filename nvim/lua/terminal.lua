local flt_win = -1
local sub_win = -1
local layout_status = 0
local term_height = 15
local term_width = 50

local flt_spawned = false
local sub_spawned = false

local function spawn_flt()
  if flt_spawned then
    return
  end
  flt_spawned = true
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = 0,
    col = 0,
    width = 100,
    height = 100,
    style = "minimal",
    focusable = false,
  })
  vim.api.nvim_set_current_win(win)
  vim.cmd.terminal(
    "nvim -u ~/.config/nvim/init_flt_term.lua --listen "
      .. vim.g.flt_term_servrename
      .. " --cmd \"lua vim.g.pip_father = '"
      .. vim.v.servername
      .. "'\""
  )
  Remote_flt_term_buf = vim.api.nvim_get_current_buf()
  vim.bo[Remote_flt_term_buf].bufhidden = "hide"
  vim.api.nvim_win_hide(win)
end

local function spawn_sub()
  if sub_spawned then
    return
  end
  sub_spawned = true
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = 0,
    col = 0,
    width = 100,
    height = 100,
    style = "minimal",
    focusable = false,
  })
  vim.api.nvim_set_current_win(win)
  vim.cmd.terminal(
    "nvim -u ~/.config/nvim/init_sub_term.lua --listen "
      .. vim.g.sub_term_servrename
      .. " --cmd \"lua vim.g.pip_father = '"
      .. vim.v.servername
      .. "'\""
  )
  Remote_sub_term_buf = vim.api.nvim_get_current_buf()
  vim.bo[Remote_sub_term_buf].bufhidden = "hide"
  vim.api.nvim_win_hide(win)
end

local function create_flt_term_window(opts)
    local width = opts.width or math.floor(vim.o.columns * 0.9)
    local height = opts.height or math.floor(vim.o.lines * 0.9)

    -- Calculate the position to center the window
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2) - 1

    -- Create a buffer

    -- Define window configuration
    local win_config = {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = "rounded",
    }

    local win = vim.api.nvim_open_win(opts.buf, true, win_config)

    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn = "no"
    vim.wo.list = false

    return win
end

local function create_sub_term_window(opts)
    local layout
    -- "float" "left", "right", "above", "below"
    if opts.layout == 0 then
        layout = "below"
    elseif opts.layout == 1 then
        layout = "left"
    elseif opts.layout == 2 then
        layout = "above"
    elseif opts.layout == 3 then
        layout = "right"
    end
    local win_config = {
        win = -1,
        split = layout,
        height = term_height,
        width = term_width,
    }

    local win = vim.api.nvim_open_win(opts.buf, true, win_config)

    vim.wo.number = false
    vim.wo.signcolumn = "no"
    vim.wo.list = false

    return win
end

local recoard_terminal = function()
    term_width = vim.api.nvim_win_get_width(sub_win)
    term_height = vim.api.nvim_win_get_height(sub_win)
end


local toggle_float_terminal = function()
    spawn_flt()
    if not vim.api.nvim_win_is_valid(flt_win) then
        flt_win = create_flt_term_window({ buf = Remote_flt_term_buf })
        vim.api.nvim_set_option_value("buflisted", false, { buf = Remote_flt_term_buf })
        vim.cmd("startinsert")
    else
        vim.api.nvim_win_hide(flt_win)
    end
end

local toggle_sub_terminal = function(opts)
    spawn_sub()
    opts = opts or {}
    if opts.cycle then
        layout_status = (layout_status + 1) % 4
    end
    local cur_win = vim.api.nvim_get_current_win()
    local cur_buf = vim.api.nvim_win_get_buf(cur_win)
    if not vim.api.nvim_win_is_valid(sub_win) then
        sub_win = create_sub_term_window({ buf = Remote_sub_term_buf, layout = layout_status })
        vim.api.nvim_set_option_value("buflisted", false, { buf = Remote_sub_term_buf })
        vim.cmd("startinsert")
    elseif cur_buf ~= Remote_sub_term_buf then
        vim.api.nvim_set_current_win(sub_win)
        vim.cmd("startinsert")
    else
        if layout_status == 0 then
            vim.cmd("wincmd k")
        elseif layout_status == 1 then
            vim.cmd("wincmd l")
        elseif layout_status == 2 then
            vim.cmd("wincmd j")
        elseif layout_status == 3 then
            vim.cmd("wincmd h")
        end
    end
end

------------------------------------------------------------------------
-- RPC Receiver command
------------------------------------------------------------------------

vim.api.nvim_create_user_command("CycleTerm", function()
    vim.api.nvim_win_hide(sub_win)
    toggle_sub_terminal({ cycle = 1 })
end, { nargs = 0 })

------------------------------------------------------------------------
-- RPC — 向子 nvim 实例发送命令
------------------------------------------------------------------------
-- vim.g.sub_term_servrename = vim.v.servername .. "_sub"

local function send_to_sub_nvim(cmd)
    vim.rpcnotify(Sub_term_chan, "nvim_command", cmd)
end

vim.t.term_last_ai = nil -- "claude" or "open_code"
--- 将 visual 选区（文件路径 + 行号）发送到子实例的 ai_cc tab
local function send_visual_to_ai()
    local filepath = vim.fn.expand("%:.")
    local start_pos = vim.fn.getpos("v")
    local end_pos = vim.fn.getpos(".")

    local start_line = math.min(start_pos[2], end_pos[2])
    local end_line = math.max(start_pos[2], end_pos[2])
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
    local text
    if start_line == end_line then
        text = "@" .. filepath .. " "
    else
        text = "@" .. filepath .. ":" .. start_line .. "-" .. end_line .. " "
    end
    send_to_sub_nvim("lua _G.send_to_tab_terminal('" .. vim.t.term_last_ai .. "','" .. text .. "')")
end

------------------------------------------------------------------------
-- Keypam
------------------------------------------------------------------------
vim.keymap.set("n", "<leader>t", function()
    if vim.api.nvim_win_is_valid(sub_win) then
        recoard_terminal()
        vim.api.nvim_win_hide(sub_win)
    else
        toggle_sub_terminal()
    end
end, { desc = "hide sub win" })

-- visual 模式下发送选区到 ai_cc
-- vim.keymap.set("v", "<C-t>", function()
--     send_visual_to_ai()
--     require("imselect").switch("zh")
-- end, { desc = "Send selection to ai_cc" })

vim.keymap.set({ "n", "t", "i" }, "<C-t>", function()
    toggle_float_terminal()
    require("imselect").to_en()
end, { desc = "Toggle float terminal" })

vim.keymap.set({ "n", "t", "i" }, "<C-,>", function()
    toggle_sub_terminal()
    require("imselect").to_en()
end, { desc = "Toggle float terminal" })
