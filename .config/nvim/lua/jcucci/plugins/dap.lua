return {
    "mfussenegger/nvim-dap",
    lazy = true,
    config = function()
        local dap = require("dap")
        local sign = vim.fn.sign_define

        sign("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = ""})
        sign("DapBreakpointCondition", { text = "●", texthl = "DapBreakpointCondition", linehl = "", numhl = ""})
        sign("DapLogPoint", { text = "◆", texthl = "DapLogPoint", linehl = "", numhl = ""})

        dap.adapters.coreclr = {
            type = "executable",
            command = "/usr/local/netcoredbg",
            args = { "--interpreter=vscode" },
            options = {
                detached = false
            }
        }

        dap.configurations.cs = {
            {
                type = "coreclr",
                name = "launch - netcoredbg",
                request = "launch",
                program = function()
                    return vim.fn.input("Path to DLL", vim.fn.getcwd(), "File")
                end
            },
        }
    end
}
