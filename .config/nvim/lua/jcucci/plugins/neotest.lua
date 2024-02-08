return {
    "nvim-neotest/neotest",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "antoinemadec/FixCursorHold.nvim",
        "nvim-treesitter/nvim-treesitter",
        "Issafalcon/neotest-dotnet"
    },
    -- lazy = true,
    config = function()
        local neotest = require("neotest")
        local keymap = vim.keymap -- for conciseness

        neotest.setup({
            adapters = {
                require("neotest-dotnet"),
            }
        })

        keymap.set("n", "<leader>ta", "<cmd>lua require('neotest').run.run( { suite = true } )<cr>", { desc = "Run all tests" })
        keymap.set("n", "<leader>tr", "<cmd>lua require('neotest').run.run()<cr>", { desc = "Run current test" })
        keymap.set("n", "<leader>td", "<cmd>lua require('neotest').run.run( { strategy = 'dap' } )<cr>", { desc = "Debug current test" })
        keymap.set("n", "<leader>et", "<cmd>lua require('neotest').summary.toggle()<cr>", { desc = "Toggle test view" })
    end
}
