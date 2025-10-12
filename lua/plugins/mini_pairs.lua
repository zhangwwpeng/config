return {
    -- Auto pairs
    -- Automatically inserts a matching closing character
    -- when you type an opening character like `"`, `[`, or `(`.
    {
        "nvim-mini/mini.pairs",
        event = "VeryLazy",
        opts = {
            modes = { insert = true, command = true, terminal = false },
            -- skip autopair when next character is one of these
            skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
            -- skip autopair when next character is closing pair
            -- and there are more closing pairs than opening pairs
            skip_unbalanced = true,
            -- better deal with markdown code blocks
            markdown = true,
            mappings = {
                ["`"] = false,
            },
        },
    },
}
