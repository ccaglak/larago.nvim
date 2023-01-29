local M = {}
M.cursor = function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local node = vim.treesitter.get_node_at_pos(0, row - 1, col, {})
    return node
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
                return vim.treesitter.query.get_node_text(node, 0)
            end
        end
    end
end

M.children = function(cnode, type)
    cnode = cnode or M.cursor()
    for node, _ in cnode:iter_children() do
        if node:type() == type then
            return vim.treesitter.query.get_node_text(node, 0)
        end
    end
end

return M

-
