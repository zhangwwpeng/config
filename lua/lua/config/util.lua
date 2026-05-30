------------------------------------------------------------------------
-- Global function for stateline
------------------------------------------------------------------------
function _G.current_tab_name()
    return vim.t[vim.fn.tabpagenr()].name or ("Tab " .. vim.fn.tabpagenr())
end

function _G.current_macro_status()
    local reg = vim.fn.reg_recording()
    if reg ~= "" then
        return "recording @" .. reg
    else
        return ""
    end
end
