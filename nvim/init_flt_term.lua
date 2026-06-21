require("remote_terminal")
require("theme").setup()

------------------------------------------------------------------------
-- RPC
------------------------------------------------------------------------
vim.api.nvim_create_autocmd("UIEnter", {
    once = true,
    callback = function()
        Father_chan = vim.fn.sockconnect("pipe", vim.g.pip_father, { rpc = true })
        vim.rpcnotify(
            Father_chan,
            "nvim_exec_lua",
            [[Flt_term_chan = vim.fn.sockconnect("pipe", vim.g.flt_term_servrename, { rpc = true })]],
            {}
        )
    end,
})
