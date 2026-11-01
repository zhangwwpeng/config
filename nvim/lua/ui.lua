local M = {}

local ui2 = require("vim._core.ui2")
local msgs = require("vim._core.ui2.messages")
local orig_set_pos = msgs.set_pos

---浮窗透明度：'winblend' 是窗口局部选项，Neovide 拿它当浮动窗口的背景 alpha
---（值来自 init.lua 的 vim.g.float_win_blend，0 = 不透明）
---注意：ui2 用 noautocmd 建这些窗口，init.lua 的 WinNew autocmd 不会触发，只能在这里手动套
local function float_blend()
    return tonumber(vim.g.float_win_blend) or 0
end

---给 ui2 的浮窗设半透明（cmd 是命令行窗口，不算浮层，想一起透明就把 "cmd" 加进来）
local function apply_ui_blend()
    local blend = float_blend()
    for _, kind in ipairs({ "msg", "pager", "dialog" }) do
        local w = ui2.wins[kind]
        if w and vim.api.nvim_win_is_valid(w) then
            vim.wo[w].winblend = blend
        end
    end
end

msgs.set_pos = function(tgt, focus)
    orig_set_pos(tgt, focus)

    -- ui2 会（换 tab / 窗口不再是浮窗时）随手重建这些窗口，所以每次定位都重套一遍
    apply_ui_blend()

    if (tgt == "msg" or tgt == nil) and vim.api.nvim_win_is_valid(ui2.wins.msg) then
        if not vim.api.nvim_win_get_config(ui2.wins.msg).hide then
            pcall(vim.api.nvim_win_set_config, ui2.wins.msg, {
                relative = "editor",
                -- anchor = "SW", -- 锚点是左下角
                -- row = vim.o.lines - 1, -- 行坐标设为屏幕底部（减 2 是为了避开底部的状态栏和命令行）
                -- col = 0,
                anchor = "NW", -- 锚点是左下角
                row = 0, -- 行坐标设为屏幕底部（减 2 是为了避开底部的状态栏和命令行）
                col = 0,
                border = "none",
            })
        end
    end

    if (tgt == "pager" or tgt == nil) and vim.api.nvim_win_is_valid(ui2.wins.pager) then
        pcall(vim.api.nvim_win_set_config, ui2.wins.pager, {
            border = "none",
        })
    end
end

---@param opts? { signs?: table, virtual_lines?: table }
function M.setup(opts)
    opts = opts or {}
    vim.diagnostic.config({
        virtual_text = {
            current_line = true,
            prefix = "",

            format = function(d)
                return "(" .. d.message .. ")"
            end,
        },
        -- ]d / [d 跳转后弹诊断浮窗。
        -- 注意：只认识顶层的 jump，写在 virtual_text.jump 里是无效配置（会被直接忽略，
        -- 所以之前 ]d / [d 看起来“没有浮窗”）。
        -- 用 on_jump 而不是已废弃的 jump.float（0.13 会把 jump.float 当 deprecated 警告）。
        jump = {
            on_jump = function(d, bufnr)
                if not d then
                    return
                end
                vim.diagnostic.open_float({
                    bufnr = bufnr,
                    scope = "cursor",
                    focus = false,
                    border = "rounded",
                    source = "if_many",
                })
            end,
        },
        virtual_lines = false,
        float = { source = "if_many" },
        underline = false,
        update_in_insert = false,
        signs = opts.signs or {
            text = {
                [vim.diagnostic.severity.ERROR] = "x",
                [vim.diagnostic.severity.WARN] = ">",
                [vim.diagnostic.severity.INFO] = "?",
                [vim.diagnostic.severity.HINT] = "?",
            },
        },
    })

    _G.lsp_diagnostics = function()
        local counts = { [1] = 0, [2] = 0, [3] = 0, [4] = 0 }
        for _, d in ipairs(vim.diagnostic.get(0)) do
            counts[d.severity] = (counts[d.severity] or 0) + 1
        end
        if counts[1] + counts[2] == 0 then
            return ""
        end
        return string.format("[x%d][>%d]", counts[1], counts[2])
    end

    ---按 title 找已有的 quickfix 列表，找到就更新（保留当前选择），找不到就新建
    ---@param title string
    ---@return integer? id
    local function qf_id_by_title(title)
        for i = 1, vim.fn.getqflist({ nr = "$" }).nr do
            local qf = vim.fn.getqflist({ nr = i, id = 0, title = 0 })
            if qf.title == title then
                return qf.id
            end
        end
        return nil
    end

    ---把所有 diagnostic 汇总到 quickfix（quickfix.lua 里已有自定义显示：带上下文行）
    ---注：0.13 的 vim.diagnostic.setqflist 不再支持 bufnr 过滤，所以自己 toqflist 后 setqflist
    ---@param bufnr integer? nil = 所有已加载的 buffer
    local function diagnostics_to_qflist(bufnr)
        local diags = vim.diagnostic.get(bufnr)
        local scope = bufnr and "当前 buffer" or "所有 buffer"
        if #diags == 0 then
            vim.notify("没有诊断（" .. scope .. "）", vim.log.levels.INFO)
            return
        end
        local counts = { 0, 0, 0, 0 }
        for _, d in ipairs(diags) do
            counts[d.severity] = (counts[d.severity] or 0) + 1
        end

        -- title 不带数量：这样重复按是在同一个 quickfix 列表上原地更新，不会把 history 刷满
        local title = "Diagnostics · " .. scope
        local prev_win = vim.api.nvim_get_current_win()
        local id = qf_id_by_title(title)

        -- 诊断消息里经常带换行（ruff/pyright 的 help 段），压成一行，quickfix 列表才好看
        local items = vim.diagnostic.toqflist(diags)
        for _, item in ipairs(items) do
            item.text = vim.trim((item.text or ""):gsub("%s*\n+%s*", " "))
        end

        vim.fn.setqflist({}, id and "u" or " ", {
            id = id,
            title = title,
            items = items,
        })
        vim.cmd("botright cwindow")
        -- cwindow 会把光标挪到 quickfix 窗口，退回原来的窗口，继续在代码里干活
        if vim.api.nvim_win_is_valid(prev_win) then
            vim.api.nvim_set_current_win(prev_win)
        end
        vim.notify(
            ("诊断 %d 条（x%d >%d ?%d）→ quickfix"):format(#diags, counts[1], counts[2], counts[3] + counts[4]),
            vim.log.levels.INFO
        )
    end

    -- 所有 buffer 的 diagnostic -> quickfix
    vim.keymap.set("n", "<leader>d", function()
        diagnostics_to_qflist(nil)
    end, { desc = "All diagnostics -> quickfix" })
    -- 当前 buffer 的 diagnostic -> quickfix
    vim.keymap.set("n", "<leader>D", function()
        diagnostics_to_qflist(vim.api.nvim_get_current_buf())
    end, { desc = "Buffer diagnostics -> quickfix" })

    vim.keymap.set("n", "gK", function()
        local vt = vim.diagnostic.config().virtual_text

        vim.diagnostic.config({
            virtual_text = type(vt) == "table" and vt.current_line and {
                prefix = "",
                format = function(d)
                    return "(" .. d.message .. ")"
                end,
            } or {
                prefix = "",
                current_line = true,
                format = function(d)
                    return "(" .. d.message .. ")"
                end,
            },
        })
    end, { desc = "Toggle diagnostic virtual_text current_line" })

    vim.opt.fillchars:append({
        stl = "-",
        stlnc = "-",
    })

    vim.o.statusline = table.concat({
        "%-.80F",
        "%m%r",
        "%{v:lua.lsp_diagnostics()}",
        "%=",
    }, "")

    -- 录制状态通知：用 RecordingEnter / RecordingLeave（按 q 进入/离开录制时触发），
    -- 不要在 statusline 里轮询 —— 那个函数只有 statusline 重绘时才跑，没重绘就永远不通知。
    vim.api.nvim_create_autocmd("RecordingEnter", {
        callback = function()
            vim.notify("recording @" .. vim.fn.reg_recording(), vim.log.levels.INFO)
        end,
        desc = "notify when macro recording starts",
    })
    vim.api.nvim_create_autocmd("RecordingLeave", {
        callback = function()
            vim.notify("recording end @ " .. vim.fn.reg_recording(), vim.log.levels.INFO)
        end,
        desc = "notify when macro recording stops",
    })

    -- Foldtext
    _G.fold_text = function()
        local line = vim.fn.getline(vim.v.foldstart)
        local folded = vim.v.foldend - vim.v.foldstart + 1
        local width = vim.api.nvim_win_get_width(0)
        local suffix = string.format(" >>> %d lines", folded)
        local avail = math.max(10, width - vim.fn.strdisplaywidth(suffix) - 5)
        local disp = vim.fn.strcharpart(line, 0, avail)
        if vim.fn.strdisplaywidth(line) > avail then
            disp = disp .. "\u{2026}"
        end
        return disp .. suffix
    end
    vim.opt.foldtext = "v:lua.fold_text()"

    -- vim.opt.messagesopt = "history:500,maxheight:50,pager:<CR>,timeout:3000,progress:c"
    ui2.enable({
        enable = true, -- Whether to enable or disable the UI.
        msg = { -- Options related to the message module.
            ---@type string|table<string, 'cmd'|'msg'|'pager'> Default message target
            ---or table mapping |ui-messages| kinds, triggers and IDs to a target.
            ---Table keys are matched as a Lua pattern to the message ID. 'default'
            ---mapping applies to any omitted kind: { default = 'cmd', progress = 'msg' }.
            targets = {
                -- default = "cmd",
                progress = "msg",
                bufwrite = "cmd",
                lua_error = "msg",
                lua_print = "msg",
                echo = "msg",
                echomsg = "msg",
            },
            dialog = { -- Options related to dialog window.
                height = 0.5, -- Maximum height.
            },
            msg = { -- Options related to msg window.
                height = 0.5, -- Maximum height.
            },
            pager = { -- Options related to message window.
                height = 0.999, -- Maximum height.
            },
        },
    })

    -- ui2.enable 建出来的窗口先统一下透明度
    apply_ui_blend()

    -- lsp message
    local function should_quiet_lsp_progress(client, title, message)
        -- Drop empty progress events (e.g. pyright #11408).
        if title == "" and message == "" then
            return true
        end

        -- basedpyright/pyright: openFilesOnly re-analyzes the current buffer (1 file) frequently.
        if client.name == "basedpyright" or client.name == "pyright" then
            local text = title .. message
            return text:match("1%s*个%s*文件") ~= nil
                or text:lower():match("analyzing%s+1%s+") ~= nil
                or text:lower():match("%f[%d]1%s+files?%f[%A]") ~= nil
        end

        -- pyrefly: some versions report useless "rechecking ... 0/0" progress on save.
        if client.name == "pyrefly" then
            local text = (title .. " " .. message):lower()
            return text:match("recheck") ~= nil and text:match("0%s*/%s*0") ~= nil
                or text:match("recheck") ~= nil and text:match("1%s*/%s*1") ~= nil
        end

        return false
    end

    local id = { LspProgressMessages = vim.api.nvim_create_augroup("LspProgressMessages", { clear = true }) }
    vim.api.nvim_create_autocmd("LspProgress", {
        group = id.LspProgressMessages,
        callback = function(ev)
            local value = ev.data.params.value
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if not client then
                return
            end

            -- basedpyright/pyright spam empty $/progress on every keystroke (pyright #11408)
            local title = value.title or ""
            local message = value.message or ""
            if should_quiet_lsp_progress(client, title, message) then
                return
            end

            local is_end = value.kind == "end"
            local msg = message ~= "" and (client.name .. ": " .. message)
                or (client.name .. (is_end and ": done" or ""))
            vim.api.nvim_echo({ { msg } }, false, {
                id = "lsp." .. ev.data.client_id,
                kind = "progress",
                source = "vim.lsp",
                title = title,
                status = is_end and "success" or "running",
                percent = value.percentage,
            })
        end,
    })
end

return M
