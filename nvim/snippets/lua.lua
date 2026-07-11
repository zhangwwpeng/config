local ls = require("luasnip")
local extras = require("luasnip.extras")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local rep = extras.rep

return {
    s({ trig = "fun", name = "function" }, {
        t("local function "),
        i(1, "name"),
        t({ "()", "    " }),
        i(0),
        t({ "", "end" }),
    }),

    s({ trig = "gfun", name = "global function" }, {
        t("function _G."),
        i(1, "name"),
        t({ "()", "    " }),
        i(0),
        t({ "", "end" }),
    }),

    s({ trig = "if", name = "if condition" }, {
        t("if "),
        i(0),
        t({ " then", "end" }),
    }),

    s({ trig = "el", name = "else condition" }, {
        t("elseif "),
        i(0),
        t(" then"),
    }),

    s({ trig = "info", name = "print info" }, {
        t("vim.notify("),
        i(0),
        t(", vim.log.levels.INFO)"),
    }),

    s({ trig = "error", name = "print error" }, {
        t("vim.notify("),
        i(0),
        t(", vim.log.levels.ERROR)"),
    }),

    s({ trig = "warn", name = "print warn" }, {
        t("vim.notify("),
        i(0),
        t(", vim.log.levels.WARN)"),
    }),

    s({ trig = "pr", name = "print debug" }, {
        t("print("),
        i(0),
        t(")"),
    }),
}
