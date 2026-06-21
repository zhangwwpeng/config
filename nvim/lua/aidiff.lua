local M = {}

local SESSION_ROOT = vim.fn.expand("~/.cache/nvim/ai-diff/sessions")

function M.run(session_name, cwd_path)
    local session_dir = SESSION_ROOT .. "/" .. session_name
    local old_dir = session_dir .. "/old"
    local new_dir = session_dir .. "/new"
    cwd_path = cwd_path or vim.fn.getcwd()

    local ok, err = pcall(vim.cmd, "CodeDiff dir " .. vim.fn.fnameescape(old_dir) .. " " .. vim.fn.fnameescape(new_dir))

    if not ok then
        vim.notify("AiDiff: 打开目录对比失败: " .. tostring(err), vim.log.levels.WARN)
        return
    end
end

function M.setup()
    vim.api.nvim_create_user_command("AiDiff", function(opts)
        M.run(unpack(opts.fargs))
    end, {
        nargs = "+",
        desc = "AI Diff: 比较 old/new 并同步到工作区",
    })
end

return M
