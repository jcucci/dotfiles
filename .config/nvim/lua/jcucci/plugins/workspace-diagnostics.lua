return {
    "artemave/workspace-diagnostics.nvim",
    config = function()
        local workspace_diagnostics = require("workspace-diagnostics")
        workspace_diagnostics.setup()
    end
}
