-- 在外部终端（kitty 等）里跑 omp，同时让 omp 通过 pi-agent 的 unix socket 接回 nvim：
--   * nvim 侧只起 socket server，不打开 pi-agent 浮窗
--   * 生成一个 /tmp 启动脚本 + 一个桥接 extension，命令复制到 + 寄存器
--   * omp 里仍然有 nvim_get_qflist / nvim_set_qflist / nvim_get_diagnostics
--
-- omp 没有 pi-agent.nvim 期望的 --session-id 参数（会直接 unknown flag），
-- 所以桥接 extension 先把 socket 名塞回 process.argv，再加载 pi-agent 自带的 extension。
local M = {}

local uv = vim.uv or vim.loop

local function notify(msg, level)
    vim.notify("[omp] " .. msg, level or vim.log.levels.INFO)
end

---@return string
local function extension_path()
    local found = vim.api.nvim_get_runtime_file("extension/pi-agent.ts", false)
    if #found > 0 then
        return found[1]
    end

    local fallback = vim.fs.joinpath(
        vim.fn.stdpath("data"),
        "site/pack/core/opt/pi-agent.nvim/extension/pi-agent.ts"
    )
    if uv.fs_stat(fallback) then
        return fallback
    end

    error("[omp] 找不到 pi-agent.nvim 的 extension/pi-agent.ts")
end

---起 socket server（不 open surface）；已有客户端连接时拒绝
---@return string? sock
---@return string? err
local function ensure_server()
    local Pi = require("pi-agent")

    if Pi.ready() then
        return nil, "pi-agent 已经连着客户端（浮窗或另一个外部 omp），先关掉再生成"
    end

    if Pi.server == nil then
        require("pi_agent_cfg").setup() -- Pi.setup()：注册 handler / tools，只配置 surface，不打开浮窗
        local utils = require("pi-agent.utils")
        local server = require("pi-agent.server")

        local session = utils.make_session_name()
        local sock = utils.get_socket_dir() .. "/" .. session .. ".sock"

        Pi.session_name = session
        Pi.socket_path = sock
        Pi.server = server.new(sock, Pi.on_connect, Pi.on_disconnect, Pi.on_message)
    end

    -- 外部模式：C-; 没有 nvim 浮窗可聚焦，agent.lua 靠这个标记静默
    Pi.omp_external = true
    return Pi.socket_path
end

---桥接 extension：把 socket 名塞回 process.argv，让 pi-agent 的 findSocket() 能定位 socket。
---omp 的 loader 只对入口 extension 解析 typebox 之类的裸 import，所以不能在这里 import
---pi-agent 的 extension；改成两个 -e 分别加载，桥接只负责改 argv。
---@param session string
---@return string path
local function write_bridge(session)
    local path = ("/tmp/omp-nvim-bridge-%s.ts"):format(session)
    local lines = {
        "const sock = process.env.PI_AGENT_SOCKET;",
        "if (sock) {",
        '\tconst parts = sock.split("/");',
        '\tconst name = (parts[parts.length - 1] || "").replace(/\\.sock$/, "");',
        '\tprocess.argv.push("--session-id", name);',
        "}",
        "",
        "export default function () {}",
        "",
    }
    vim.fn.writefile(lines, path)
    return path
end

---@param session string
---@param sock string
---@param bridge string
---@param ext string
---@return string path
local function write_script(session, sock, bridge, ext)
    local path = ("/tmp/omp-nvim-%s.sh"):format(session)
    local omp = vim.fn.exepath("omp")
    if omp == "" then
        omp = "omp"
    end

    local lines = {
        "#!/bin/sh",
        "cd " .. vim.fn.shellescape(vim.fn.getcwd(), 1) .. " || exit 1",
        "export PI_AGENT_SOCKET=" .. vim.fn.shellescape(sock, 1),
        "exec "
            .. vim.fn.shellescape(omp, 1)
            .. " -e "
            .. vim.fn.shellescape(bridge, 1)
            .. " -e "
            .. vim.fn.shellescape(ext, 1),
    }
    vim.fn.writefile(lines, path)
    uv.fs_chmod(path, tonumber("700", 8))
    return path
end

---生成外部 omp 的启动命令，复制到 + 寄存器
---@return string? cmd
function M.generate()
    local sock, err = ensure_server()
    if not sock then
        notify(err, vim.log.levels.WARN)
        return
    end

    local session = assert(require("pi-agent").session_name)
    local ext = extension_path()
    local bridge = write_bridge(session)
    local script = write_script(session, sock, bridge, ext)
    local cmd = "sh " .. vim.fn.shellescape(script, 1)

    local ok = pcall(vim.fn.setreg, "+", cmd)
    notify(
        ("%s：%s\n（socket %s）"):format(ok and "命令已复制到 + 寄存器" or "命令（剪贴板不可用）", cmd, sock)
    )
    return cmd
end

function M.setup()
    vim.api.nvim_create_user_command("OmpExternal", function()
        M.generate()
    end, { desc = "生成外部 omp 启动命令（接回 nvim quickfix/diagnostics）" })
end

return M
