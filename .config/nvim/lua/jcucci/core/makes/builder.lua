local M = {}

local dotnet = require("jcucci.core.makes.dotnet")

local makers = {
    dotnet = {
        detect = function()
            return dotnet.is_dotnet()
        end,
        get_error_format = function()
            return dotnet.get_error_format()
        end,
        process_quick_list = function()
            return dotnet.process_quick_list()
        end,
        register_compiler = function()
            return dotnet.register_compiler()
        end,
    },
}

local compile_project = function(maker)

    vim.fn.setqflist({}, 'r')
    vim.notify("Building workspace", vim.log.levels.INFO, { title = "Compiler" })

    local error_format = maker.get_error_format()

    local job_id = vim.fn.jobstart(vim.o.makeprg, {

        stdout_buffered = true,
        stderr_buffered = true,
        
        on_stdout = function(_, data)
          if data and #data > 1 then
            vim.fn.setqflist({}, 'a', {
              lines = data,
              efm = error_format
            })
          end
        end,

        on_stderr = function(_, data)
          if data and #data > 1 then
            vim.fn.setqflist({}, 'a', {
              lines = data,
              efm = error_format
            })
          end
        end,

        on_exit = function(_, exit_code)
            local trouble = require("trouble")

            maker.process_quick_list()

            local qflist = vim.fn.getqflist()
            local errors = #vim.tbl_filter(function(item) return item.type == 'E' end, qflist)
            local warnings = #vim.tbl_filter(function(item) return item.type == 'W' end, qflist)
          
            local level = errors > 0 and vim.log.levels.ERROR or warnings > 0 and vim.log.levels.WARN or vim.log.levels.INFO
            local msg = string.format("Workspace compilation finished: %d error(s), %d warning(s)", errors, warnings)
            vim.notify(msg, level, { title = "Compiler" })
          
            if errors > 0 or warnings > 0 then
                local diagOpts = { mode = "quickfix", follow = true, win = { size = .25 } }
                trouble.open(diagOpts)
            else
                trouble.close("quickfix")
            end
        end,
    })
  
    if job_id == 0 then
        vim.notify("Failed to start build", vim.log.levels.ERROR, { title = "Compiler" })
    elseif job_id == -1 then
        vim.notify("Invalid build command", vim.log.levels.ERROR, { title = "Compiler" })
    end

end

local get_maker = function()
    for _, maker in pairs(makers) do
        if maker.detect() then 
            return maker
        end
    end
    return nil
end

function M.compile_project()
    local maker = get_maker()
    if maker then 
        compile_project(maker)
    else
        vim.notify("No suitable compilation strategy found.", vim.log.levels.WARN)
    end
end

function M.register_compiler()
    local maker = get_maker()
    if maker then 
        maker.register_compiler()
    end
end

return M
