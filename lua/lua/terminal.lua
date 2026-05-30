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

    if opts.layout ~= "float" then
        vim.wo.statusline = "%=terminal"
    end

    return { buf = buf, win = win }
end

local toggle_terminal = function(opts)
    local cur_win = vim.api.nvim_get_current_win()
    local cur_buf = vim.api.nvim_win_get_buf(cur_win)
    if not vim.api.nvim_win_is_valid(state.term.win) then
        state.term.layout = vim.t.term_tab_layout or "float"
        state.term = create_term_window({ buf = state.term.buf, layout = state.term.layout })
        if vim.bo[state.term.buf].buftype ~= "terminal" then
            vim.cmd.terminal(
                "nvim -u ~/.config/nvim/init_term.lua --cmd \"lua vim.g.pip_father = '" .. vim.v.servername .. "'\""
            )
        end
        -- unlist the terminal from buffer list
        vim.api.nvim_set_option_value("buflisted", false, { buf = state.term.buf })
        vim.cmd("startinsert")
    elseif cur_buf ~= state.term.buf then
        vim.api.nvim_set_current_win(state.term.win)
        vim.cmd("startinsert")
    else
        if vim.t.term_keep and vim.t.term_tab_layout == "below" then
            vim.cmd("wincmd k")
        else
            if vim.t.term_tab_layout ~= "float" then
                vim.t.term_width = vim.api.nvim_win_get_width(state.term.win)
                vim.t.term_height = vim.api.nvim_win_get_height(state.term.win)
            end
            vim.api.nvim_win_hide(state.term.win)
        end
    end
end

vim.keymap.set({ "n", "t", "i" }, "<C-t>", toggle_terminal, { desc = "Toggle terminal" })

-- vim.keymap.set("n", "<leader>tt", function()
--     cycle_layout()
-- end, { desc = "cycle terminal layout" })

vim.keymap.set("n", "<leader>tk", function()
    vim.t.term_keep = not vim.t.term_keep
    if vim.t.term_keep then
        vim.notify("terminal will be keep", vim.log.levels.INFO)
    else
        vim.notify("terminal will be hidden", vim.log.levels.INFO)
    end
end, { desc = "keep term when use C-t" })

local function term_remote_callback(argument)
    if vim.t.term_tab_layout == "below" then
        vim.cmd("wincmd k")
    else
        if vim.t.term_tab_layout ~= "float" then
            vim.t.term_width = vim.api.nvim_win_get_width(state.term.win)
            vim.t.term_height = vim.api.nvim_win_get_height(state.term.win)
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

vim.api.nvim_create_user_command("RemoteTrigger", function(opts)
    term_remote_callback(opts.args)
end, { nargs = 1 })

vim.api.nvim_create_user_command("RemoteCycleTerm", function()
    vim.api.nvim_win_hide(state.term.win)
    cycle_layout()
    toggle_terminal()
end, { nargs = 0 })
