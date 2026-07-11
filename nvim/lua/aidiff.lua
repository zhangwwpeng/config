local M = {}

local SESSION_ROOT = vim.fn.expand("~/.cache/nvim/ai-diff/sessions")

local function notify(message, level)
    vim.notify("AiDiff: " .. message, level or vim.log.levels.WARN)
end

local function valid_session_name(session_name)
    return type(session_name) == "string"
        and session_name ~= "."
        and session_name ~= ".."
        and session_name:match("^[A-Za-z0-9._-]+$") ~= nil
end

local function valid_relative_path(rel)
    if
        type(rel) ~= "string"
        or rel == ""
        or rel:sub(1, 1) == "/"
        or rel:sub(-1) == "/"
        or rel:find("\0", 1, true)
    then
        return false
    end
    if rel:find("//", 1, true) then
        return false
    end
    for part in rel:gmatch("[^/]+") do
        if part == "." or part == ".." then
            return false
        end
    end
    return true
end

local function read_file(path)
    local ok, lines = pcall(vim.fn.readfile, path, "b")
    if not ok then
        return nil
    end
    return table.concat(lines, "\n")
end

local function ensure_empty_file(path)
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    local ok, err = pcall(vim.fn.writefile, {}, path, "b")
    if not ok then
        notify("无法创建新增文件的空基线 " .. path .. ": " .. tostring(err))
        return false
    end
    return true
end

local function load_session(session_name)
    if not valid_session_name(session_name) then
        notify("非法 session 名")
        return nil
    end

    local session_dir = SESSION_ROOT .. "/" .. session_name
    if vim.fn.isdirectory(session_dir) ~= 1 then
        notify("session 不存在: " .. session_name)
        return nil
    end

    local cwd_path = read_file(session_dir .. "/.cwd")
    if not cwd_path or cwd_path == "" or cwd_path:sub(1, 1) ~= "/" or vim.fn.isdirectory(cwd_path) ~= 1 then
        notify("session 的 .cwd 无效")
        return nil
    end

    local change_text = read_file(session_dir .. "/change.json")
    if not change_text then
        notify("session 缺少 change.json")
        return nil
    end

    local ok, changes = pcall(vim.json.decode, change_text)
    if not ok or type(changes) ~= "table" then
        notify("change.json 无效")
        return nil
    end

    return session_dir, cwd_path, changes
end

function M.run(session_name)
    local session_dir, cwd_path, changes = load_session(session_name)
    if not session_dir then
        return
    end

    local file_pairs = {}
    for rel, operation in pairs(changes) do
        if valid_relative_path(rel) and (operation == "A" or operation == "M" or operation == "D") then
            local old_path = session_dir .. "/old/" .. rel
            local target_path = cwd_path .. "/" .. rel

            if operation == "A" then
                if ensure_empty_file(old_path) then
                    file_pairs[#file_pairs + 1] = { old_path, target_path }
                end
            elseif vim.fn.filereadable(old_path) == 1 then
                -- D 的 target_path 可以不存在；CodeDiff 会把它作为空的新文件缓冲区打开。
                file_pairs[#file_pairs + 1] = { old_path, target_path }
            else
                notify("缺少 old 基线，已跳过: " .. rel)
            end
        else
            notify("change.json 中有非法记录，已跳过: " .. tostring(rel))
        end
    end

    table.sort(file_pairs, function(left, right)
        return left[2] < right[2]
    end)

    if #file_pairs == 0 then
        notify("没有可对比的文件")
        return
    end

    local lifecycle = require("codediff.ui.lifecycle")
    local view = require("codediff.ui.view")
    local original_tab = vim.api.nvim_get_current_tabpage()

    for _, pair in ipairs(file_pairs) do
        if vim.api.nvim_tabpage_is_valid(original_tab) then
            vim.api.nvim_set_current_tabpage(original_tab)
        end

        local filetype = vim.filetype.match({ filename = pair[2] }) or ""
        local opened, err = pcall(view.create, {
            mode = "standalone",
            git_root = nil,
            original_path = pair[1],
            modified_path = pair[2],
            original_revision = nil,
            modified_revision = nil,
        }, filetype)

        if not opened then
            notify("打开文件对比失败: " .. tostring(err))
        else
            local current_tab = vim.api.nvim_get_current_tabpage()
            if not lifecycle.get_session(current_tab) then
                notify("CodeDiff 未能创建对比窗口: " .. pair[2])
            end
        end
    end
end

function M.setup()
    vim.api.nvim_create_user_command("AiDiff", function(opts)
        M.run(opts.fargs[1])
    end, {
        nargs = 1,
        desc = "AI Diff: 逐文件比较 AI 修改前快照与当前工作区",
    })
end

return M
