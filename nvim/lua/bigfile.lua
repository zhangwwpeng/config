-- bigfile：大文件 / 二进制文件 / 特殊 filetype 关掉重功能
--
-- 命中后设 vim.b[buf].bigfile = 原因（"size" / "binary" / "filetype"），各模块自己检查这个变量：
--   treesitter 高亮 + 折叠   本模块（stop + foldmethod=manual）、code_treesitter.lua
--   缩进线                   indent.lua
--   treesitter-context      treesitter_context_cfg.lua
--   markdown 代码块背景       markdown_hlcode.lua
--   保存时 lint（含 typos）   code_lint.lua
--   AI 补全                  ai.lua（copilot / cursortab / minuet）
-- 原因 "filetype"：filetype 或扩展名命中 M.config.filetypes / M.config.extensions
local M = {}

M.config = {
    size = 1024 * 1024, -- 超过这个字节数算大文件
    filetypes = { log = true, csv = true, tsv = true },
    -- 按扩展名判断：nvim 对 *.log 是按内容猜 filetype 的，普通日志 filetype 为空，只看 filetype 抓不到
    extensions = { log = true, csv = true, tsv = true },
}

---文件开头 1KB 里有 NUL 就当二进制
---@param path string
---@return boolean
local function is_binary(path)
    local fd = vim.uv.fs_open(path, "r", 0)
    if not fd then
        return false
    end
    local data = vim.uv.fs_read(fd, 1024, 0)
    vim.uv.fs_close(fd)
    return data ~= nil and data:find("\0", 1, true) ~= nil
end

---@param buf integer
---@return string? reason
local function check_file(buf)
    local path = vim.api.nvim_buf_get_name(buf)
    if path == "" then
        return nil
    end
    if M.config.extensions[vim.fn.fnamemodify(path, ":e"):lower()] then
        return "filetype"
    end
    local stat = vim.uv.fs_stat(path)
    if not stat or stat.type ~= "file" then
        return nil
    end
    if stat.size > M.config.size then
        return "size"
    end
    if is_binary(path) then
        return "binary"
    end
end

---treesitter 折叠：foldexpr 会自己建 parser 解析整个文件，换成 manual（window 局部选项，进窗口时都要设）
---@param buf integer
local function disable_fold(buf)
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        vim.wo[win][0].foldmethod = "manual"
    end
end

---@param buf integer
local function disable(buf)
    -- markdown / lua 等的 ftplugin 会自己 treesitter.start，这里统一停掉
    pcall(vim.treesitter.stop, buf)
    disable_fold(buf)
end

---@param buf integer
---@param reason string
local function mark(buf, reason)
    if vim.b[buf].bigfile then
        return
    end
    vim.b[buf].bigfile = reason
    vim.notify(("bigfile (%s)：已关闭 treesitter / 缩进线 / lint / AI"):format(reason), vim.log.levels.INFO)
end

---@param buf integer
local function on_filetype(buf)
    if M.config.filetypes[vim.bo[buf].filetype] then
        mark(buf, "filetype")
    end
    if vim.b[buf].bigfile then
        disable(buf)
    end
end

function M.setup()
    local group = vim.api.nvim_create_augroup("BigFile", { clear = true })

    -- 读文件之前就判定，FileType 里各模块看到的已经是打好标记的 buffer
    vim.api.nvim_create_autocmd("BufReadPre", {
        group = group,
        callback = function(args)
            local reason = check_file(args.buf)
            if reason then
                mark(args.buf, reason)
            end
        end,
    })
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(args)
            on_filetype(args.buf)
        end,
    })
    vim.api.nvim_create_autocmd("BufWinEnter", {
        group = group,
        callback = function(args)
            if vim.b[args.buf].bigfile then
                disable_fold(args.buf)
            end
        end,
    })
end

return M
