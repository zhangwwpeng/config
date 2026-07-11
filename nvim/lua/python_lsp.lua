local M = {}

--- Skip installed packages; otherwise find project root or fall back to file dir.
function M.root_dir(bufnr, on_dir)
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local normalized_name = bufname:gsub("\\", "/")
    if normalized_name:find("/site-packages/", 1, true) or normalized_name:find("/dist-packages/", 1, true) then
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
