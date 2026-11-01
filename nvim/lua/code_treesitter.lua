local M = {}

function M.setup()
    vim.treesitter.language.register("bash", { "sh" })
    vim.filetype.add({
        extension = {
            v = "systemverilog",
        },
    })

    --  treesitter
    local filetypes = {
        "c",
        "cpp",
        "systemverilog",
        "python",
        "sh",
        "markdown",
        "json",
        "yaml",
        "toml",
        "make",
        "tcl",
        "bash",
    }

    local function has_indents(ft)
        local lang = vim.treesitter.language.get_lang(ft) or ft
        local ok, query = pcall(vim.treesitter.query.get, lang, "indents")
        return ok and query ~= nil
    end

    -- parser 没装时 start() 会直接报错，打开文件就弹异常；pcall 掉，退回 regex 高亮
    local function start(buf)
        if vim.b[buf].bigfile then
            return -- 大文件 / 特殊 filetype，见 bigfile.lua
        end
        if not pcall(vim.treesitter.start, buf) then
            return -- 没 parser：legacy syntax 还开着，内置缩进照常用
        end
        -- 有 indents.scm 就用 treesitter 缩进（ts_indent.lua）。treesitter.start 关掉了 legacy syntax，
        -- 内置缩进里靠 syntax 判断字符串/注释的逻辑会失效，所以能换就换。
        -- 没有 indents.scm 的（markdown / make / systemverilog）保留内置缩进，它们都不依赖 syntax。
        if has_indents(vim.bo[buf].filetype) then
            vim.bo[buf].cindent = false -- c/cpp 的 ftplugin 开了 cindent，避免 cinkeys 顶掉 indentkeys
            vim.bo[buf].indentexpr = "v:lua.require'ts_indent'.indent(v:lnum)"
        end
    end

    vim.api.nvim_create_autocmd("FileType", {
        pattern = filetypes,
        callback = function(args)
            start(args.buf)
        end,
    })

    -- 本模块在 init.lua 的 vim.schedule 里才执行，`nvim foo.py` 打开的第一个 buffer
    -- 的 FileType 早就触发过了，上面的 autocmd 赶不上，这里给已加载的 buffer 补一次
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.tbl_contains(filetypes, vim.bo[buf].filetype) then
            start(buf)
        end
    end
end

return M
