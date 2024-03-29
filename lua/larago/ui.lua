local popup = require("plenary.popup")
local rd = require("larago.root")

local M = {}

function table.map(list, fn)
	local r = {}
	for i, value in ipairs(list) do
		local new = fn(value, i)
		table.insert(r, new)
	end
	return r
end

local win, _ = nil, nil
local buf_nr
local function close_popup()
	vim.api.nvim_win_close(win, true)
end

local rootDir = rd.root_dir()
local selected = {}
function M.popup(results)
	selected = results
	buf_nr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf_nr, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf_nr, "filetype", "larago")
	local parsedir = table.map(results, function(v)
		return v:gsub(rootDir, "")
	end)
	vim.api.nvim_buf_set_lines(buf_nr, 0, -1, true, parsedir)
	vim.api.nvim_buf_set_option(buf_nr, "modifiable", false)
	local width = 70
	local height = 10
	local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
	local title = "PHPNamespace"

	win, _ = popup.create(buf_nr, {
		line = math.floor(((vim.o.lines - height) / 2) - 1),
		col = math.floor((vim.o.columns - width) / 2),
		minwidth = width,
		minheight = height,
		title = title,
		cursorline = true,
		focusable = true,
		borderchars = borderchars,
	})
	vim.api.nvim_win_set_option(win, "number", true)
	vim.api.nvim_win_set_option(win, "wrap", false)
	vim.api.nvim_buf_set_option(buf_nr, "bufhidden", "delete")
	vim.api.nvim_buf_set_keymap(buf_nr, "n", "q", ":q!<cr>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf_nr, "n", "<cr>", "<cmd>lua require('larago.ui').selectItem()<cr>", {})
end

local idx = nil
function M.selectItem()
	idx = vim.fn.line(".")
	local selectedline = selected[idx]
	close_popup()
	selected = {}
	vim.cmd("e " .. vim.fn.fnameescape(selectedline))
end

return M
