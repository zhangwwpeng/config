-- 全局 snippet，对所有 filetype 生效
-- 按 filetype 新建文件，例如 lua.lua / python.lua

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
    s("date", {
        t(os.date("%Y-%m-%d")),
    }),

    s("todo", {
        t("-- TODO: "),
        i(1, "fixme"),
    }),
}
