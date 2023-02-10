vim.api.nvim_create_user_command("GoBlade", require("larago").go, {})
vim.filetype.add({
    extension = {
        html = "blade.php"
    },
})
