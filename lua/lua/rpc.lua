local M = {}

-- ==================== 1. RPC 客户端 (Client) ====================
local Client = {}
Client.__index = Client

function Client.connect(pipe_path)
    local self = setmetatable({}, Client)
    -- 如果没传路径，自动去读取环境变量
    local target_pipe = pipe_path or vim.env.NVIM_RPC_PIPE

    if not target_pipe or target_pipe == "" then
        error("未找到有效的 RPC 管道路径，请确保 Server 已启动或传入了正确路径！")
    end

    -- 连接底层管道
    local chan_id = vim.fn.sockconnect("pipe", target_pipe, { rpc = true })
    if chan_id <= 0 then
        error("连接 RPC 服务端失败! 目标管道: " .. target_pipe)
    end

    self.chan_id = chan_id
    return self
end

-- 异步发送命令（发完即走，不阻塞）
function Client:send(func_name, ...)
    if not self.chan_id then
        return
    end
    vim.rpcnotify(self.chan_id, "nvim_exec_lua", "_G._my_rpc_server_hub(...)", { func_name, { ... } })
end

-- 同步请求命令（等待对端执行完）
function Client:request(func_name, ...)
    if not self.chan_id then
        return
    end
    return vim.rpcrequest(self.chan_id, "nvim_exec_lua", "return _G._my_rpc_server_hub(...)", { func_name, { ... } })
end

-- 断开连接
function Client:close()
    if self.chan_id then
        vim.fn.chanclose(self.chan_id)
        self.chan_id = nil
    end
end

return M
