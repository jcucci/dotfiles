local M = {}

local dotnet = require("jcucci.core.testers.dotnet")

local runners = {
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
        register_runner = function()
            return dotnet.register_runner()
        end,
    },
}

local run_tests = function(runner)

    vim.fn.setqflist({}, 'r')
    vim.notify("Running workspace tests", vim.log.levels.INFO, { title = "Tests" })

    local error_format = runner.get_error_format()
    local current_test = nil
    local test_entries = {}
    local error_message = nil

    local job_id = vim.fn.jobstart(vim.o.makeprg, {

        stdout_buffered = true,
        stderr_buffered = true,

        on_stdout = function(_, data)

            if data then
                for _, line in ipairs(data) do
                    if line:match("^%s+Failed%s+") then
                        -- New test failure found
                        current_test = {
                            text = line:match("^%s+Failed%s+(.+)"),
                            error = nil,
                            traces = {}
                        }
                        table.insert(test_entries, current_test)
                    elseif line:match("^%s+Error Message:") then
                        error_message = true
                    elseif error_message and line:match("^%s+.+") then
                        if current_test then
                            current_test.error = line:match("^%s+(.+)")
                            error_message = false
                        end
                    elseif current_test and line:match("^%s+at.+in.+:line") then
                        local trace = line:match("^%s+at%s+(.+)%s+in")
                        local file = line:match("in%s+(.+):line")
                        local lnum = line:match(":line%s+(%d+)")
                        table.insert(current_test.traces, {
                            trace = trace,
                            file = file,
                            line = tonumber(lnum)
                        })
                    end
                end
            end

          -- if data and #data > 1 then
          --   vim.fn.setqflist({}, 'a', {
          --     lines = data,
          --     efm = error_format
          --   })
          -- end
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

            local qf_entries = {}
            for _, test in ipairs(test_entries) do
                -- Use last stack trace line for location
                local last_trace = test.traces[#test.traces]
                if last_trace then
                    local text = test.text
                    if test.error then
                        text = text .. " | " .. test.error
                    end
                    if last_trace.trace then
                        text = text .. " | " .. last_trace.trace
                    end
                    
                    table.insert(qf_entries, {
                        text = text,
                        filename = last_trace.file,
                        lnum = last_trace.line,
                        type = 'E'
                    })
                end
            end

            vim.fn.setqflist(qf_entries)
            runner.process_quick_list()

            local qflist = vim.fn.getqflist()
            local failures = #vim.tbl_filter(function(item) return item.type == 'E' end, qflist)
          
            local level = failures > 0 and vim.log.levels.ERROR or vim.log.levels.INFO
            local msg = string.format("Test run completed: %d failure(s)", failures)
            vim.notify(msg, level, { title = "Tests" })
          
            if failures > 0 then
                local diagOpts = { mode = "quickfix", follow = true, win = { size = .25 } }
                trouble.open(diagOpts)
            else
                trouble.close("quickfix")
            end
        end,
    })
  
    if job_id == 0 then
        vim.notify("Failed to start test run", vim.log.levels.ERROR, { title = "Tests" })
    elseif job_id == -1 then
        vim.notify("Invalid test command", vim.log.levels.ERROR, { title = "Tests" })
    end

end

local get_runner = function()
    for _, runner in pairs(runners) do
        if runner.detect() then 
            return runner
        end
    end
    return nil
end

function M.run_tests()
    local runner = get_runner()
    if runner then 
        run_tests(runner)
    else
        vim.notify("No suitable test runner found.", vim.log.levels.WARN)
    end
end

function M.register_test_runner()
    local runner = get_runner()
    if runner then 
        runner.register_runner()
    end
end

return M
