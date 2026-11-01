-- 通用 treesitter 缩进：执行 queries/<lang>/indents.scm
-- 移植自 nvim-treesitter（master 分支）lua/nvim-treesitter/indent.lua，Apache-2.0
-- nvim 本体只有 indents.scm 的格式约定，没有执行它的 indentexpr，所以自带一份。
local M = {}

local COMMENT_PARSERS = { comment = true, jsdoc = true, phpdoc = true }
-- 新开一行时强制 reparse 反而更差的语言（nvim-treesitter 还列了 python，实测 python 不 reparse
-- 时树是旧的，括号内回车缩进会错，所以去掉）
local AVOID_FORCE_REPARSING = { html = true, yaml = true }

-- nvim-treesitter 自定义的谓词，c 的 indents.scm 用到（#not-kind-eq? 的 not- 前缀由 nvim 自动处理）
vim.treesitter.query.add_predicate("kind-eq?", function(match, _, _, pred)
    local nodes = match[pred[2]]
    if not nodes or #nodes == 0 then
        return true
    end
    local types = { unpack(pred, 3) }
    for _, node in ipairs(nodes) do
        if not vim.tbl_contains(types, node:type()) then
            return false
        end
    end
    return true
end, { force = true })

local CAPTURES = {
    "indent.auto",
    "indent.begin",
    "indent.end",
    "indent.dedent",
    "indent.branch",
    "indent.ignore",
    "indent.align",
    "indent.zero",
}

local function getline(lnum)
    return vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
end

local function get_first_node_at_line(root, lnum, col)
    col = col or vim.fn.indent(lnum)
    return root:descendant_for_range(lnum - 1, col, lnum - 1, col)
end

local function get_last_node_at_line(root, lnum, col)
    col = col or (#getline(lnum) - 1)
    return root:descendant_for_range(lnum - 1, col, lnum - 1, col)
end

local function node_length(node)
    local _, _, start_byte = node:start()
    local _, _, end_byte = node:end_()
    return end_byte - start_byte
end

---在 node 的直接子节点里找分隔符，并判断它是不是该行最后一个有效字符
local function find_delimiter(bufnr, node, delimiter)
    for child in node:iter_children() do
        if child:type() == delimiter then
            local linenr = child:start()
            local line = vim.api.nvim_buf_get_lines(bufnr, linenr, linenr + 1, false)[1]
            local _, end_col = child:end_()
            local escaped = delimiter:sub(1, 1):match("[%^%$%(%)%%%.%[%]%*%+%-%?]") and "%" .. delimiter or delimiter
            local trimmed = line:sub(end_col + 1):gsub("[%s" .. escaped .. "]*", "")
            return child, #trimmed == 0
        end
    end
end

-- 同一个 changedtick + root 只跑一次 query（一次回车可能连续调用好几次 indentexpr）
local cache = { key = nil, map = nil }

local function get_indents(bufnr, root, lang)
    local key = table.concat({ bufnr, vim.b[bufnr].changedtick, lang, root:id() }, ":")
    if cache.key == key then
        return cache.map
    end
    local map = {}
    for _, name in ipairs(CAPTURES) do
        map[name] = {}
    end
    local query = vim.treesitter.query.get(lang, "indents")
    if query then
        for id, node, metadata in query:iter_captures(root, bufnr) do
            local name = query.captures[id]
            if name:sub(1, 1) ~= "_" and map[name] then
                map[name][node:id()] = metadata or {}
            end
        end
    end
    cache.key, cache.map = key, map
    return map
end

function M.indent(lnum)
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
    if not ok or not parser then
        return -1
    end

    if not AVOID_FORCE_REPARSING[parser:lang()] then
        parser:parse() -- 可能是 indentkeys 触发的，先同步一下树
    end

    -- 找包住该行、范围最小且不是注释 parser 的那棵树（处理 injection）
    local root, lang_tree
    parser:for_each_tree(function(tstree, tree)
        if not tstree or COMMENT_PARSERS[tree:lang()] then
            return
        end
        local local_root = tstree:root()
        if vim.treesitter.is_in_node_range(local_root, lnum - 1, 0) then
            if not root or node_length(root) >= node_length(local_root) then
                root, lang_tree = local_root, tree
            end
        end
    end)
    if not root then
        return 0
    end

    local q = get_indents(bufnr, root, lang_tree:lang())
    local node
    if getline(lnum):match("^%s*$") then
        -- 空行（刚回车）：从上一个非空行的最后一个节点往上算
        local prevlnum = vim.fn.prevnonblank(lnum)
        local indent = vim.fn.indent(prevlnum)
        local prevline = vim.trim(getline(prevlnum))
        node = get_last_node_at_line(root, prevlnum, indent + #prevline - 1)
        if node:type():match("comment") then
            -- 行尾注释不算，退到注释前的最后一个节点
            local first_node = get_first_node_at_line(root, prevlnum, indent)
            local _, scol = node:range()
            if first_node:id() ~= node:id() then
                prevline = vim.trim(prevline:sub(1, scol - indent))
                node = get_last_node_at_line(root, prevlnum, indent + #prevline - 1)
            end
        end
        if q["indent.end"][node:id()] then
            node = get_first_node_at_line(root, lnum)
            -- python 这类靠缩进分块的语言，块不含尾部空行，空行处落到根节点，原版会直接给 0
            -- （比如 if 里 return 之后）。这种情况按"比上一行少一级"处理
            if node and node:id() == root:id() then
                return math.max(indent - vim.fn.shiftwidth(), 0)
            end
        end
    else
        node = get_first_node_at_line(root, lnum)
    end
    if not node then
        return -1
    end

    local indent_size = vim.fn.shiftwidth()
    local indent = 0
    local _, _, root_start = root:start()
    if root_start ~= 0 then
        indent = vim.fn.indent(root:start() + 1) -- injected tree
    end

    -- 同一行起始的多个节点只算一次缩进
    local is_processed_by_row = {}

    if q["indent.zero"][node:id()] then
        return 0
    end

    while node do
        local id = node:id()
        local begin = q["indent.begin"][id]

        -- @indent.auto：保持 autoindent
        if not begin and not q["indent.align"][id] and q["indent.auto"][id] and node:start() < lnum - 1 and lnum - 1 <= node:end_() then
            return -1
        end

        -- @indent.ignore 块内不缩进
        if not begin and q["indent.ignore"][id] and node:start() < lnum - 1 and lnum - 1 <= node:end_() then
            return 0
        end

        local srow, _, erow = node:range()
        local is_processed = false

        if
            not is_processed_by_row[srow]
            and ((q["indent.branch"][id] and srow == lnum - 1) or (q["indent.dedent"][id] and srow ~= lnum - 1))
        then
            indent = indent - indent_size
            is_processed = true
        end

        local should_process = not is_processed_by_row[srow]
        local is_in_err = false
        if should_process then
            local parent = node:parent()
            is_in_err = parent and parent:has_error() or false
        end

        -- 起止在同一行、且从目标行开始的节点不缩进
        if
            should_process
            and begin
            and (srow ~= erow or is_in_err or begin["indent.immediate"])
            and (srow ~= lnum - 1 or begin["indent.start_at_same_line"])
        then
            indent = indent + indent_size
            is_processed = true
        end

        if is_in_err and not q["indent.align"][id] then
            -- ERROR 节点：把第一个子节点上的 @indent.align 提到 ERROR 本身
            for c in node:iter_children() do
                if q["indent.align"][c:id()] then
                    q["indent.align"][id] = q["indent.align"][c:id()]
                    break
                end
            end
        end

        if should_process and q["indent.align"][id] and (srow ~= erow or is_in_err) and srow ~= lnum - 1 then
            local metadata = q["indent.align"][id]
            local o_delim_node, o_is_last_in_line
            local c_delim_node, c_is_last_in_line
            local indent_is_absolute = false
            if metadata["indent.open_delimiter"] then
                o_delim_node, o_is_last_in_line = find_delimiter(bufnr, node, metadata["indent.open_delimiter"])
            else
                o_delim_node = node
            end
            if metadata["indent.close_delimiter"] then
                c_delim_node, c_is_last_in_line = find_delimiter(bufnr, node, metadata["indent.close_delimiter"])
            else
                c_delim_node = node
            end

            if o_delim_node then
                local o_srow, o_scol = o_delim_node:start()
                local c_srow = c_delim_node and c_delim_node:start() or nil
                if o_is_last_in_line then
                    -- 开括号在行尾：悬挂缩进，按普通缩进处理
                    indent = indent + indent_size
                    if c_is_last_in_line and c_srow and c_srow < lnum - 1 then
                        indent = math.max(indent - indent_size, 0)
                    end
                else
                    -- 开括号后还有内容：对齐到括号后
                    if c_is_last_in_line and c_srow and o_srow ~= c_srow and c_srow < lnum - 1 then
                        indent = math.max(indent - indent_size, 0)
                    else
                        indent = o_scol + (metadata["indent.increment"] or 1)
                        indent_is_absolute = true
                    end
                end
                -- 闭括号所在行：避免和下一行同缩进（如函数参数）
                if
                    c_srow
                    and c_srow ~= o_srow
                    and c_srow == lnum - 1
                    and metadata["indent.avoid_last_matching_next"]
                    and indent <= vim.fn.indent(o_srow + 1) + indent_size
                then
                    indent = indent + indent_size
                end
                is_processed = true
                if indent_is_absolute then
                    return indent -- 绝对位置，不再叠加父节点
                end
            end
        end

        is_processed_by_row[srow] = is_processed_by_row[srow] or is_processed
        node = node:parent()
    end

    return indent
end

return M
