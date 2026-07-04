-- 全局 snippet，对所有 filetype 生效
-- 按 filetype 新建文件，例如 lua.lua / python.lua

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
    s("hello", {
        t("Hello, "),
        i(1, "world"),
        t("!"),
    }),

    s("date", {
        t(os.date("%Y-%m-%d")),
    }),

    s("todo", {
        t("-- TODO: "),
        i(1, "fixme"),
    }),

    s(
        "fn",
        fmt(
            [[
        function {}({})
          {}
        end]],
            {
                i(1, "name"),
                i(2, "args"),
                i(0, "-- todo"),
            }
        )
    ),

    s(
        "if",
        fmt(
            [[
        if {} then
          {}
        end]],
            {
                i(1, "cond"),
                i(0, "-- body"),
            }
        )
    ),
}
