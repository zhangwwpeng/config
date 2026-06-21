local M = {}

--- Skip stdlib/site-packages; otherwise find project root or fall back to file dir.
function M.root_dir(bufnr, on_dir)
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if bufname:match("site%-packages") or bufname:match("[\\/][Ll]ib[\\/]") then
        return
    end

    local root = vim.fs.root(bufnr, {
        "pyproject.toml",
        "pyrightconfig.json",
        "ruff.toml",
        ".ruff.toml",
        "pyrefly.toml",
        ".git",
    }) or vim.fs.dirname(bufname)

    on_dir(root)
end

return M
