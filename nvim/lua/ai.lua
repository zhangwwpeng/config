local M = {}

function M.setup()
    require("minuet").setup({
        cmp = {
            enable_auto_complete = false,
        },
        blink = {
            enable_auto_complete = false,
        },
        virtualtext = {
            -- Specify the filetypes to enable automatic virtual text completion,
            -- e.g., { 'python', 'lua' }. Note that you can still invoke manual
            -- completion even if the filetype is not on your auto_trigger_ft list.
            auto_trigger_ft = {},
            -- specify file types where automatic virtual text completion should be
            -- disabled. This option is useful when auto-completion is enabled for
            -- all file types i.e., when auto_trigger_ft = { '*' }
            auto_trigger_ignore_ft = {},
            keymap = {
                -- accept = "<c-y>",
                -- accept_line = "<A-l>",
                -- accept_n_lines = "<A-n>",
                -- next / prev 交给下面自己的映射：按下去时顺便让 cursortab 让路 5s
                next = false, -- 手动触发 / 下一个建议
                prev = false, -- 上一个建议 / 手动触发
                dismiss = false,
            },
            -- Whether show virtual text suggestion when the completion menu
            -- (nvim-cmp or blink-cmp) is visible.
            show_on_completion_menu = false,
        },
        provider = "openai_fim_compatible",
        context_window = 20000,
        context_ratio = 0.5,
        provider_options = {
            openai_fim_compatible = {
                -- deepseek
                api_key = "DEEPSEEK_API_KEY",
                name = "deepseek",
                optional = {
                    max_tokens = 256,
                    top_p = 0.9,
                },
                -- model = "mercury-coder",
                -- end_point = "https://api.inceptionlabs.ai/v1/fim/completions",
                -- api_key = "MERCURY_AI_TOKEN", -- environment variable name
                -- stream = true,

                -- template = {
                -- prompt = function(context_before_cursor, context_after_cursor, opts)
                --     -- vim.notify(context_after_cursor)
                --     print(context_before_cursor)
                --     return context_after_cursor
                -- end,
                -- suffix = function(context_before_cursor, context_after_cursor, opts) end,
                -- },
            },
        },
    })
    require("cursortab").setup({
        keymaps = {
            accept = "<Tab>", -- Keymap to accept completion, or false to disable
            partial_accept = false, -- Keymap to partially accept, or false to disable
            trigger = false, -- Keymap to manually trigger completion, or false to disable
        },
        ui = {
            completions = {
                addition_style = "highlight",
                fg_opacity = 1,
            },
        },
        provider = {
            type = "mercuryapi",
            api_key_env = "MERCURY_AI_TOKEN",
            completion_timeout = 100000,
        },
        behavior = {
            -- 只在 normal 模式出建议（默认是 { "insert", "normal" }）。
            -- 这个字段是启动时通过 CURSORTAB_CONFIG 交给 Go daemon 的
            -- （daemon.lua:120-121 映射成 complete_in_insert / complete_in_normal），
            -- 改完生效方式：:CursortabRestart（或重启 nvim）。
            enabled_modes = { "normal" },
            ignore_filetypes = { "refer_input" },
        },
    })
    -- cursortab 没有按 buffer 的开关，只能包一层 should_skip()（daemon / events 每次都通过模块表调用它）
    local ct_buffer = require("cursortab.buffer")
    local ct_should_skip = ct_buffer.should_skip
    ct_buffer.should_skip = function()
        return vim.b.bigfile ~= nil or ct_should_skip()
    end

    require("copilot").setup({
        -- 大文件 / 特殊 filetype 不挂 copilot（见 bigfile.lua），其余走插件默认判断
        should_attach = function(buf, name)
            if vim.b[buf].bigfile then
                return false
            end
            return require("copilot.config.should_attach").default(buf, name)
        end,
        panel = {
            enabled = false,
        },
        suggestion = {
            enabled = true,
            auto_trigger = true, -- 默认 false：不设就是“只有手动 <M-]> 才会出建议”
        },
    })

    -- Copilot（copilot.lua）的动作表：is_visible / accept / next / prev / dismiss
    -- （copilot.lua/lua/copilot/suggestion/init.lua:778 / 633 / 598 / 615）
    local cp_ok, copilot_suggestion = pcall(require, "copilot.suggestion")
    local cp = cp_ok and copilot_suggestion or nil

    -- minuet 的动作表：is_visible / accept / next / prev / dismiss
    -- （minuet-ai.nvim/lua/minuet/virtualtext.lua:426 M.action = action）
    local vt_ok, vt = pcall(require, "minuet.virtualtext")
    local vt_action = vt_ok and vt and vt.action or nil

    -- 前置声明：<C-f> 在下面才用到 minuet_mode_off，而它是后面才定义的 local
    local minuet_mode_off

    -- <C-f>：谁有 ghost text 就接受谁（copilot 优先，其次 minuet），都没有就退回 <Right>。
    -- 接受 minuet 之后立刻退出 minuet 模式（清预览 + 恢复 copilot 的自动触发），
    -- 这样接着打字就又是 copilot 的 ghost text 了。
    vim.keymap.set("i", "<c-f>", function()
        if cp and cp.is_visible() then
            cp.accept()
            return
        end
        if vt_action and vt_action.is_visible() then
            vt_action.accept()
            -- accept() 里的 nvim_buf_set_text 是 vim.schedule 的，dismiss 不会影响这次插入
            if minuet_mode_off then
                minuet_mode_off()
            end
            return
        end
        vim.api.nvim_feedkeys(vim.keycode("<Right>"), "n", false)
    end, { desc = "[ai] accept visible (copilot/minuet), else <Right>", silent = true })

    -- ── C-n / C-p 切到 minuet；打字 / 进 normal 切回 copilot ──
    -- 两边都靠 buffer 变量开关：
    --   minuet : vim.b.minuet_virtual_text_auto_trigger   (minuet/virtualtext.lua:25-27)
    --   copilot: vim.b.copilot_suggestion_auto_trigger    (copilot/suggestion/init.lua:45-50，
    --            nil = 跟随全局 config.suggestion.auto_trigger)
    local saved_copilot_auto = {} ---@type table<integer, { value: boolean? }>

    local function is_minuet_mode()
        return vim.b.minuet_virtual_text_auto_trigger == true
    end

    local function minuet_mode_on()
        if vt_action then
            vim.b.minuet_virtual_text_auto_trigger = true
        end
        if cp then
            local buf = vim.api.nvim_get_current_buf()
            -- 记住原来的值再改，避免把你手动 :Copilot suggestion toggle_auto_trigger 的结果冲掉
            saved_copilot_auto[buf] = { value = vim.b.copilot_suggestion_auto_trigger }
            vim.b.copilot_suggestion_auto_trigger = false
            cp.dismiss() -- 清掉 copilot 已画出的 ghost text
        end
    end

    function minuet_mode_off()
        if vt_action then
            vim.b.minuet_virtual_text_auto_trigger = false
            if vt_action.is_visible() then
                vt_action.dismiss()
            end
        end
        if cp then
            local buf = vim.api.nvim_get_current_buf()
            local saved = saved_copilot_auto[buf]
            saved_copilot_auto[buf] = nil
            vim.b.copilot_suggestion_auto_trigger = saved and saved.value or nil
        end
    end

    -- <C-n> = next，<C-p> = prev；两者行为一致：关掉 copilot 的 ghost text，
    -- 然后（必要时）触发一次 minuet 请求 / 在 minuet 候选间循环。
    -- 区别只在方向，和 vim 自身的 C-n/C-p 习惯一致。
    local function minuet_cycle(dir)
        if vim.b.bigfile then
            return -- 大文件 / 特殊 filetype 不请求 minuet（见 bigfile.lua）
        end
        minuet_mode_on()
        if not vt_action then
            return
        end
        if dir > 0 then
            vt_action.next() -- 没有建议时它会自己发一次请求
        else
            vt_action.prev()
        end
    end

    vim.keymap.set("i", "<c-n>", function()
        minuet_cycle(1)
    end, { desc = "[minuet] next suggestion (copilot off)", silent = true })
    vim.keymap.set("i", "<c-p>", function()
        minuet_cycle(-1)
    end, { desc = "[minuet] prev suggestion (copilot off)", silent = true })

    local switch_group = vim.api.nvim_create_augroup("AiCompletionSwitch", { clear = true })
    -- 注意：下面两个回调都先读一个 buffer 变量就返回，不在 minuet 模式时几乎零开销
    vim.api.nvim_create_autocmd("InsertCharPre", {
        group = switch_group,
        callback = function()
            if is_minuet_mode() then
                minuet_mode_off()
            end
        end,
        desc = "[ai] typing switches back to copilot",
    })
    vim.api.nvim_create_autocmd("ModeChanged", {
        group = switch_group,
        pattern = "*:n",
        callback = function()
            if is_minuet_mode() then
                minuet_mode_off()
            end
        end,
        desc = "[ai] normal mode switches back to copilot",
    })
    -- minuet 请求是异步的：切回 copilot 后迟到的响应可能还会画出 ghost text。
    -- 只有真的画出来了才 dismiss（is_visible() ≈ 0.2µs），否则纯读一次 extmark 就返回。
    vim.api.nvim_create_autocmd("TextChangedI", {
        group = switch_group,
        callback = function()
            if vt_action and vt_action.is_visible() then
                vt_action.dismiss()
            end
        end,
        desc = "[ai] drop stale minuet preview",
    })
end

return M
