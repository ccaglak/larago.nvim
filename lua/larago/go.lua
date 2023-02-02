local ts = vim.treesitter
local Job = require("plenary.job")
local tags = require("larago.tags")
local pop = require("larago.ui")
local rt = require("larago.root")
local trs = require("larago.treesitter")
local utils = require("larago.utils")

local sep = utils.path_sep()

local M = {}

-- note to self camelcase vs snakecase
M.parsed_dir = function(file)
    local rd = rt.root_dir()
    local path = rd .. sep .. "resources" .. sep .. "views" .. sep
    if #file == 1 then
        path = path
    else
        for i, value in pairs(file) do
            if i < #file then
                path = path .. value .. sep
            end
        end
    end
    return path
end

M.rgSearch = function(path, file)
    local rg = Job:new({
        command = "rg",
        args = { "-g", file .. ".blade.php", "--files", path },
    })
    rg:sync()
    return unpack(rg:result())
end


M.rgcSearch = function(file)
    local rd = rt.root_dir()
    local rg = Job:new({
        command = "rg",
        -- rg -g 'Route.php' --files ./
        args = { "-g", file .. ".blade.php", "--files", rd .. sep .. "resources" },
    })
    rg:sync()
    return rg:result()
end

M.to = function()
    utils.filetype()
    local node = nil
    for _, value in pairs({ "function_call_expression", "tag_name", "text", "nowdoc_string" }) do
        node = trs.parent(value)
        if node ~= nil then
            local type = node:type()
            if type == "function_call_expression" then
                M.view(node)
                break
            elseif type == "tag_name" then
                M.tag(node)
                break
            elseif type == "text" then
                M.include()
                break
            elseif type == "nowdoc_string" then
                M.nowdoc(node)
                break
            end
        end
    end
end

local spliter = function(path, sepa)
    sepa = sepa or "."
    local format = string.format("([^%s]+)", sepa)
    local t = {}
    for str in string.gmatch(path, format) do
        table.insert(t, str)
    end
    return t
end

M.nowdoc = function(node)
    local line = trs.get_name(node)
    M.include(line)
end

M.include = function(line)
    line = line or vim.api.nvim_get_current_line()
    local txt = string.match(line, [[include%('([^']+)]])
    if txt == nil then
        txt = string.match(line, [[livewire%('([^']+)]])
        local split = spliter(txt)
        local rc = M.rgcSearch(split[#split])
        if #rc > 1 then
            pop.popup(rc)
            return
        end
    end
    local split = spliter(txt)
    local path = M.parsed_dir(split)
    local bladeFile = M.rgSearch(path, split[#split])
    vim.cmd("e " .. vim.fn.fnameescape(bladeFile))
end

M.view = function(node)
    local fn = trs.get_name(trs.child(node, "function"))
    if fn == "view" then
        local arg = trs.child(node, "arguments")
        local val = trs.children(arg, "argument")
        val = val:gsub("'", "")
        local split = spliter(val)
        local path = M.parsed_dir(split) -- need some refactoring
        local bladeFile = M.rgSearch(path, split[#split])
        if bladeFile ~= nil then
            vim.cmd("e " .. vim.fn.fnameescape(bladeFile))
            return
        end
        vim.cmd("e " .. vim.fn.fnameescape(path .. split[#split] .. ".blade.php"))
    end
end

M.tag = function(node)
    local cmp = ts.query.get_node_text(node, 0, {}) -- empty brackets are important
    if tags:contains(cmp) then
        vim.api.nvim_echo({ { "Native Html Tag", "Function" }, { " " } }, true, {})
        return
    end
    local split = spliter(cmp,'-')
    local rc = M.rgcSearch(split[#split])
    if #rc > 1 then
        pop.popup(rc)
        return
    end
    vim.cmd("e " .. vim.fn.fnameescape(unpack(rc)))
end

return M
