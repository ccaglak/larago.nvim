local ts    = vim.treesitter
local tq    = require("vim.treesitter.query")
local Job   = require("plenary.job")
local tags  = require("larago.tags")
local pop   = require('larago.ui')
local rt    = require("larago.rootDir")
local trs   = require('larago.treesitter')
local utils = require('larago.utils')
local List  = require("plenary.collections.py_list")

local M = {}

-- vim.bo.filetype
-- vim.bo.filename

M.getRoot = function(language, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local parser = ts.get_parser(bufnr, language, {})
    local tree = parser:parse()[1]
    return tree:root(), bufnr
end

M.rgSearch = function(file)
    local rootDir = rt.rootDir()
    local path = "/resources/views/"
    if #file == 1 then
        path = path
    else

        for i, value in pairs(file) do
            if i < #file then
                path = path .. value .. "/"
            end
        end
    end
    P(path)
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
    utils.filetype()
    local node = nil
    for _, value in pairs({ 'function_call_expression', 'tag_name' }) do
        node = trs.parent(value)
        if node ~= nil then
            local type = node:type()
            if type == "function_call_expression" then
                M.view(node)
                break
            elseif type == "tag_name" then
                M.tag(node)
                break
            end
        end
    end
end

M.view = function(node)
    local fn = trs.get_name(trs.child(node, "function"))
    if fn == 'view' then
        local arg = trs.child(node, "arguments")
        local val = trs.children(arg, 'argument')
        local split = {}
        for word in val:gmatch("%w+") do table.insert(split, word) end
        local bladeFile = M.rgSearch(split)
        if bladeFile ~= nil then
            vim.cmd("e " .. vim.fn.fnameescape(bladeFile))
            return
        end
        vim.cmd("e " ..
            vim.fn.fnameescape(rt.rootDir() .. "/resources/views/" .. split[1] .. "/" .. split[2] .. ".blade.php"))
    end
end

M.tag = function(node)
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

return M
