-- 语言限定的高亮覆盖：@<capture>.<lang>
--
-- 原理（nvim runtime/lua/vim/treesitter/highlighter.lua:43）：
--   高亮器查组时永远先查 "@" .. capture .. "." .. tree语言，例如 markdown 里的
--   (atx_h1_marker) @markup.heading.1  →  "@markup.heading.1.markdown"
--   这个组没定义时才回退到 "@markup.heading.1" → 再回退到标准组。
-- 所以 "@xxx.markdown" 是官方支持的写法，比覆盖全局 @xxx 更精准：
-- 只影响 markdown，代码注释里的 @markup.* 不受牵连。
--
-- 注意：colors/bamboo.lua 开头会 `hi clear`，所以必须在 ColorScheme 之后重新设一遍。

local M = {}

-- key = treesitter 语言名（注入语言也算，例如 fenced code block 里的是代码本身的语言）
local overrides = {
    markdown = {
        -- 标题 1-6（(paragraph) 与 atx_hN_marker 都带这个 capture）
        ["@markup.heading.1"] = { fg = "#e6a05a", bold = true },
        ["@markup.heading.2"] = { fg = "#d8b47a", bold = true },
        ["@markup.heading.3"] = { fg = "#c9bf8e", bold = true },

        ["@markup.quote"] = { fg = "#928374", italic = true },
        ["@markup.list"] = { fg = "#83a598" },
        ["@markup.list.checked"] = { fg = "#a8c982" },
        ["@markup.list.unchecked"] = { fg = "#928374" },

        -- 围栏代码块整体（内部会被注入语言再覆盖一层）
        ["@markup.raw.block"] = { bg = "#2a3029" },

        -- 引用式链接定义行 [foo]: https://...
        ["@markup.link.url"] = { fg = "#83a598", underline = true },
    },

    markdown_inline = {
        ["@markup.strong"] = { fg = "#e6a05a", bold = true },
        ["@markup.italic"] = { fg = "#e49cb1", italic = true },
        ["@markup.strikethrough"] = { fg = "#928374", strikethrough = true },
        ["@markup.raw"] = { fg = "#a8c982", bg = "#30352d" }, -- 行内 `code`
        ["@markup.link.url"] = { fg = "#83a598", underline = true },
        ["@markup.link.label"] = { fg = "#9bbcb5" },
        ["@string.escape"] = { fg = "#e75a7c" }, -- \* \_ 之类
    },

    -- ```diff 代码块里注入的语言是 diff，不是 markdown
    diff = {
        ["@diff.plus"] = { fg = "#a8c982" },
        ["@diff.minus"] = { fg = "#e75a7c" },
        ["@diff.delta"] = { fg = "#83a598" },
    },
}

--- 直接设置/新增一组覆盖，例如 require("hl_extra").add("lua", { ["@variable"] = { fg = "#fff" } })
---@param lang string
---@param groups table<string, vim.api.keyset.highlight>
function M.add(lang, groups)
    overrides[lang] = overrides[lang] or {}
    for name, spec in pairs(groups) do
        overrides[lang][name] = spec
    end
end

--- 应用所有覆盖（幂等）
function M.apply()
    for lang, groups in pairs(overrides) do
        for name, spec in pairs(groups) do
            vim.api.nvim_set_hl(0, string.format("%s.%s", name, lang), spec)
        end
    end
end

--- 列出当前所有覆盖，方便 :lua require("hl_extra").list() 检查
function M.list()
    local out = {}
    for lang, groups in pairs(overrides) do
        for name in pairs(groups) do
            out[#out + 1] = string.format("%s.%s", name, lang)
        end
    end
    table.sort(out)
    print(table.concat(out, "\n"))
end

local registered = false

function M.setup()
    M.apply()
    if registered then
        return
    end
    registered = true
    -- :colorscheme 会先 hi clear 再设色，所以 ColorScheme 之后再补一遍
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("HLExtra", { clear = true }),
        callback = M.apply,
    })
end

return M
