local M = {}

local async = vim.async

local showdotfile = false
local src_path = ""

-- 非阻塞执行命令，必须在 vim.async.run() 的 task 内调用
-- vim.system 的 on_exit 是在 fast event 上下文里回调的，直接 await 会让任务在那个上下文里恢复，
-- 之后连 vim.notify / nvim_buf_get_name 都会报 E5560，所以套一层 vim.schedule 回到普通上下文
local function run(cmd)
    local ok, obj = async.pawait(function(done)
        vim.system(cmd, {}, function(obj)
            vim.schedule(function()
                done(obj)
            end)
        end)
    end)

    if not ok then
        -- 起进程就失败了，比如命令不存在
        return false, tostring(obj)
    end

    -- 进程被信号杀掉时 code 是 0、signal 才是非 0，所以两个都要看
    if obj.code ~= 0 or obj.signal ~= 0 then
        local why = ("code %d, signal %d"):format(obj.code, obj.signal)
        return false, obj.stderr ~= "" and obj.stderr or why
    end

    return true
end

local function entry_path_str(path, name)
    return vim.fs.joinpath(path, (name:gsub("/$", "")))
end

-- 列表里每行是相对名字，按 buffer 名拼成绝对路径
local function entry_path(buf, name)
    return entry_path_str(vim.api.nvim_buf_get_name(buf), name)
end

-- 目标目录里已经有同名条目时加 _cpy 后缀，还撞就再叠一个：a.lua、a.lua_cpy、a.lua_cpy_cpy
local function copy_dst_path(dir, name)
    name = (name:gsub("/$", ""))

    local dst = entry_path_str(dir, name)
    while vim.uv.fs_lstat(dst) do
        name = name .. "_cpy"
        dst = entry_path_str(dir, name)
    end

    return dst
end

-- 重新读目录列表（增删改文件后调用），buffer 隐藏着也能刷
local function reload_dir(buf)
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
        vim.api.nvim_buf_call(buf, function()
            vim.cmd("edit")
        end)
    end
end

function M.record_filepath(args)
    src_path = args
end

function M.copy_file()
    local files = vim.fn.getreg("0")
    if files == "" then
        return
    end

    if src_path == "" then
        vim.notify("Copy: no source directory, yank a file in a directory first", vim.log.levels.WARN)
        return
    end

    local buf = vim.api.nvim_get_current_buf()
    local dst_path = vim.api.nvim_buf_get_name(buf)

    for _, file in ipairs(vim.split(files, "\n", { trimempty = true })) do
        local src = entry_path_str(src_path, file)
        local dst = copy_dst_path(dst_path, file)

        vim.notify("copy file " .. src .. " to " .. dst)

        local ok, err = run({ "cp", "-r", "--", src, dst })
        if not ok then
            vim.notify("Copy failed: " .. src .. "\n" .. err, vim.log.levels.ERROR)
        else
            vim.notify("copy file " .. src .. " to " .. dst .. " done")
        end
    end

    reload_dir(buf)
end

function M.trigger_showdotfile()
    if showdotfile == true then
        showdotfile = false
    else
        showdotfile = true
    end
    vim.cmd("edit")
end

function M.delete_file()
    local buf = vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_get_current_line()
    if file == "" then
        return
    end

    local choice = vim.fn.confirm("Delete " .. file .. "?", "&y\n&n", 2)
    if choice ~= 1 then
        return
    end

    local ok, err = run({ "rm", "-rf", "--", entry_path(buf, file) })
    if not ok then
        vim.notify("Delete failed: " .. file .. "\n" .. err, vim.log.levels.ERROR)
    end

    reload_dir(buf)
end

function M.delete_range_file()
    local buf = vim.api.nvim_get_current_buf()
    local start_line = vim.fn.line("v")
    local end_line = vim.fn.line(".")

    if start_line > end_line then
        start_line, end_line = end_line, start_line
    end

    local files = vim.api.nvim_buf_get_lines(buf, start_line - 1, end_line, false)

    local choice = vim.fn.confirm("Delete " .. #files .. " files?", "&y\n&n", 2)
    if choice ~= 1 then
        return
    end

    local failed = {}
    for _, file in ipairs(files) do
        local ok, err = run({ "rm", "-rf", "--", entry_path(buf, file) })
        if not ok then
            table.insert(failed, file .. ": " .. err)
        end
    end

    if #failed > 0 then
        vim.notify("Delete failed:\n" .. table.concat(failed, "\n"), vim.log.levels.ERROR)
    else
        vim.notify(("Deleted %d files"):format(#files))
    end

    reload_dir(buf)
end

local function format_size(size)
    if size >= 1024 * 1024 * 1024 then
        return string.format("%.1fG", size / (1024 * 1024 * 1024))
    elseif size >= 1024 * 1024 then
        return string.format("%.1fM", size / (1024 * 1024))
    elseif size >= 1024 then
        return string.format("%.1fK", size / 1024)
    else
        return string.format("%dB", size)
    end
end

function M.add_file()
    vim.ui.input({ prompt = "Name: " }, function(name)
        if not name or name == "" then
            return
        end

        if name:find("/", 1, true) then
            -- 包含 /，创建目录
            vim.fn.mkdir(name, "p")
        else
            -- 不包含 /，创建文件
            vim.fn.system({ "touch", name })
        end

        vim.cmd("edit")
    end)
end

function M.add_range_file()
    local dir_buf = vim.api.nvim_get_current_buf()
    local dst_path = vim.api.nvim_buf_get_name(dir_buf)

    -- 创建临时 buffer
    local tmp_buf = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_buf_set_name(tmp_buf, "New Files")

    -- 当前窗口打开
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, tmp_buf)

    vim.bo[tmp_buf].buftype = "nofile"
    vim.bo[tmp_buf].bufhidden = "wipe"
    vim.bo[tmp_buf].swapfile = false

    -- 关闭时创建文件
    vim.api.nvim_create_autocmd("BufWipeout", {
        buffer = tmp_buf,
        once = true,
        callback = function()
            local content = vim.api.nvim_buf_get_lines(tmp_buf, 0, -1, false)
            local failed = {}

            for _, file in ipairs(content) do
                if file ~= "" then
                    local path = entry_path_str(dst_path, file)
                    if file:find("/", 1, true) then
                        -- 包含 /，创建目录
                        local ok, err = pcall(vim.fn.mkdir, path, "p")
                        if ok then
                            vim.notify("Created dir " .. file)
                        else
                            table.insert(failed, file .. ": " .. tostring(err))
                        end
                    else
                        -- 不包含 /，创建文件
                        local result = vim.fn.system({ "touch", path })
                        if vim.v.shell_error == 0 then
                            vim.notify("Created file " .. file)
                        else
                            table.insert(failed, file .. ": " .. vim.trim(result))
                        end
                    end
                end
            end

            if #failed > 0 then
                vim.notify("Create failed:\n" .. table.concat(failed, "\n"), vim.log.levels.ERROR)
            end
        end,
        reload_dir(dir_buf),
    })
end

function M.rename_file()
    local file = vim.api.nvim_get_current_line()

    vim.ui.input({
        prompt = "Rename to: ",
        default = file,
    }, function(new_name)
        if not new_name or new_name == "" or new_name == file then
            return
        end

        local ret = vim.fn.rename(file, new_name)
        if ret == 0 then
            vim.cmd("edit")
        else
            vim.notify("Rename failed: " .. new_name, vim.log.levels.ERROR)
        end
    end)
end

-- 两段式改名的临时后缀，取个基本不会撞车的名字
local tmp_suffix = "_xxddxxtmp"

function M.range_rename_file()
    local start_line = vim.fn.line("v")
    local end_line = vim.fn.line(".")

    if start_line > end_line then
        start_line, end_line = end_line, start_line
    end

    local dir_buf = vim.api.nvim_get_current_buf()
    local dst_path = vim.api.nvim_buf_get_name(dir_buf)
    local files = vim.api.nvim_buf_get_lines(dir_buf, start_line - 1, end_line, false)

    -- 创建临时 buffer
    local tmp_buf = vim.api.nvim_create_buf(false, true)

    -- 把原文件名放进去
    vim.api.nvim_buf_set_lines(tmp_buf, 0, -1, false, files)

    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, tmp_buf)

    vim.bo[tmp_buf].buftype = "nofile"
    vim.bo[tmp_buf].bufhidden = "wipe"
    vim.bo[tmp_buf].swapfile = false

    -- 关闭时执行 mv
    vim.api.nvim_create_autocmd("BufWipeout", {
        buffer = tmp_buf,
        once = true,
        callback = function()
            local new_files = vim.api.nvim_buf_get_lines(tmp_buf, 0, -1, false)

            if #new_files ~= #files then
                vim.notify("Number of files changed!", vim.log.levels.ERROR)
                return
            elseif vim.deep_equal(new_files, files) then
                return
            end

            local failed = {}
            local tmp_paths = {}

            -- 先全部改成临时名，避免 a->b、b->a 这种互换互相覆盖
            for i, old_name in ipairs(files) do
                local new_name = new_files[i]

                if old_name ~= new_name and new_name ~= "" then
                    local tmp_path = entry_path_str(dst_path, old_name) .. tmp_suffix
                    local result = vim.fn.system({ "mv", entry_path_str(dst_path, old_name), tmp_path })

                    if vim.v.shell_error == 0 then
                        tmp_paths[old_name] = tmp_path
                    else
                        table.insert(failed, old_name .. ": " .. vim.trim(result))
                    end
                end
            end

            -- 再改成新名字
            for i, old_name in ipairs(files) do
                local tmp_path = tmp_paths[old_name]

                if tmp_path then
                    local new_name = new_files[i]
                    local result = vim.fn.system({ "mv", tmp_path, entry_path_str(dst_path, new_name) })

                    if vim.v.shell_error == 0 then
                        vim.notify("Renamed " .. old_name .. " -> " .. new_name)
                    else
                        table.insert(failed, old_name .. " -> " .. new_name .. ": " .. vim.trim(result))
                    end
                end
            end

            if #failed > 0 then
                vim.notify("Rename failed:\n" .. table.concat(failed, "\n"), vim.log.levels.ERROR)
            end
        end,
    })
    reload_dir(dir_buf)
end

function M.setup()
    vim.api.nvim_create_autocmd("User", {
        pattern = "DirReadPost",
        callback = function(args)
            vim.api.nvim_buf_call(args.buf, function()
                if not showdotfile then
                    vim.cmd([[silent keeppatterns g/^\./d _]])
                end
            end)
        end,
    })

    local ns = vim.api.nvim_create_namespace("my.dir.classify")
    -- local glyph = {
    --     fifo = " |",
    --     socket = " =",
    --     char = " %",
    --     block = " #",
    -- }
    vim.api.nvim_set_decoration_provider(ns, {
        on_win = function(_, _, buf)
            return vim.bo[buf].filetype == "directory"
        end,
        on_range = function(_, _, buf, row)
            local dir = vim.api.nvim_buf_get_name(buf)
            local name = vim.api.nvim_buf_get_lines(buf, row, row + 1, true)[1]
            local path = vim.fs.joinpath(dir, (name:gsub("/$", "")))
            local stat = vim.uv.fs_lstat(path) or {}
            -- local exe = stat.type == "file" and bit.band(stat.mode, tonumber("111", 8)) ~= 0
            -- local char = glyph[stat.type] or (exe and " *")
            local size = stat.size and format_size(stat.size) or "-"
            local mtime = stat.mtime and os.date("%Y-%m-%d %H:%M:%S", stat.mtime.sec) or ""
            local info = string.format("%8s  %s", size and tostring(size) or "-", mtime)

            vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
                virt_text = { { info, "Comment" } },
                virt_text_pos = "right_align",
                ephemeral = true,
            })
            -- if char then
            --     vim.api.nvim_buf_set_extmark(buf, ns, row, #name, {
            --         virt_text = { { char, "dimmed" } },
            --         virt_text_pos = "overlay",
            --         ephemeral = true,
            --     })
            -- end
            if stat.type == "link" then
                local target = vim.uv.fs_readlink(path) or "?"
                vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
                    virt_text = { { "-> " .. target, "dimmed" } },
                    virt_text_pos = "eol",
                    ephemeral = true,
                })
            end
            -- on_range 允许返回 skip_row 整数，让 nvim 跳过已处理的行；
            -- 但当前 lua_ls 的 nvim 类型注解只声明了 boolean?，故这里是误报，压掉即可
            ---@diagnostic disable-next-line: return-type-mismatch
            return row + 1
        end,
    })

    vim.api.nvim_create_autocmd("TextYankPost", {
        callback = function()
            -- 只在目录列表里 yank 才记源目录，在普通文件里 yank 会记成文件路径
            local buf = vim.api.nvim_get_current_buf()
            if vim.bo[buf].filetype == "directory" then
                require("dir").record_filepath(vim.api.nvim_buf_get_name(buf))
            end
        end,
    })
end

return M
