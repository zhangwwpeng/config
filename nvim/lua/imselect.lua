------------------------------------------------------------------------
-- imselect — macOS 输入法切换
--
-- 依赖 im-select: brew install im-select
-- 按 <C-[> 时记录当前输入法并切到英文，
-- 进入 insert/terminal 时如果之前是中文输入法则恢复。
------------------------------------------------------------------------

local M = {}

M.sources = {
    en = "com.apple.keylayout.Australian",
    zh = "im.rime.inputmethod.Squirrel.Hans",
}

local last_im = nil

--- 获取当前输入法 ID
function M.current()
    local handle = io.popen("im-select 2>/dev/null")
    if not handle then
        return nil
    end
    local result = handle:read("*a")
    handle:close()
    return result:gsub("%s+$", "")
end

--- 切换到指定输入法
function M.switch(source)
    local id = M.sources[source] or source
    vim.fn.system("im-select " .. M.sources["en"]) -- mac os must set this
    vim.fn.system("im-select " .. id)
end

--- 当前输入法是否为中文
function M.is_zh(id)
    id = id or M.current()
    return id and id ~= M.sources.en
end

--- 记录当前输入法并切到英文
function M.to_en()
    last_im = M.current()
    if last_im == M.sources["zh"] then
        vim.notify("change to im-en", vim.log.levels.INFO)
        M.switch("en")
    end
end

--- 如果上次是中文输入法则恢复（先 en 后 zh 强制鼠须管重新激活）
function M.maybe_restore()
    if last_im == M.sources["zh"] then
        vim.notify("change to im-zh", vim.log.levels.INFO)
        vim.fn.system("im-select " .. M.sources.en .. " && im-select " .. M.sources.zh)
    end
end

--- 启用: 映射 <C-[> 切换输入法，进入 insert 时按需恢复
function M.setup()
    vim.keymap.set("i", "<C-[>", function()
        M.to_en()
        return "<Esc>"
    end, { expr = true })

    vim.keymap.set("t", "<C-[>", function()
        M.to_en()
        return "<C-\\><C-n>"
    end, { expr = true })

    vim.api.nvim_create_autocmd("InsertEnter", {
        callback = function()
            M.maybe_restore()
        end,
    })
end

return M
