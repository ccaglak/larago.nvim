local M = {}

M.spliter = function(path, sepa)
    sepa = sepa or "."
    local format = string.format("([^%s]+)", sepa)
    local t = {}
    for str in string.gmatch(path, format) do
        table.insert(t, str)
    end
    return t
end

M.filetype = function()
    local split = M.spliter(vim.fn.expand("%:t"), ".")

    if #split < 3 then
        return
    end
    local filetype = split[#split - 1] .. "." .. split[#split]
    if filetype == "blade.php" then
        vim.cmd([[setfiletype html]])
    end
end

function M.setFiletype(buffer, type)
    vim.api.nvim_buf_set_option(buffer, "filetype", type)
end

M.path_sep = function()
    local win = vim.loop.os_uname().sysname == "Darwin" or "Linux"
    return win and "/" or "\\"
end

return M
