local M = {}

M.filetype = function()
    local split = {}
    for f in vim.fn.expand('%:t'):gmatch("%w+") do table.insert(split, f) end
    if #split < 3 then return end -- TODO got to find better way detect blade files
    local filetype = split[2] .. '.' .. split[3]
    if filetype == 'blade.php' then
        vim.cmd([[setfiletype html]])
    end
end

M.path_sep = function()
    local win = vim.loop.os_uname().version == 'WindowsNT'
    return win and '\\' or '/'
end

return M
