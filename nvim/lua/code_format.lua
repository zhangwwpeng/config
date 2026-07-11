M = {}

local format = require("conform")
local sv_format = require("sv_format")

local function close_all_float_wins()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local config = vim.api.nvim_win_get_config(win)
        -- Close all floating windows (including ui2's hidden msg/pager/dialog).
        if config.relative ~= "" then
            pcall(vim.api.nvim_win_close, win, true)
        end
    end
end

local function run_all_formatters(done)
    local bufnr = vim.api.nvim_get_current_buf()
    local filetype = vim.bo[bufnr].filetype
    local needs_sv_format = filetype == "systemverilog" or filetype == "verilog"
    local finished = false

    local function finish(conform_err, conform_did_edit, sv_err, sv_did_edit)
        if finished then
            return
        end
        finished = true

        local errors = {}
        if conform_err then
            errors[#errors + 1] = "conform: " .. tostring(conform_err)
        end
        if sv_err then
            errors[#errors + 1] = "sv_format: " .. tostring(sv_err)
        end

        local did_edit = conform_did_edit == true or sv_did_edit == true
        local combined_err
        if #errors > 0 then
            combined_err = table.concat(errors, "; ")
            vim.notify("format error: " .. combined_err, vim.log.levels.ERROR)
        elseif did_edit then
            vim.notify("format successfully", vim.log.levels.INFO)
        else
            vim.notify("already formatted", vim.log.levels.INFO)
        end

        if done then
            done(combined_err, did_edit)
        end
    end

    format.format({ async = true, bufnr = bufnr }, function(conform_err, conform_did_edit)
        if not needs_sv_format then
            finish(conform_err, conform_did_edit)
            return
        end

        -- This formatter supplements conform even when conform made no edits.
        sv_format.format({ bufnr = bufnr }, function(sv_err, sv_did_edit)
            finish(conform_err, conform_did_edit, sv_err, sv_did_edit)
        end)
    end)
end

function M.setup()
    format.setup({
        -- Define your formatters
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "ruff_format" },
            c = { lsp_format = "fallback" },
            cpp = { lsp_format = "fallback" },
            verilog = { "verible" },
            systemverilog = { "verible" },
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
            verible = {
                command = vim.fn.expand("~/.config/nvim/scripts/verible-format-wrapper.sh"),
                append_args = {
                    "--column_limit",
                    "120",
                    "-indentation_spaces",
                    "4",
                    "--alignment_group_boundary",
                    "blank-lines-and-separator-comments",
                    "--assignment_statement_alignment=align",
                    "--case_items_alignment=align",
                    "--class_member_variable_alignment=align",
                    "--distribution_items_alignment=align",
                    "--enum_assignment_statement_alignment=align",
                    "--formal_parameters_alignment=align",
                    "--module_net_variable_alignment=align",
                    "--named_parameter_alignment=align",
                    "--named_port_alignment=align",
                    "--port_declarations_alignment=align",
                    "--struct_union_members_alignment=align",
                    "--formal_parameters_indentation=indent",
                    "--named_parameter_indentation=indent",
                    "--named_port_indentation=indent",
                    "--port_declarations_indentation=indent",
                    "--port_declarations_right_align_packed_dimensions=true",
                    "--port_declarations_right_align_unpacked_dimensions=true",
                },
            },
        },
    })

    -- code format + close floating windows
    vim.keymap.set({ "i", "n", "v" }, "<C-l>", function()
        close_all_float_wins()
        run_all_formatters()
    end, { desc = "Close float windows and format code" })
end

return M
