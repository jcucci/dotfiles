return {
    "folke/neodev.nvim",
    lazy = true,
    config = function()
        local neodev = require("neodev")

        neodev.setup({
            library = { plugins = { "neotest", "nvim-dap-ui" }, types = true }
        })
    end
}
