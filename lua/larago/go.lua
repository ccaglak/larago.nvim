local ts = vim.treesitter
local tags = require("larago.tags")
local pop = require("larago.ui")
local trs = require("larago.treesitter")
local utils = require("larago.utils")

local sep = vim.uv.os_uname().sysname == "Windows_NT" and "\\" or "/"
local M = {}

-- Cache root directory
local root_dir = nil
local function get_root_dir()
  if not root_dir then
    root_dir = vim.fs.root(0, { ".git", "composer.json" }) or vim.uv.cwd()
  end
  return root_dir
end

-- Pre-compile patterns
local INCLUDE_PATTERN = [[include%('([^']+)]]
local LIVEWIRE_PATTERN = [[livewire%('([^']+)]]

-- Buffer-local tag cache
local tag_cache = {}
local function check_tag(tag_name)
  if tag_cache[tag_name] == nil then
    tag_cache[tag_name] = tags:contains(tag_name)
  end
  return tag_cache[tag_name]
end



vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function(event)
    if event.match:match('^%w%w+://') then return end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
  end,
})

M.parsed_dir = function(file)
  local rd = get_root_dir()
  local path = rd .. sep .. "resources" .. sep .. "views" .. sep
  if #file == 1 then return path end

  for i, value in pairs(file) do
    if i < #file then
      path = path .. value .. sep
    end
  end
  return path
end

local function rg_search(pattern, path)
  local output = vim.system({
    "rg",
    "-g",
    pattern .. ".blade.php",
    "--files",
    path
  }):wait()

  return vim.split(output.stdout, "\n")
end

-- Update rgSearch to handle the new output format
M.rgSearch = function(path, file)
  local result = rg_search(file, path)
  return result[1] -- Return first match
end

-- Update rgcSearch to use the new search function
M.rgcSearch = function(file)
  local rd = get_root_dir()
  return rg_search(file, rd .. sep .. "resources")
end

local node_handlers = {
  function_call_expression = function(node) M.view(node) end,
  member_call_expression = function(node) M.route_name(node) end,
  self_closing_tag = function(node) M.tag(node) end,
  tag_name = function(node) M.tag(node) end,
  text = function() M.include() end,
  nowdoc_string = function(node) M.nowdoc(node) end,
  start_tag = function(node)
    local _, name_node = trs.children(node, "tag_name")
    M.tag(name_node)
  end
}

M.to = function()
  if not vim.bo.filetype then return end
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
    if node then
      local handler = node_handlers[node:type()]
      if handler then
        handler(node)
        break
      end
    end
  end
end

M.nowdoc = function(node)
  local line = trs.get_name(node)
  if not line then return end
  M.include(line)
end

M._toBlade = function(txt)
  local split = utils.spliter(txt)
  local path = M.parsed_dir(split)
  local bladeFile = M.rgSearch(path, split[#split])

  if bladeFile then
    vim.cmd("e " .. vim.fn.fnameescape(bladeFile))
    return
  end
  vim.cmd("e " .. vim.fn.fnameescape(path .. split[#split] .. ".blade.php"))
end

M.search = function(search)
  local rc = M.rgcSearch(search)
  if #rc > 1 then
    vim.schedule(function()
      pop.popup(rc)
    end)
    return
  end
  vim.cmd("e " .. vim.fn.fnameescape(unpack(rc)))
end

M.include = function(line)
  line = line or vim.api.nvim_get_current_line()
  local txt = string.match(line, INCLUDE_PATTERN)
  if not txt then
    txt = string.match(line, LIVEWIRE_PATTERN)
    if not txt then return end
    local split = utils.spliter(txt)
    M.search(split[#split])
    return
  end
  M._toBlade(txt)
end

M.route_name = function(node)
  if vim.bo.filetype ~= "php" then return end
  local fn = trs.get_name(trs.child(node, "name"))
  if fn == "name" then
    local arg = trs.child(node, "arguments")
    local val = trs.children(arg, "argument")
    if not val then return end
    val = val:gsub("'", "")
    M._toBlade(val)
  end
end

M.view = function(node)
  if vim.bo.filetype ~= "php" then return end
  local fn = trs.get_name(trs.child(node, "function"))
  if fn == "view" then
    local arg = trs.child(node, "arguments")
    local val = trs.children(arg, "argument")
    if not val then return end
    val = val:gsub("'", "")
    M._toBlade(val)
  end
end

M.tag = function(node)
  if vim.bo.filetype ~= "html" then return end

  local cmp = ts.get_node_text(node, 0, {})
  if not cmp then return end

  if check_tag(cmp) then
    vim.notify_once("Native HTML Tag")
    return
  end

  local nt = node:next_sibling()
  local att = trs.get_name(nt)

  if cmp:find(":", 1, true) then
    local scmp = utils.spliter(cmp, ":")
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
    vim.schedule(function()
      pop.popup(rc)
    end)
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
