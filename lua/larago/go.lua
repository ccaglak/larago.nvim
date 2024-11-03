local ts = vim.treesitter
local tags = require("larago.tags")
local pop = require("larago.ui")
local trs = require("larago.treesitter")
local utils = require("larago.utils")

-- Cache system variables
local cache = {
  root_dir = nil,
  tags = {},
  sep = vim.uv.os_uname().sysname == "Windows_NT" and "\\" or "/"
}

-- Patterns compiled once
local PATTERNS = {
  include = [=[include%(['"]([^'"]+)['"])]=],
  livewire = [=[livewire%(['"]([^'"]+)['"])]=],
  component = [=[component%(['"]([^'"]+)['"])]=]
}

local function get_root_dir()
  if not cache.root_dir then
    cache.root_dir = vim.fs.root(0, { ".git", "composer.json" }) or vim.uv.cwd()
  end
  return cache.root_dir
end

local function check_tag(tag_name)
  if cache.tags[tag_name] == nil then
    cache.tags[tag_name] = tags:contains(tag_name)
  end
  return cache.tags[tag_name]
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

local M = {}

M.parsed_dir = function(file)
  local path = get_root_dir() .. cache.sep .. "resources" .. cache.sep .. "views" .. cache.sep
  if #file == 1 then return path end

  for i, value in ipairs(file) do
    if i < #file then
      path = path .. value .. cache.sep
    end
  end
  return path
end

M.rgSearch = function(path, file)
  return (rg_search(file, path))[1]
end

M.rgcSearch = function(file)
  return rg_search(file, get_root_dir() .. cache.sep .. "resources")
end

M._toBlade = function(txt)
  local split = utils.spliter(txt)
  local path = M.parsed_dir(split)
  local bladeFile = M.rgSearch(path, split[#split])

  local target = bladeFile or (path .. split[#split] .. ".blade.php")
  vim.cmd("e " .. vim.fn.fnameescape(target))
end

M.search = function(search)
  local results = M.rgcSearch(search)
  if #results > 1 then
    vim.schedule(function() pop.popup(results) end)
    return
  end
  vim.cmd("e " .. vim.fn.fnameescape(results[1]))
end

local node_handlers = {
  function_call_expression = function(node)
    if vim.bo.filetype ~= "php" then return end
    local fn = trs.get_name(trs.child(node, "function"))
    if fn == "view" then
      local val = trs.children(trs.child(node, "arguments"), "argument")
      if val then M._toBlade(val:gsub("'", "")) end
    end
  end,

  member_call_expression = function(node)
    if vim.bo.filetype ~= "php" then return end
    local fn = trs.get_name(trs.child(node, "name"))
    if fn == "name" then
      local val = trs.children(trs.child(node, "arguments"), "argument")
      if val then M._toBlade(val:gsub("'", "")) end
    end
  end,

  tag = function(node)
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
        M.search(utils.spliter(att, ".")[#utils.spliter(att, ".")])
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

    local results = M.rgcSearch(search)
    if #results > 1 then
      vim.schedule(function() pop.popup(results) end)
      return
    elseif #results == 0 then
      M.search(split[#split - 1] .. "-" .. split[#split])
      return
    end
    vim.cmd("e " .. vim.fn.fnameescape(results[1]))
  end
}

M.to = function()
  if not vim.bo.filetype then return end
  utils.filetype()

  for _, node_type in ipairs({
    "function_call_expression",
    "member_call_expression",
    "tag_name",
    "self_closing_tag",
    "text",
    "nowdoc_string",
    "start_tag"
  }) do
    local node = trs.parent(node_type)
    if node then
      local handler = node_handlers[node:type()]
      if handler then
        handler(node)
        break
      end
    end
  end
end

M.include = function(line)
  line = line or vim.api.nvim_get_current_line()
  local txt = line:match(PATTERNS.include) or line:match(PATTERNS.livewire)
  if not txt then return end

  if line:match(PATTERNS.livewire) then
    M.search(utils.spliter(txt)[#utils.spliter(txt)])
  else
    M._toBlade(txt)
  end
end

-- Create directories automatically when saving files
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function(event)
    if event.match:match('^%w%w+://') then return end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
  end,
})

return M
