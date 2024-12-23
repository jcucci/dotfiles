local M = {}

function M.is_dotnet()
    return vim.g.roslyn_nvim_selected_solution ~= nil
end

function M.register_compiler()
    vim.cmd([[
        let dotnet_show_project_file = v:false
        compiler! dotnet
        let current_compiler = "dotnet"
        ]]
    )

    vim.opt.makeprg = string.format('dotnet build "%s" /v:q /nologo', vim.g.roslyn_nvim_selected_solution)
end

function M.get_error_format()
    return table.concat({
        '%*[^"]"%f"%*\\D%l %*\\D%c): %m',
        '%*[^"]"%f"%*\\D%l %*\\D%c : %m',
        '%f(%l\\,%c): %t%*[^:]: %m',
        '%*[^@]@%f:%l:%c: %m',
        '%*[^"]"%f"%*\\D%l: %m',
        '%f(%l) : %m',
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
