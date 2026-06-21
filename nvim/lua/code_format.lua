M = {}

local format = require("conform")

local function close_all_float_wins()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local config = vim.api.nvim_win_get_config(win)
        -- Close all floating windows (including ui2's hidden msg/pager/dialog).
        if config.relative ~= "" then
            pcall(vim.api.nvim_win_close, win, true)
        end
    end
end

function M.setup()
    format.setup({
        -- Define your formatters
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "ruff_format" },
            c = { lsp_format = "fallback" },
            cpp = { lsp_format = "fallback" },
            rust = { lsp_format = "fallback" },
            just = { lsp_format = "fallback" },
            make = { lsp_format = "fallback" },
            tcl = { lsp_format = "fallback" },
            bash = { "shfmt" },
            sh = { "shfmt" },
            json = { "jq" },
            jsonc = { "jq" },
            yaml = { "yamlfmt" },
            toml = { "taplo" },
            ["_"] = { "trim_whitespace" },
        },
        default_format_opts = {
            lsp_format = "fallback",
        },
        -- Set up format-on-save
        -- format_on_save = { timeout_ms = 500 },
        -- Customize formatters
        formatters = {
            stylua = {
                append_args = { "--indent-type", "Spaces" },
            },
        },
    })

    -- code format + close floating windows
    vim.keymap.set({ "i", "n", "v" }, "<C-l>", function()
        close_all_float_wins()
        format.format({ async = true }, function(err, did_edit)
            if err then
                vim.notify("format error: " .. err, vim.log.levels.ERROR)
            elseif did_edit then
                vim.notify("format successfully", vim.log.levels.INFO)
            else
                vim.notify("already formatted", vim.log.levels.INFO)
            end
        end)
    end, { desc = "Close float windows and format code" })
end

return M
