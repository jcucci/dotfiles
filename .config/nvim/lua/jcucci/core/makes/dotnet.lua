local M = {}

function M.is_dotnet()
    return vim.g.roslyn_nvim_selected_solution ~= nil
end

function M.get_build_command_full()
    return string.format('dotnet build "%s" -v:q --nologo', vim.g.roslyn_nvim_selected_solution)
end

function M.get_build_command()
    return string.format('dotnet build "%s" -v:q --nologo --no-restore --no-dependencies', vim.g.roslyn_nvim_selected_solution)
end

function M.get_error_format()
    return table.concat({
        -- Basic format for C# compiler messages with project reference
        '%f(%l,%c): %t%*[^ ] %m [%*[^]]',
        -- Ignore build summary lines
        '%-GBuild %.%#',

        '%-GTime Elapsed%.%#',
        '%-G%*[0-9] Warning(s)%.%#',
        '%-G%*[0-9] Error(s)%.%#',
        -- Ignore other noise
        '%-G%.%#'
    }, ',')
end

function M.test_error_format()
    local test_error = [[C:\Project\File.cs(10,5): error CS1002: ; expected]]
    local parsed = vim.fn.getqflist({
        lines = { test_error },
        efm = M.get_error_format()
    }).items[1]

    vim.notify("Test parse result: " .. vim.inspect(parsed), vim.log.levels.DEBUG)
end

function M.process_diagnostics(build_output)
    local diagnostics_by_file = {}

    for _, line in ipairs(build_output) do
        if line and line ~= "" and not line:match("^%s*$")
            and not line:match("^Build %w+")
            and not line:match("^%s*%d+ Warning%(s%)")
            and not line:match("^%s*%d+ Error%(s%)")
            and not line:match("^Time Elapsed") then

            -- Parse dotnet error format: filename(line,col): type CS####: message [project]
            local filepath, lnum, col, dtype, message = line:match("^(.-)%((%d+),(%d+)%): (%w+)[^:]+: ([^[]+)")

            if not filepath then -- Try to handle Snyk warnings
                filepath, dtype, message = line:match("^(.-) : (%w+) ([^:]+: .+)$")
                lnum, col = "1", "1"
            end

            if message:match("https://") then
                message = message:gsub("(https://%S+)", " \n→ %1")
            end

            if filepath and lnum and col and dtype and message then
                if not vim.fn.has('win32') == 1 and not filepath:match("^/") then
                    filepath = vim.fn.getcwd() .. "/" .. filepath
                end
                filepath = vim.fn.fnamemodify(filepath, ':p')

                if not diagnostics_by_file[filepath] then
                    diagnostics_by_file[filepath] = {}
                end

                local severity
                if dtype:lower() == 'error' then
                    severity = vim.diagnostic.severity.ERROR
                elseif dtype:lower():match('warning') or dtype:match('NU%d+') then
                    severity = vim.diagnostic.severity.WARN
                else
                    severity = vim.diagnostic.severity.INFO
                end

                local diagnostic = {
                    lnum = tonumber(lnum) - 1,  -- Convert to 0-based line numbers
                    col = tonumber(col) - 1,  -- Convert to 0-based columns
                    message = message:gsub("^%s*(.-)%s*$", "%1"), -- trim whitespace
                    severity = severity,
                    source = "dotnet"
                }

                table.insert(diagnostics_by_file[filepath], diagnostic)
            end
        end
    end

    return diagnostics_by_file
end

return M
