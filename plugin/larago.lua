vim.api.nvim_create_user_command("GoBlade", require("larago").go, {})
if not vim.uv then
	vim.uv = vim.loop
end
