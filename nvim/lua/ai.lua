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
                accept = "<c-y>",
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
            ignore_filetypes = { "refer_input" },
        },
    })

    -- ── minuet 的 C-p / C-n：按下时用官方 :CursortabToggle 让 cursortab 让路 5s ──
    -- 用 toggle 而不自己改 config 的理由：
    --   toggle = daemon.set_enabled(取反) + clear_all_completions()（init.lua:63-75），
    --   关掉后 daemon.send_event 在 daemon.lua:228 直接 return，不会再有请求/渲染；
    --   而 behavior.idle_completion_delay / text_change_debounce 是启动时通过环境变量
    --   CURSORTAB_CONFIG 交给 Go daemon 的，运行中改 Lua 表根本不会生效
    --   （除非 restart daemon），所以「临时把 50 改成 -1」那种写法本来就没用。
    -- 注意：不要 require("cursortab").setup({...})，config.setup() 是「defaults + 传入的表」，
    -- 只传局部表会把 provider / keymaps / ui 全打回默认，还会重复注册 autocmd。
    local ct_timer = vim.uv.new_timer()

    -- toggle 自带 vim.notify（"Cursortab disabled"），程序化调用时静音一次
    local function cursortab_toggle_silent()
        local saved_notify = vim.notify
        vim.notify = function() end
        local ok, err = pcall(vim.cmd, "CursortabToggle")
        vim.notify = saved_notify
        if not ok then
            vim.notify("[ai] CursortabToggle failed: " .. tostring(err), vim.log.levels.WARN)
        end
        return ok
    end

    -- 让 cursortab 让路 ms 毫秒。幂等：连按只顺延，不会来回翻（偶数次也不会停在关闭状态）
    local function cursortab_pause(ms)
        local ok, ct_daemon = pcall(require, "cursortab.daemon")
        if not (ok and ct_daemon) then
            return
        end
        if ct_daemon.is_enabled() then
            cursortab_toggle_silent() -- 关
        end
        ct_timer:stop()
        ct_timer:start(
            ms,
            0,
            vim.schedule_wrap(function()
                if not ct_daemon.is_enabled() then
                    cursortab_toggle_silent() -- 5s 后开
                end
            end)
        )
    end

    -- minuet 把动作表暴露在 require("minuet.virtualtext").action（virtualtext.lua:426）
    local vt_ok, vt = pcall(require, "minuet.virtualtext")
    local vt_action = vt_ok and vt and vt.action or nil
    if vt_action then
        vim.keymap.set("i", "<c-p>", function()
            cursortab_pause(5000)
            vt_action.next()
        end, { desc = "[minuet] next suggestion (cursortab paused 5s)", silent = true })
        vim.keymap.set("i", "<c-n>", function()
            cursortab_pause(5000)
            vt_action.prev()
        end, { desc = "[minuet] prev suggestion (cursortab paused 5s)", silent = true })
    end
end

return M
