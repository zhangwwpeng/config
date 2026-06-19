local M = {}

-- require("cmd_panel").registry_cmd({
--     cmd_name = "session save ",
--     desc = "save session to state ss",
--     cmd = function()
--         M.save()
--     end,
--     cmd_pre = function() end,
--     cmd_post = function() end,
-- })

---@class CmdPanelItem
---@field cmd_name string
---@field desc? string
---@field cmd fun()
---@field cmd_pre? fun()
---@field cmd_post? fun()

---@type CmdPanelItem[]
local cmd_table = {}

---@type table<string, CmdPanelItem>
local cmd_index = {}

---@param item CmdPanelItem
local function exec(item)
    item.cmd()
end

function M.setup()
    vim.keymap.set("n", "<C-p>", function()
        M.panel_pick()
    end, { desc = "Command panel pick" })
end

---@param cmd CmdPanelItem
function M.registry_cmd(cmd)
    cmd_table[#cmd_table + 1] = cmd
    cmd_index[cmd.cmd_name] = cmd
end

function M.panel_pick()
    vim.ui.select(cmd_table, {
        prompt = "Command: ",
        format_item = function(item)
            if item.desc and item.desc ~= "" then
                return item.cmd_name .. " │ " .. item.desc
            end
            return item.cmd_name
        end,
        preview_item = function(item)
            if item.desc and item.desc ~= "" then
                return { item.cmd_name, "", item.desc }
            end
            return { item.cmd_name }
        end,
    }, function(item)
        if item then
            exec(item)
        end
    end)
end

return M
