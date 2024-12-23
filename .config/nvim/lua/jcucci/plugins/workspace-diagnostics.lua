return {
    "artemave/workspace-diagnostics.nvim",
    config = function()
        local workspace_diagnostics = require("workspace-diagnostics")
        workspace_diagnostics.setup()

        vim.api.nvim_set_keymap('n', '<space>x', '', {
            noremap = true,
            callback = function()
                for _, client in ipairs(vim.lsp.buf_get_clients()) do
                    workspace_diagnostics.populate_workspace_diagnostics(client, 0)
                end
            end
        })
    end
}
