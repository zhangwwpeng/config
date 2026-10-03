------------------------------------------------------------------------
-- pi_diff: rsync 快照 + codediff 目录对比 + 一键回滚
------------------------------------------------------------------------
-- 每轮对话（pi 的 before_agent_start）把项目 rsync 到 nvim cache 下的快照，
-- 用 codediff 的目录模式对比 snapshot 与当前 cwd，或用 rsync 精确回滚。
-- 不依赖 pi-workspace-history。
--
-- 键位：<leader>aD 看本轮改动  <leader>aR 回滚本轮
--
-- 调用 require("pi_diff").ask_enable() 询问当前 cwd 是否启用；
-- 未启用时 review/rollback 会被拒绝，快照也不刷新。
--
-- 快照与「启用时的 cwd」绑定：中途 :cd 不会串项目。
-- 快照先写 *.tmp 再原子替换，rsync 失败不会留下半截快照被回滚。
------------------------------------------------------------------------

local M = {}

local async = vim.async

local DEFAULT_SNAPSHOT_ROOT = vim.fs.joinpath(vim.fn.stdpath("cache"), "pi-diff")

local opts = {
    exclude = {
        ".git/",
        ".jj/",
        "node_modules/",
        ".venv/",
        "venv/",
        "__pycache__/",
        "target/",
        "build/",
        "dist/",
        ".cache/",
        ".DS_Store",
        "*.o",
    },
    confirm_rollback = true,
}

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

------------------------------------------------------------------------
-- utils
------------------------------------------------------------------------

local function strip_slash(p)
    return (p:gsub("/+$", ""))
end

local function with_slash(p)
    return strip_slash(p) .. "/"
end

--- 展开 ~ / 环境变量并转绝对路径
--- escape 掉 % #，否则 expand() 会把它们当当前文件名/alternate 文件名展开
local function abspath(p)
    p = vim.fn.expand(vim.fn.escape(p, "#%"))
    return strip_slash(vim.fn.fnamemodify(p, ":p"))
end

local function ensure_dir(p)
    vim.fn.mkdir(p, "p")
end

local function rm_rf(p)
    if p == nil or p == "" then
        return
    end
    vim.fn.delete(p, "rf")
end

--- 文件 mtime+size 指纹，用来判断回滚是否真的动了这个文件
local function file_fingerprint(p)
    local st = vim.uv.fs_stat(p)
    if not st then
        return nil
    end
    return string.format("%d.%d.%d", st.mtime.sec, st.mtime.nsec, st.size)
end

------------------------------------------------------------------------
-- state
------------------------------------------------------------------------

local enabled = false
---@type { path: string, cwd: string, ok: boolean }?
local snapshot = nil

local function resolve_cwd()
    return abspath(vim.uv.cwd())
end

local function snapshot_dir()
    return snapshot and snapshot.path or nil
end

local function snapshot_cwd()
    return snapshot and snapshot.cwd or nil
end

--- 新建一个绑定当前 cwd 的快照记录（此时还没有内容）
local function new_snapshot()
    local name = string.format("pi-diff-%s-%d", os.date("%Y-%m-%dT%H-%M-%S"), vim.fn.getpid())
    snapshot = {
        path = vim.fs.joinpath(DEFAULT_SNAPSHOT_ROOT, name),
        cwd = resolve_cwd(),
        ok = false,
    }
    return snapshot
end

local function snapshot_ready()
    return snapshot ~= nil
        and snapshot.ok
        and vim.fn.isdirectory(snapshot.path) == 1
        and vim.fn.isdirectory(snapshot.cwd) == 1
end

------------------------------------------------------------------------
-- rsync
------------------------------------------------------------------------

local function rsync_excludes()
    local args = {}
    for _, p in ipairs(opts.exclude) do
        args[#args + 1] = "--exclude=" .. p
    end
    return args
end

--- 阻塞拷贝。调用方可能处于 pi 的 blocking hook 里：
--- 这里必须等 rsync 真正跑完，才能保证 agent 动手前快照已就位。
--- 代价是 rsync 期间 nvim 主循环被占住（见文件头的说明）。
local function run_rsync(src, dst)
    local cmd = { "rsync", "-a", "--delete" }
    vim.list_extend(cmd, rsync_excludes())
    cmd[#cmd + 1] = with_slash(src)
    cmd[#cmd + 1] = with_slash(dst)

    -- vim.system 在找不到可执行文件时是直接抛错，而不是返回非 0 code
    local spawned, res = pcall(function()
        return vim.system(cmd, { text = true }):wait()
    end)
    if not spawned then
        return nil, tostring(res)
    end

    if res.code ~= 0 then
        local err = res.stderr
        if not err or err == "" then
            err = "rsync exited with code " .. tostring(res.code)
        end
        return nil, err
    end
    return true
end

--- 快照与绑定的 cwd 是否有差异（dry-run，不写文件；忽略目录/权限等属性变化）
local function has_changes()
    if not snapshot then
        return false
    end

    local cmd = { "rsync", "-a", "--delete", "--dry-run", "--itemize-changes", "--omit-dir-times" }
    vim.list_extend(cmd, rsync_excludes())
    cmd[#cmd + 1] = with_slash(snapshot.cwd)
    cmd[#cmd + 1] = with_slash(snapshot.path)

    local spawned, res = pcall(function()
        return vim.system(cmd, { text = true }):wait()
    end)
    if not spawned or res.code ~= 0 then
        -- 出错时保守处理：当作有改动，交给 review 自己报错
        return true
    end
    -- 以 "." 开头的行是「无需传输、只改属性」（如目录/文件时间），不算内容改动
    for line in (res.stdout or ""):gmatch("[^\r\n]+") do
        if line:sub(1, 1) ~= "." then
            return true
        end
    end
    return false
end

--- 把绑定的 cwd 镜像到快照目录。
--- 先 rsync 到 *.tmp，成功后再原子替换正式目录：
--- 中途失败/被杀不会留下半截快照，也就不会被 rollback 当成基线来 --delete。
local function refresh()
    if not snapshot then
        return false
    end

    vim.notify("[pi-agent] rsync waiting...")

    local cwd = snapshot.cwd
    local dst = snapshot.path
    local tmp = dst .. ".tmp"

    rm_rf(tmp)
    ensure_dir(tmp)

    local ok, err = run_rsync(cwd, tmp)
    if not ok then
        rm_rf(tmp)
        rm_rf(dst) -- 旧快照也作废，避免用陈旧/另一轮的基线回滚
        snapshot.ok = false
        vim.notify("[pi-agent] rsync 快照失败: " .. tostring(err), vim.log.levels.ERROR)
        return false
    end

    rm_rf(dst)
    if not vim.uv.fs_rename(tmp, dst) then
        rm_rf(tmp)
        rm_rf(dst)
        snapshot.ok = false
        vim.notify("[pi-agent] 快照目录替换失败", vim.log.levels.ERROR)
        return false
    end

    snapshot.ok = true
    -- 更新快照目录 mtime，标记本轮活动（cleanup_stale 按 mtime 判过期）
    vim.uv.fs_utime(dst, os.time(), os.time())

    vim.notify("[pi-agent] rsync done")
    return true
end

--- 询问当前 cwd 是否启用 pi_diff
function M.ask_enable()
    local choice = vim.fn.confirm(
        string.format("[pi-agent] 是否为当前 cwd 启用快照/对比/回滚？\n%s", vim.fn.getcwd()),
        "&Yes\n&No",
        1
    )
    enabled = choice == 1
    snapshot = nil

    if enabled then
        new_snapshot() -- 绑定当前 cwd，之后 :cd 不影响本轮
        refresh()
    end
    return enabled
end

------------------------------------------------------------------------
-- cleanup
------------------------------------------------------------------------

--- 异步清理过期快照（后台 find + rm，不阻塞；>24h 未活动）
local function cleanup_stale()
    if vim.fn.isdirectory(DEFAULT_SNAPSHOT_ROOT) ~= 1 then
        return
    end

    vim.async.run(function()
        run({
            "find",
            DEFAULT_SNAPSHOT_ROOT,
            "-mindepth",
            "1",
            "-maxdepth",
            "1",
            "-type",
            "d",
            "-mmin",
            "+1440",
            "-exec",
            "rm",
            "-rf",
            "--",
            "{}",
            "+",
        })
    end)
end

------------------------------------------------------------------------
-- public actions
------------------------------------------------------------------------

function M.review()
    if not enabled then
        vim.notify("[pi-agent] pi_diff not enable", vim.log.levels.WARN)
        return
    end
    if not snapshot_ready() then
        vim.notify("[pi-agent] 没有可用的快照，跳过对比", vim.log.levels.WARN)
        return
    end

    local ok, dir_diff = pcall(require, "codediff.commands.handlers.dir_diff")
    if not ok then
        vim.notify("[pi-agent] codediff not valid", vim.log.levels.ERROR)
        return
    end

    vim.notify("[pi-agent] call codediff to compare snap and source code")
    dir_diff.run(snapshot.path, snapshot.cwd, {})
end

function M.rollback()
    if not enabled then
        vim.notify("[pi-agent] pi_diff not enable", vim.log.levels.WARN)
        return
    end
    if not snapshot_ready() then
        vim.notify("[pi-agent] 没有可用的快照，拒绝回滚", vim.log.levels.WARN)
        return
    end

    -- 记录各 buffer 文件的指纹与 modified 状态，回滚后只重载真的被改过的文件
    local bufs = {}
    local unsaved = 0
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buftype == "" then
            local name = vim.api.nvim_buf_get_name(b)
            if name ~= "" then
                bufs[#bufs + 1] = {
                    buf = b,
                    name = name,
                    before = file_fingerprint(name),
                    modified = vim.bo[b].modified,
                }
                if vim.bo[b].modified then
                    unsaved = unsaved + 1
                end
            end
        end
    end

    if unsaved > 0 then
        local c = vim.fn.confirm(
            string.format("有 %d 个未保存的 buffer，回滚会覆盖它们。继续？", unsaved),
            "&Yes\n&No",
            2
        )
        if c ~= 1 then
            return
        end
    end

    if opts.confirm_rollback then
        local c = vim.fn.confirm("回滚到本轮开始前？会删除 agent 本轮新建的文件。", "&Yes\n&No", 2)
        if c ~= 1 then
            return
        end
    end

    local ok, err = run_rsync(snapshot.path, snapshot.cwd)
    if not ok then
        vim.notify("[pi-agent] 回滚失败: " .. tostring(err), vim.log.levels.ERROR)
        return
    end

    -- 被回滚掉且当前是 modified 的 buffer：用户已确认覆盖，强制从磁盘恢复，
    -- 否则 buffer 仍显示 agent 的版本，一保存就把回滚覆盖回去。
    for _, it in ipairs(bufs) do
        if vim.api.nvim_buf_is_valid(it.buf) then
            local after = file_fingerprint(it.name)
            if after ~= it.before and it.modified and after ~= nil then
                vim.api.nvim_buf_call(it.buf, function()
                    vim.cmd("silent! edit!")
                end)
            end
        end
    end
    -- 未修改的 buffer（以及被删除的文件）交给 checktime/autoread
    vim.cmd("checktime")

    vim.notify("[pi-agent] 已回滚到本轮开始前")
end

------------------------------------------------------------------------
-- pi event handlers（注册为 blocking，回调必须 return nil）
------------------------------------------------------------------------

--- 每轮对话开始前刷新快照（阻塞，保证 agent 动手前快照就位）
---
--- 注意：pi-agent.nvim 的 blocking 事件等待超时写死为 2500ms
--- （extension/dispatcher.ts 的 waitForEvent 默认值），大仓库 rsync 超过这个时间时
--- 扩展会提示 "Timed out waiting for blocking result"。这里保持阻塞是刻意的：
--- nvim 主循环被占住期间后续 tool RPC 会排队，快照仍然跑在 agent 改文件之前，
--- 只是 UI 会卡住 rsync 的时长。真要彻底解决需要上游放宽该超时。
function M._on_round_start()
    if not enabled or not snapshot then
        return nil
    end
    refresh()
    return nil
end

--- 每轮对话结束 hook：本轮有改动才进 codediff
function M._on_round_end()
    if not enabled or not snapshot_ready() then
        return
    end
    if not has_changes() then
        vim.notify("[pi-agent] 本轮无文件改动，跳过对比")
        return
    end
    vim.notify("[pi-agent] pi-agent round_end,will input codediff")
    M.review()
end

------------------------------------------------------------------------
-- setup
------------------------------------------------------------------------
function M.setup()
    cleanup_stale()

    -- 每轮对话的起止钩子
    pcall(function()
        local pi = require("pi-agent")
        -- 开始前建快照（阻塞，保证 agent 动手前快照就位）
        pi.on_blocking("before_agent_start", M._on_round_start)
        -- 结束后触发（非阻塞）
        pi.on("agent_settled", M._on_round_end)
    end)
end

return M
