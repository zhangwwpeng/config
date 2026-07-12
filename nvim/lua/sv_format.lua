local M = {}

local function ok(done, did_edit)
    if done then
        done(nil, did_edit or false)
    end
end

local function fail(done, err)
    if done then
        done(err, false)
    end
end

local ts = vim.treesitter
local api = vim.api

local function build_query_from_node_types(node_types)
    local captures = {}
    for _, node_type in ipairs(node_types or {}) do
        captures[#captures + 1] = string.format("(%s) @target", node_type)
    end
    return table.concat(captures, "\n")
end

local function collect_nodes(bufnr, language, node_types)
    local parser = ts.get_parser(bufnr, language)
    local tree = parser:parse()[1]
    if not tree then
        return {}
    end

    local root = tree:root()
    local query_str = build_query_from_node_types(node_types)
    if query_str == "" then
        return {}
    end

    local ok_query, query = pcall(ts.query.parse, language, query_str)
    if not ok_query then
        return {}
    end

    local nodes = {}
    for _, node in query:iter_captures(root, bufnr, 0, -1) do
        nodes[#nodes + 1] = node
    end
    return nodes
end

local function format_module(bufnr)
    local spec = {
        language = "systemverilog",
        node_types = {
            "parameter_declaration",
            "ansi_port_declaration",
            "local_parameter_declaration",
            "net_declaration",
            "data_declaration",
            "list_of_parameter_value_assignments",
            "list_of_port_connections",
        },
        align_col = 48,
        target_col = 80,
    }
    local has_parser = pcall(ts.get_parser, bufnr, spec.language)
    if not has_parser then
        return false
    end

    local parser = ts.get_parser(bufnr, spec.language)
    local tree = parser:parse()[1]
    if not tree then
        return false
    end

    local root = tree:root()
    local has_module_declaration = false
    for child in root:iter_children() do
        if child:type() == "module_declaration" then
            has_module_declaration = true
            break
        end
    end
    if not has_module_declaration then
        return false
    end

    local nodes = collect_nodes(bufnr, spec.language, spec.node_types)
    if #nodes == 0 then
        return false
    end

    vim.notify("start format", vim.log.levels.INFO)

    local list_del_node_types = {
        list_of_param_assignments = true,
        list_of_variable_decl_assignments = true,
        list_of_net_decl_assignments = true,
    }

    local list_inst_node_types = {
        named_parameter_assignment = true,
        named_port_connection = true,
    }

    local edits = {}
    local function push_edit(sr, sc, er, ec, text)
        edits[#edits + 1] = {
            sr = sr,
            sc = sc,
            er = er,
            ec = ec,
            text = text,
        }
    end

    local function build_aligned_text(node)
        local lsr, lsc, ler, lec = node:range()
        if lsc >= (spec.align_col + 1) then
            return nil
        end

        local node_text = ts.get_node_text(node, bufnr)
        if type(node_text) ~= "string" then
            return nil
        end

        local left_pad = math.max(0, spec.align_col - lsc)
        local eq_idx = node_text:find("=")
        if eq_idx then
            local lhs = node_text:sub(1, eq_idx - 1):gsub("%s+$", "")
            local rhs = node_text:sub(eq_idx + 1):gsub("^%s*", "")
            local spaces_before_eq = math.max(1, spec.target_col - (lsc + left_pad + #lhs))
            return {
                sr = lsr,
                sc = lsc,
                er = ler,
                ec = lec,
                text = string.rep(" ", left_pad) .. lhs .. string.rep(" ", spaces_before_eq) .. "= " .. rhs,
            }
        end

        local right_pad = math.max(0, spec.target_col - (lec + left_pad))
        local line = api.nvim_buf_get_lines(bufnr, lsr, lsr + 1, false)[1] or ""
        if lec >= #line then
            right_pad = 0
        end
        return {
            sr = lsr,
            sc = lsc,
            er = ler,
            ec = lec,
            text = string.rep(" ", left_pad) .. node_text .. string.rep(" ", right_pad),
        }
    end

    local function swap_packed_dimension(node)
        local function find_descendant_by_type(root, target_type)
            if root:type() == target_type then
                return root
            end
            for child in root:iter_children() do
                local found = find_descendant_by_type(child, target_type)
                if found then
                    return found
                end
            end
            return nil
        end

        local packed = find_descendant_by_type(node, "packed_dimension")
        if not packed then
            return nil
        end

        local psr, psc, per, pec = packed:range()
        if psr ~= per then
            return nil
        end

        local constant_range = find_descendant_by_type(packed, "constant_range")
        local constant_expression = find_descendant_by_type(packed, "constant_expression")
        if not constant_range or not constant_expression then
            return nil
        end

        local crsr, crsc = constant_range:range()
        local cesr, _, ceer, ceec = constant_expression:range()
        if psr ~= crsr or psr ~= cesr or ceer ~= psr then
            return nil
        end

        local line = api.nvim_buf_get_lines(bufnr, psr, psr + 1, false)[1] or ""
        local packed_text = line:sub(psc + 1, pec)
        if packed_text:sub(1, 1) ~= "[" then
            return nil
        end

        local idx_crs = crsc - psc + 1
        local idx_cee = ceec - psc
        if idx_crs <= 2 or idx_cee < idx_crs then
            return nil
        end

        local gap = packed_text:sub(2, idx_crs - 1)
        if gap == "" or not gap:match("^%s+$") then
            return nil
        end

        local moved_spaces = #gap
        local before = packed_text:sub(1, 1)
        local expr_part = packed_text:sub(idx_crs, idx_cee)
        local after_expr = packed_text:sub(idx_cee + 1)
        local new_text = before .. expr_part .. string.rep(" ", moved_spaces) .. after_expr

        if new_text == packed_text then
            return nil
        end

        return {
            sr = psr,
            sc = psc,
            er = per,
            ec = pec,
            text = new_text,
        }
    end

    local function build_inst_port_text(node)
        local lsr, lsc, ler, lec = node:range()
        if lsr ~= ler then
            return nil
        end

        local node_text = ts.get_node_text(node, bufnr)
        if type(node_text) ~= "string" or node_text == "" then
            return nil
        end

        local open_idx = node_text:find("%(")
        local close_idx = open_idx and node_text:match(".*()%)") or nil
        if not open_idx or not close_idx then
            return nil
        end

        local inner_text = node_text:sub(open_idx + 1, close_idx - 1)
        inner_text = inner_text:gsub("^%s*", ""):gsub("%s*$", "")

        local open_col = lsc + open_idx - 1
        local close_col = lsc + close_idx - 1
        local left_pad = math.max(0, 41 - open_idx)
        local right_pad = math.max(0, (79 + lsc) - (close_col + left_pad))
        return {
            sr = lsr,
            sc = open_col,
            er = ler,
            ec = close_col + 1,
            text = string.rep(" ", left_pad) .. "( " .. inner_text .. string.rep(" ", right_pad) .. ")",
        }
    end

    for _, node in ipairs(nodes) do
        local sr, sc, er, _ = node:range()
        for child, field in node:iter_children() do
            if list_inst_node_types[child:type()] then
                local edit = build_inst_port_text(child)
                if edit then
                    push_edit(edit.sr, edit.sc, edit.er, edit.ec, edit.text)
                end
            elseif sr == er and sc == 4 and (list_del_node_types[child:type()] or field == "port_name") then
                local edit = build_aligned_text(child)
                if edit then
                    push_edit(edit.sr, edit.sc, edit.er, edit.ec, edit.text)
                end
            end
        end
        -- local edit = swap_packed_dimension(node)
        -- if edit then
        --     push_edit(edit.sr, edit.sc, edit.er, edit.ec, edit.text)
        -- end
    end

    if #edits == 0 then
        return false
    end

    table.sort(edits, function(a, b)
        if a.sr ~= b.sr then
            return a.sr > b.sr
        end
        return a.sc > b.sc
    end)

    for _, edit in ipairs(edits) do
        api.nvim_buf_set_text(bufnr, edit.sr, edit.sc, edit.er, edit.ec, { edit.text })
    end

    return true
end

function M.format(opts, done)
    opts = opts or {}
    local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return fail(done, "invalid bufnr")
    end

    local ft = vim.bo[bufnr].filetype
    if ft ~= "systemverilog" and ft ~= "verilog" and ft ~= "sv" then
        return ok(done, false)
    end

    local success, did_edit_or_err = pcall(format_module, bufnr)
    if not success then
        return fail(done, did_edit_or_err)
    end

    return ok(done, did_edit_or_err)
end

return M
