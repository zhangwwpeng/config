local state = {
    term = {
        layout = "split",
        buf = -1,
        win = -1,
    },
}

-- "float" "left", "right", "above", "below"
vim.t.term_tab_layout = "float"
vim.t.term_height = 15
vim.t.term_width = 50
vim.t.term_keep = false
vim.t.term_last_ai = nil -- "claude" or "open_code"

local layouts = { "float", "below", "left", "right", "above" }

local function cycle_layout()
    local cur = vim.t.term_tab_layout or "float"
    local idx = 1
    for i, v in ipairs(layouts) do
        if v == cur then
            idx = i
            break
        end
    end
    local next_layout = layouts[(idx % #layouts) + 1]
    vim.t.term_tab_layout = next_layout
    vim.notify("term layout =" .. next_layout)
end

local function create_term_window(opts)
    opts = opts or {}
    local width = opts.width or math.floor(vim.o.columns * 0.9)
    local height = opts.height or math.floor(vim.o.lines * 0.9)

    -- Calculate the position to center the window
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2) - 1

    -- Create a buffer
    local buf = nil
    if vim.api.nvim_buf_is_valid(opts.buf) then
        buf = opts.buf
    else
        buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
    end

    -- Define window configuration
    local win_config
    if opts.layout == "float" then
        win_config = {
            relative = "editor",
            width = width,
            height = height,
            col = col,
            row = row,
            style = "minimal",
            border = "rounded",
        }
    else
        win_config = {
            win = -1,
            split = opts.layout,
            height = vim.t.term_height,
            width = vim.t.term_width,
        }
    end

    local win = vim.api.nvim_open_win(buf, true, win_config)

    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn = "no"
    vim.wo.list = false

    return { buf = buf, win = win }
end

local toggle_terminal = function(opts)
    opts = opts or {}
    local cur_win = vim.api.nvim_get_current_win()
    local cur_buf = vim.api.nvim_win_get_buf(cur_win)
    if opts.layout then
        vim.t.term_tab_layout = opts.layout
    end
    local layout = vim.t.term_tab_layout
    -- layout 变化：先隐藏重建
    if opts.layout and vim.api.nvim_win_is_valid(state.term.win) and state.term.layout ~= opts.layout then
        vim.api.nvim_win_hide(state.term.win)
    end
    if not vim.api.nvim_win_is_valid(state.term.win) then
        state.term.layout = layout
        state.term = create_term_window({ buf = state.term.buf, layout = layout })
        if vim.bo[state.term.buf].buftype ~= "terminal" then
            vim.cmd.terminal(
                "nvim -u ~/.config/nvim/init_term.lua --listen "
                    .. vim.g.sub_term_servrename
                    .. " --cmd \"lua vim.g.pip_father = '"
                    .. vim.v.servername
                    .. "'\""
            )
        end
        -- unlist the terminal from buffer list
        vim.api.nvim_set_option_value("buflisted", false, { buf = state.term.buf })
        vim.cmd("startinsert")
    elseif cur_buf ~= state.term.buf then
        vim.api.nvim_set_current_win(state.term.win)
        vim.cmd("startinsert")
    else
        -- 先记录 size（keep 和 hide 都需要记）
        local cur_layout = state.term.layout or layout
        if cur_layout == "above" or cur_layout == "below" then
            vim.t.term_height = vim.api.nvim_win_get_height(state.term.win)
        elseif cur_layout == "left" or cur_layout == "right" then
            vim.t.term_width = vim.api.nvim_win_get_width(state.term.win)
        end
        if vim.t.term_keep and vim.t.term_tab_layout == "below" then
            vim.cmd("wincmd k")
        elseif vim.t.term_keep and vim.t.term_tab_layout == "above" then
            vim.cmd("wincmd j")
        elseif vim.t.term_keep and vim.t.term_tab_layout == "right" then
            vim.cmd("wincmd h")
        elseif vim.t.term_keep and vim.t.term_tab_layout == "left" then
            vim.cmd("wincmd l")
        else
            vim.api.nvim_win_hide(state.term.win)
        end
    end
end

-- vim.keymap.set("n", "<leader>tt", function()
--     cycle_layout()
-- end, { desc = "cycle terminal layout" })

vim.keymap.set("n", "<leader>tk", function()
    if vim.t.term_keep then
        vim.notify("terminal will be hidden", vim.log.levels.INFO)
        vim.t.term_keep = false
    else
        vim.notify("terminal will be fix", vim.log.levels.INFO)
        vim.t.term_keep = true
    end
end, { desc = "keep term when use C-t" })

local function term_remote_callback(argument)
    if vim.t.term_tab_layout == "below" then
        vim.cmd("wincmd k")
    else
        if state.term.layout == "above" or state.term.layout == "below" then
            vim.t.term_height = vim.api.nvim_win_get_height(state.term.win)
        elseif state.term.layout == "left" or state.term.layout == "right" then
            vim.t.term_width = vim.api.nvim_win_get_width(state.term.win)
        end
        vim.api.nvim_win_hide(state.term.win)
    end

    if argument == "null" then
        return
    else
        vim.api.nvim_command("edit " .. argument)
        vim.notify("收到远程控制！参数是: " .. argument, vim.log.levels.INFO)
    end
end

------------------------------------------------------------------------
-- RPC Receiver command
------------------------------------------------------------------------

vim.api.nvim_create_user_command("RemoteTrigger", function(opts)
    term_remote_callback(opts.args)
end, { nargs = 1 })

vim.api.nvim_create_user_command("RemoteCycleTerm", function()
    vim.api.nvim_win_hide(state.term.win)
    cycle_layout()
    toggle_terminal()
end, { nargs = 0 })

------------------------------------------------------------------------
-- RPC — 向子 nvim 实例发送命令
------------------------------------------------------------------------
vim.g.sub_term_servrename = vim.v.servername .. "_sub"

local function send_to_sub_nvim(cmd)
    local addr = vim.g.sub_term_servrename
    if not addr or addr == "" then
        vim.notify("sub_term_servrename not set", vim.log.levels.ERROR)
        return
    end
    local chan = vim.fn.sockconnect("pipe", addr, { rpc = true })
    if chan <= 0 then
        vim.notify("failed to connect to sub-nvim RPC", vim.log.levels.ERROR)
        return
    end
    vim.rpcnotify(chan, "nvim_command", cmd)
    vim.fn.chanclose(chan)
end

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

-- 导航到子 nvim 指定 tab（强制 float 布局）
vim.keymap.set("n", "<leader>tg", function()
    toggle_terminal({ layout = "float" })
    send_to_sub_nvim("lua _G.goto_or_create_tab('lazygit','lazygit')")
end, { desc = "Open lazygit tab" })

vim.keymap.set("n", "<leader>ty", function()
    toggle_terminal({ layout = "above" })
    send_to_sub_nvim("lua _G.goto_or_create_tab('yazi','yazi')")
end, { desc = "Open yazi tab" })

vim.keymap.set("n", "<leader>tt", function()
    toggle_terminal({ layout = "float" })
    vim.t.term_last_ai = "claude"
    send_to_sub_nvim("lua _G.goto_or_create_tab('claude')")
end, { desc = "Open claude tab" })

vim.keymap.set("n", "<leader>to", function()
    toggle_terminal({ layout = "left" })
    vim.t.term_last_ai = "open_code"
    send_to_sub_nvim("lua _G.goto_or_create_tab('open_code')")
end, { desc = "Open openc code tab" })

vim.keymap.set("n", "<leader>tb", function()
    toggle_terminal({ layout = "below" })
    send_to_sub_nvim("lua _G.goto_or_create_tab('bash')")
end, { desc = "Open bash tab" })

vim.keymap.set({ "n", "t", "i" }, "<C-t>", function()
    toggle_terminal()
    require("imselect").to_en()
end, { desc = "Toggle terminal" })

-- visual 模式下发送选区到 ai_cc
vim.keymap.set("v", "<C-t>", function()
    send_visual_to_ai()
    require("imselect").switch("zh")
    toggle_terminal()
end, { desc = "Send selection to ai_cc" })
