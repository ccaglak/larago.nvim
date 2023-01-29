local ts   = vim.treesitter
local tq   = require("vim.treesitter.query")
local Job  = require("plenary.job")
local tags = require("larago.tags")
local pop  = require('larago.ui')
local rt   = require("larago.rootDir")
local trs  = require('larago.treesitter')


local M = {}

M.root_patterns = { ".git", "lua", "vendor", "node_modules" }


M.getRoot = function(language, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local parser = ts.get_parser(bufnr, language, {})
    local tree = parser:parse()[1]
    return tree:root(), bufnr
end

M.getfunc = function()
    local root, bufnr = M.getRoot("php")
    local query = ts.parse_query(
        "php",
        [[
    (function_call_expression
        function: (name) @view (#eq? @view "view")
        arguments: (arguments (argument (string (string_value)@s)
    )))
    ]]
    )
    local func, text = nil, nil
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    for _, captures, _ in query:iter_matches(root, bufnr, row - 1, col) do
        func = tq.get_node_text(captures[1], bufnr)
        text = tq.get_node_text(captures[2], bufnr)

    end
    return func, text
end

M.rgSearch = function(file)
    local rootDir = rt.rootDir()
    local path = "/resources/views/"
    if #file == 1 then
        path = path
    else
        for _, value in pairs(file) do
            path = path .. value .. "/"
        end
    end
    local rg = Job:new({
        command = "rg",
        args = { "-g", file[1] .. '.blade.php', "--files", rootDir .. path },
    })
    rg:sync()
    return unpack(rg:result())
end

M.rgcSearch = function(file)
    local rootDir = rt.rootDir()
    local rg = Job:new({
        command = "rg",
        -- rg -g 'Route.php' --files ./
        args = { "-g", file .. '.blade.php', "--files", rootDir .. "/resources" },
    })
    rg:sync()
    return rg:result()
end


M.to = function()
    local fn, val = M.getfunc()
    if fn == "view" then
        local split = {}
        if val ~= nil then
            for word in val:gmatch("%w+") do table.insert(split, word) end
            local bladeFile = M.rgSearch(split)
            if bladeFile ~= nil then
                vim.cmd("e " .. vim.fn.fnameescape(bladeFile))
                return
            end
            vim.cmd("e " ..
                vim.fn.fnameescape(rt.rootDir() .. "/resources/views/" .. split[1] .. "/" .. split[2] .. ".blade.php"))
        end
    else -- change
        vim.cmd([[setfiletype html]]) -- blade
        local node = trs.parent('tag_name')
        local type = node:type()
        if type == "tag_name" then
            local cmp = ts.query.get_node_text(node, 0, {}) -- empty brackets are important
            if tags:contains(cmp) then
                vim.api.nvim_echo({ { "Native Html Tag", 'Function' }, { ' ' } }, true, {})
                return
            end
            local split = {}
            for word in cmp:gmatch("%w+") do table.insert(split, word) end
            local rc = M.rgcSearch(split[2])
            if #rc > 1 then
                pop.popup(rc)
                return
            end
            vim.cmd("e " .. vim.fn.fnameescape(unpack(rc)))
        end
    end
end

return M
