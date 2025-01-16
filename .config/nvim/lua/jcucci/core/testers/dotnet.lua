local M = {}

function M.is_dotnet()
    return vim.g.roslyn_nvim_selected_solution ~= nil
end

function M.register_runner()
    vim.opt.makeprg = string.format('dotnet test "%s" /nologo --filter=Category!=Integration', vim.g.roslyn_nvim_selected_solution)
end

function M.get_error_format()
    return table.concat({
        '%E  Failed %m',
        '%-G  Error Message:%m',
        '%-G  Stack Trace:',
        '%C   at %.%# in %f:line %l', -- Change %+G to %C to make these continuation lines
        '%-G%.%#'
    }, ',')
end

function M.process_quick_list()

    local qflist = vim.fn.getqflist()

    for _, item in ipairs(qflist) do
        
        if item.type == 'e' then
            item.type = 'E'
        elseif item.type == 'w' then
            item.type = 'W'
        end
    end

    vim.fn.setqflist({}, 'r', { items = qflist })

end

return M
