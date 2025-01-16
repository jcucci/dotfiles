local M = {}

local dotnet = require("jcucci.core.makes.dotnet")
local ns = vim.api.nvim_create_namespace('dotnet_compiler')

local makers = {
    dotnet = {
        detect = function()
            return dotnet.is_dotnet()
        end,
        get_error_format = function()
            return dotnet.get_error_format()
        end,
        process_diagnostics = function(build_output)
            return dotnet.process_diagnostics(build_output)
        end,
        process_quick_list = function()
            return dotnet.process_quick_list()
        end,
        get_build_command = function()
            return dotnet.get_build_command()
        end;
        get_build_command_full = function()
            return dotnet.get_build_command_full()
        end;
    },
}

local compile_project = function(maker, build_command)
    ---@diagnostic disable-next-line: undefined-field
    local start_time = vim.loop.hrtime()

    vim.notify("Building workspace", vim.log.levels.INFO, { title = "Compiler" })
    vim.diagnostic.reset(ns)

    local build_output = {}
    local seen_lines = {}  -- Track unique lines
    
    local function add_output_line(line)
        if line ~= "" and not seen_lines[line] then
            seen_lines[line] = true
            table.insert(build_output, line)
        end
    end

        local job_id = vim.fn.jobstart(build_command, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data)
            if data and #data > 1 then
                for _, line in ipairs(data) do
                    add_output_line(line)
                end
            end
        end,

        on_stderr = function(_, data)
            if data and #data > 1 then
                for _, line in ipairs(data) do
                    add_output_line(line)
                end
            end
        end,

        on_exit = function(_)
            local trouble = require("trouble")
            local diagnostics_by_file = maker.process_diagnostics(build_output)
            local errors = 0
            local warnings = 0

            for filepath, file_diagnostics in pairs(diagnostics_by_file) do
                for _, diag in ipairs(file_diagnostics) do
                    if diag.severity == vim.diagnostic.severity.ERROR then
                        errors = errors + 1
                    elseif diag.severity == vim.diagnostic.severity.WARN then
                        warnings = warnings + 1
                    end
                end

                local bufnr = vim.fn.bufnr(filepath)
                if bufnr == -1 then
                    bufnr = vim.fn.bufadd(filepath)
                    vim.fn.bufload(bufnr)
                end

                vim.diagnostic.set(ns, bufnr, file_diagnostics)
            end

            ---@diagnostic disable-next-line: undefined-field
            local end_time = vim.loop.hrtime()
            local duration_sec = (end_time - start_time) / 1e9


            local level = errors > 0 and vim.log.levels.ERROR or warnings > 0 and vim.log.levels.WARN or vim.log.levels.INFO
            local msg = string.format("Workspace compilation finished in %.2fs: %d error(s), %d warning(s)", duration_sec, errors, warnings)
            vim.notify(msg, level, { title = "Compiler" })

            if errors > 0 or warnings > 0 then
                local diagOpts = { mode = "diagnostics", follow = true, win = { size = .25 }, filter = { ['not'] = { severity = vim.diagnostic.severity.HINT }, }, }
                trouble.open(diagOpts)
            else
                trouble.close()
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

function M.compile_project(full_build)
    local maker = get_maker()
    local build_command

    if maker then
        if full_build then
            build_command = maker.get_build_command_full()
        else
            build_command = maker.get_build_command()
        end

        if not build_command then
            vim.notify("No Compiler found", vim.log.levels.INFO, { title = "Compiler" })
            return
        end

        compile_project(maker, build_command)
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
