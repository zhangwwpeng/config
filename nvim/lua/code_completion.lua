local M = {}

---@alias CompletionBackend "blink" | "mini"
--- Change this value and restart Neovim to switch completion backend.
---@type CompletionBackend
M.backend = "blink"

local tiny_cmdline = {
    position = {
        x = "50%",
        y = "10%",
    },
}

local function setup_mini()
    require("mini.completion").setup()
    require("mini.cmdline").setup({
        autocorrect = { enable = false },
    })
    require("tiny-cmdline").setup(tiny_cmdline)
end

local function setup_blink()
    require("blink.cmp").setup({
        keymap = {
            preset = "none",
            ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
            ["<C-n>"] = { "select_next", "fallback_to_mappings" },

            -- 显式确认：有选中项时插入，否则退回普通回车（换行）
            -- ["<Enter>"] = { "accept", "fallback" },
            ["<C-l>"] = { "hide", "fallback" },

            ["<C-u>"] = { "scroll_documentation_up", "fallback" },
            ["<C-d>"] = { "scroll_documentation_down", "fallback" },
        },
        signature = { enabled = true, window = { border = "single" } },
        appearance = {
            use_nvim_cmp_as_default = true,
        },
        sources = {
            default = { "snippets", "lsp", "path", "buffer" },
            providers = {
                -- blink 默认声明 lsp/path 的 fallbacks 是 buffer（sources/lib/tree.lua 会把它变成"依赖门控"）：
                -- 只要 lsp 或 path 返回了候选，buffer 源整条都不会跑。清掉才会始终参与。
                lsp = {
                    fallbacks = function()
                        return {}
                    end,
                },
                path = {
                    name = "Path",
                    module = "blink.cmp.sources.path",
                    score_offset = 3,
                    opts = {
                        trailing_slash = false,
                        label_trailing_slash = true,
                        get_cwd = function(context)
                            return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
                        end,
                        show_hidden_files_by_default = false,
                    },
                },
            },
        },
        fuzzy = { implementation = "prefer_rust_with_warning" },
        snippets = { preset = "luasnip" },
        completion = {
            accept = {
                auto_brackets = {
                    enabled = true,
                },
            },
            -- trigger = {
            --     prefetch_on_insert = false,
            -- },
            ghost_text = { enabled = true },
            menu = {
                -- border = "single",
                draw = {
                    columns = { { "label" }, { "kind" } },
                },
            },
            documentation = {
                auto_show = true,
                window = { border = "single" },
            },
            list = {
                selection = {
                    preselect = false,
                    auto_insert = true,
                },
            },
        },
        cmdline = {
            keymap = {
                preset = "none",
                ["<C-p>"] = { "select_prev", "fallback" },
                ["<C-n>"] = { "select_next", "fallback" },
                -- ['<C-y>'] = { 'select_and_accept', 'fallback' },
            },
            completion = {
                menu = { auto_show = true },
                list = { selection = { preselect = false, auto_insert = true } },
            },
        },
    })
    -- require("tiny-cmdline").setup(vim.tbl_extend("force", tiny_cmdline, {
    --    on_reposition = require("tiny-cmdline").adapters.blink,
    -- }))
end

local backends = {
    mini = setup_mini,
    blink = setup_blink,
}

function M.setup()
    backends[M.backend]()
end

return M
