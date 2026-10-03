local M = {}

local ui2 = require("vim._core.ui2")
local msgs = require("vim._core.ui2.messages")
local orig_set_pos = msgs.set_pos

msgs.set_pos = function(tgt, focus)
    orig_set_pos(tgt, focus)

    if (tgt == "msg" or tgt == nil) and vim.api.nvim_win_is_valid(ui2.wins.msg) then
        if not vim.api.nvim_win_get_config(ui2.wins.msg).hide then
            pcall(vim.api.nvim_win_set_config, ui2.wins.msg, {
                relative = "editor",
                anchor = "SW", -- 锚点是左下角
                row = vim.o.lines - 1, -- 行坐标设为屏幕底部（减 2 是为了避开底部的状态栏和命令行）
                col = 0,
                border = "rounded",
            })
        end
    end

    if (tgt == "pager" or tgt == nil) and vim.api.nvim_win_is_valid(ui2.wins.pager) then
        pcall(vim.api.nvim_win_set_config, ui2.wins.pager, {
            border = "rounded",
        })
    end
end

---@param opts? { signs?: table, virtual_lines?: table }
function M.setup(opts)
    opts = opts or {}
    vim.diagnostic.config({
        virtual_text = { source = "if_many" },
        virtual_lines = { current_line = true },
        float = { source = "if_many" },
        underline = false,
        update_in_insert = false,
        signs = opts.signs or {
            text = {
                [vim.diagnostic.severity.ERROR] = "\u{EA87}",
                [vim.diagnostic.severity.WARN] = "\u{EA6C}",
                [vim.diagnostic.severity.INFO] = "\u{EA74}",
                [vim.diagnostic.severity.HINT] = "\u{EC10} ",
            },
        },
    })

    _G.lsp_diagnostics = function()
        local counts = { [1] = 0, [2] = 0, [3] = 0, [4] = 0 }
        for _, d in ipairs(vim.diagnostic.get(0)) do
            counts[d.severity] = (counts[d.severity] or 0) + 1
        end
        if counts[1] + counts[2] + counts[3] + counts[4] == 0 then
            return ""
        end
        return string.format(
            " \u{EA87} %d \u{EA6C} %d \u{EA74} %d \u{EC10} %d ",
            counts[1],
            counts[2],
            counts[3],
            counts[4]
        )
    end

    vim.o.statusline = table.concat({
        "%-.80F",
        "%m%r",
        "%=",
        "%{v:lua.current_macro_status()}", -- 展示宏录制
        "%{v:lua.lsp_diagnostics()}",
        "%y %l,%c",
    }, "")

    local reg_status = false
    function _G.current_macro_status()
        local reg = vim.fn.reg_recording()
        if reg ~= "" then
            if reg_status == false then
                vim.notify("recoarding " .. reg)
            end
            reg_status = true
            return "recording @" .. reg .. " "
        else
            if reg_status == true then
                vim.notify("end recoarding")
            end
            reg_status = false
            return ""
        end
    end

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
