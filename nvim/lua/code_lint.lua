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

    lint.linters_by_ft = {
        -- python lint is handled by ruff LSP (see lsp/ruff.lua)
        c = { "clangtidy" },
        cpp = { "clangtidy" },
        rust = { "clippy" },
        json = { "jsonlint" },
        jsonc = { "jsonlint" },
        yaml = { "yamllint" },
        toml = { "taplo" },
    }
end

return M
