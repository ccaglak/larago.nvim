local ts, api = vim.treesitter, vim.api
local M = {}

M.getRoot = function(language, bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    local parser = ts.get_parser(bufnr, language, {})
    local tree = parser:parse()[1]
    return tree:root(), bufnr
end

M.cursor = function()
    local row, col = unpack(api.nvim_win_get_cursor(0))
    local node = ts.get_node({ buffer = 0, pos = { row - 1, col - 1 } })
    return node
end

M.get_name = function(node)
    node = node or M.cursor()
    return ts.get_node_text(node, 0, {}) -- empty brackets are important
end

M.parent = function(type)
    local node = M.cursor()
    while node and node:type() ~= type do
        node = node:parent()
    end
    return node
end

M.child = function(cnode, cname)
    cnode = cnode or M.cursor()
    for node, name in cnode:iter_children() do
        if node:named() then
            if name == cname then
                return node
            end
        end
    end
end

M.child_type = function(node, type)
    local id = 0
    local child = node:child(id)
    while child do
        if child:type() == type then
            break
        end
        child = node:child(id)
        id = id + 1
    end
    return child
end

M.children = function(cnode, type)
    cnode = cnode or M.cursor()
    for node, _ in cnode:iter_children() do
        if node:type() == type then
            return M.get_name(node), node --  perhaps returning node could be better idea
        end
    end
end

M.prev_sibling = function(cnode, type)
    cnode = cnode or M.cursor()
    for node, _ in cnode:prev_sibling() do
        if node:type() == type then
            return M.get_name(node), node --  perhaps returning node could be better idea
        end
    end
end

return M
