local M = {}

---@param opts? { signs?: table, virtual_lines?: table }
function M.setup(opts)
    opts = opts or {}
    vim.diagnostic.config({
        virtual_text = true,
        virtual_lines = opts.virtual_lines or { current_line = true },
        underline = false,
        update_in_insert = false,
        signs = opts.signs or {
            text = {
                [vim.diagnostic.severity.ERROR] = "\u{EA87}",
                [vim.diagnostic.severity.WARN] = "\u{EA6C}",
                [vim.diagnostic.severity.INFO] = "\u{EA74}",
                [vim.diagnostic.severity.HINT] = "\u{F0B16} ",
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
            " \u{EA87} %d \u{EA6C} %d \u{EA74} %d \u{F0B16} %d ",
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
        "%{v:lua.lsp_diagnostics()}",
        "%y %l,%c",
    }, "")

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
end

return M
