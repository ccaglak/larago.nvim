local ts = vim.treesitter
local Job = require("plenary.job")
local tags = require("larago.tags")
local pop = require("larago.ui")
local rt = require("larago.root")
local trs = require("larago.treesitter")
local utils = require("larago.utils")

local sep = utils.path_sep()

local M = {}

vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function(event)
        if event.match:match('^%w%w+://') then
            return
        end
        local file = vim.uv.fs_realpath(event.match) or event.match
        vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
    end,
})

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

-- ripgrep local search
M.rgSearch = function(path, file)
    local rg = Job:new({
        command = "rg",
        args = { "-g", file .. ".blade.php", "--files", path },
    })
    rg:sync()
    return unpack(rg:result())
end

-- ripgrep resources search
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
    for _, value in pairs({
        "function_call_expression",
        "member_call_expression",
        "tag_name",
        "self_closing_tag",
        "text",
        "nowdoc_string",
        "start_tag",
    }) do
        local node = trs.parent(value)
        if node ~= nil then
            local type = node:type()
            if type == "function_call_expression" then
                M.view(node)
                break
            elseif type == "member_call_expression" then
                M.route_name(node)
                break
            elseif type == "self_closing_tag" or type == "tag_name" then
                M.tag(node)
                break
            elseif type == "text" then
                M.include()
                break
            elseif type == "nowdoc_string" then
                M.nowdoc(node)
                break
            elseif type == "start_tag" then
                _, node = trs.children(node, "tag_name")
                M.tag(node)
                break
            end
        end

    end
end

M.nowdoc = function(node)
    local line = trs.get_name(node)
    if line == nil then
        return
    end
    M.include(line)
end

M._toBlade = function(txt)
    local split = utils.spliter(txt)
    local path = M.parsed_dir(split)
    local bladeFile = M.rgSearch(path, split[#split])
    if bladeFile ~= nil then
        vim.cmd("e " .. vim.fn.fnameescape(bladeFile))
        return
    end
    vim.cmd("e " .. vim.fn.fnameescape(path .. split[#split] .. ".blade.php"))
end

M.search = function(search)
    local rc = M.rgcSearch(search)
    if #rc > 1 then
        pop.popup(rc)
        return
    end
    vim.cmd("e " .. vim.fn.fnameescape(unpack(rc)))
end

M.include = function(line)
    line = line or vim.api.nvim_get_current_line()
    local txt = string.match(line, [[include%('([^']+)]])
    if txt == nil then
        txt = string.match(line, [[livewire%('([^']+)]])
        if txt == nil then
            return
        end
        local split = utils.spliter(txt)
        M.search(split[#split])
        return
    end
    M._toBlade(txt)
end

M.route_name = function(node)
    if vim.bo.filetype ~= "php" then
        return
    end
    local fn = trs.get_name(trs.child(node, "name"))
    if fn == "name" then
        local arg = trs.child(node, "arguments")
        local val = trs.children(arg, "argument")
        if val == nil then
            return
        end
        val = val:gsub("'", "")
        M._toBlade(val)
    end
end

M.view = function(node)
    if vim.bo.filetype ~= "php" then
        return
    end
    local fn = trs.get_name(trs.child(node, "function"))
    if fn == "view" then
        local arg = trs.child(node, "arguments")
        local val = trs.children(arg, "argument")
        if val == nil then
            return
        end
        val = val:gsub("'", "")
        M._toBlade(val)
    end
end

-- this needs to be rewritten
M.tag = function(node)
    if vim.bo.filetype ~= "html" then
        return
    end

    local cmp = ts.get_node_text(node, 0, {}) -- empty brackets are important
    if cmp == nil then
        return
    end
    if tags:contains(cmp) then
        vim.notify_once("Native HTML Tag")
        return
    end

    local nt = node:next_sibling()
    local att = trs.get_name(nt)

    if cmp:find(":", 1, true) then
        local scmp = utils.spliter(cmp, ":")
        dd(scmp)

        if att:find(".", 1, true) then
            local split = utils.spliter(att, ".")
            M.search(split[#split])
            return
        end
        M.search(scmp[#scmp])
        return
    end

    local split = utils.spliter(cmp, "-")
    local search = split[#split]

    if search == "layouts" or search == "layout" then
        search = split[#split - 1]
    end
    if #split > 3 then
        search = split[#split - 1] .. "-" .. split[#split]
    end
    local rc = M.rgcSearch(search)

    if #rc > 1 then
        pop.popup(rc)
        return
    end

    if #rc == 0 then
        search = split[#split - 1] .. "-" .. split[#split]
        M.search(search)
        return
    end

    vim.cmd("e " .. vim.fn.fnameescape(unpack(rc)))
end

return M
