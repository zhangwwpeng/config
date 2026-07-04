local M = {}

local SNIPPETS_PATH = vim.fn.stdpath("config") .. "/snippets"

local function setup_config()
    local ls = require("luasnip")
    ls.config.set_config({
        history = true,
        updateevents = "TextChanged,TextChangedI",
        delete_check_events = "TextChanged",
    })
end

local function setup_keymaps()
    local function jump(direction)
        local ls = require("luasnip")
        if direction == 1 and ls.expandable() then
            ls.expand()
        elseif ls.jumpable(direction) then
            ls.jump(direction)
        end
    end

    -- <C-l> 展开 snippet / 跳到下一个占位符
    -- <C-h> 跳到上一个占位符
    vim.keymap.set({ "i", "s" }, "<C-;>", function()
        jump(1)
    end, { desc = "Snippet expand / forward" })
end

local function setup_snippets()
    require("luasnip.loaders.from_lua").lazy_load({
        paths = SNIPPETS_PATH,
    })
end

function M.setup()
    setup_config()
    setup_keymaps()
    setup_snippets()
end

return M
