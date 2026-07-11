M = {}

local lint = require("lint")

function M.setup()
    -- lint config
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function()
            -- try_lint without arguments runs the linters defined in `linters_by_ft`
            -- for the current filetype
            lint.try_lint()

            -- You can call `try_lint` with a linter name or a list of names to always
            -- run specific linters, independent of the `linters_by_ft` configuration
            lint.try_lint("typos")
        end,
    })

    -- lint config
    lint.linters.taplo = {
        cmd = "taplo",
        stdin = true,
        args = { "lint", "--colors", "never", "-" },
        stream = "stderr",
        ignore_exitcode = true,
        parser = function(output, _)
            local diags = {}
            local lnum, col
            for line in output:gmatch("[^\r\n]+") do
                local ln, cl = line:match("┌─ .-:(%d+):(%d+)")
                if ln then
                    lnum, col = tonumber(ln) - 1, tonumber(cl) - 1
                end
                local msg = line:match("│ %^ (.+)")
                if msg and lnum then
                    diags[#diags + 1] = {
                        lnum = lnum,
                        col = col,
                        message = msg,
                        severity = vim.diagnostic.severity.ERROR,
                        source = "taplo",
                    }
                end
            end
            return diags
        end,
    }

    -- NOTE: nvim-lint built-in svlint pattern can miss diagnostics with newer svlint output.
    -- Keep a local parser that tolerates tab/space variations in `--oneline` mode.
    lint.linters.svlint = {
        name = "svlint",
        cmd = "svlint",
        stdin = false,
        stream = "both",
        env = {
            NO_COLOR = "1",
            CLICOLOR = "0",
            CLICOLOR_FORCE = "0",
        },
        append_fname = false,
        -- Pass absolute file path ourselves to avoid edge-cases with appended fname.
        args = {
            "--oneline",
            "--config",
            vim.fn.expand("~/.config/nvim/.svlint.toml"),
            function()
                local fname = vim.api.nvim_buf_get_name(0)
                return vim.fn.fnamemodify(fname, ":p")
            end,
        },
        ignore_exitcode = true,
        parser = function(output, _)
            local diags = {}
            for line in output:gmatch("[^\r\n]+") do
                line = line:gsub("\27%[[%d;]*[%a]", "")
                local sev, file, lnum, col, msg = line:match("^(%a+)%s+([^:]+):(%d+):(%d+).-[Hh]int:%s*(.+)$")
                if (sev == "Fail" or sev == "Warning" or sev == "Error") and file and lnum and col and msg then
                    msg = msg:gsub("%.%s*$", "")
                    diags[#diags + 1] = {
                        lnum = tonumber(lnum) - 1,
                        col = tonumber(col) - 1,
                        message = msg,
                        severity = sev == "Error" and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
                        source = "svlint",
                    }
                end
            end
            return diags
        end,
    }

    -- lint.linters.verilator = {
    --     name = "verilator",
    --     cmd = "verilator",
    --     stdin = false,
    --     stream = "stderr",
    --     args = {
    --         "-sv",
    --         "-Wall",
    --         "-Wno-GENUNNAMED",
    --         "--bbox-sys",
    --         "--bbox-unsup",
    --         "--lint-only",
    --     },
    --     ignore_exitcode = true,
    --     parser = function(output, _)
    --         local diags = {}
    --         for line in output:gmatch("[^\r\n]+") do
    --             local sev, file, lnum, col, msg = line:match("^%%(%a+)%-%u+:%s(.-):(%d+):(%d+):%s(.+)$")
    --             if sev == "Warning" or sev == "Error" then
    --                 diags[#diags + 1] = {
    --                     lnum = tonumber(lnum) - 1,
    --                     col = tonumber(col) - 1,
    --                     message = msg,
    --                     severity = sev == "Error" and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
    --                     source = "verilator",
    --                 }
    --             end
    --         end
    --         return diags
    --     end,
    -- }

    lint.linters.verible = {
        name = "verible",
        cmd = "verible-verilog-lint",
        stdin = false,
        stream = "stderr",
        args = {
            "--parse_fatal=false",
            "--lint_fatal=false",
            "--rules=-always-comb,-parameter-name-style,-parameter-type-name-style,-line-length",
        },
        ignore_exitcode = true,
        parser = function(output, _)
            local diags = {}
            for line in output:gmatch("[^\r\n]+") do
                local file, lnum, col, msg = line:match("^(.-):(%d+):(%d+)%-%d+:%s*(.+)$")
                if not (file and lnum and col and msg) then
                    file, lnum, col, msg = line:match("^(.-):(%d+):(%d+):%s*(.+)$")
                end
                if file and lnum and col and msg then
                    local lower_msg = msg:lower()
                    local severity = vim.diagnostic.severity.WARN
                    if lower_msg:match("^error") or lower_msg:match("^syntax error") then
                        severity = vim.diagnostic.severity.ERROR
                    elseif lower_msg:match("^warning") then
                        severity = vim.diagnostic.severity.WARN
                    end
                    diags[#diags + 1] = {
                        lnum = tonumber(lnum) - 1,
                        col = tonumber(col) - 1,
                        message = msg,
                        severity = severity,
                        source = "verible",
                    }
                end
            end
            return diags
        end,
    }

    lint.linters_by_ft = {
        -- python lint is handled by ruff LSP (see lsp/ruff.lua)
        c = { "clangtidy" },
        cpp = { "clangtidy" },
        rust = { "clippy" },
        json = { "jsonlint" },
        jsonc = { "jsonlint" },
        yaml = { "yamllint" },
        toml = { "taplo" },
        systemverilog = { "svlint", "verilator", "verible" },
        verilog = { "svlint", "verilator", "verible" },
    }
end

return M
