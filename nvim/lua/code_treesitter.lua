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

    -- parser 没装时 start() 会直接报错，打开文件就弹异常；pcall 掉，退回 regex 高亮
    local function start(buf)
        if vim.b[buf].bigfile then
            return -- 大文件 / 特殊 filetype，见 bigfile.lua
        end
        pcall(vim.treesitter.start, buf)
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
