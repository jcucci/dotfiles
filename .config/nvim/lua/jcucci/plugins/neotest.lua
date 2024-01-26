return {
    "nvim-neotest/neotest",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "antoinemadec/FixCursorHold.nvim",
        "nvim-treesitter/nvim-treesitter",
        "Issafalcon/neotest-dotnet"
    },
    lazy = true,
    config = function()
        local neotest = require("neotest")
        local keymap = vim.keymap -- for conciseness

        neotest.setup({
            adapters = {
                require("neotest-dotnet"),
            }
        })

        keymap.set("n", "<leader>ta", "<cmd>require('neotest').run.run( { suite = true } )<cr>", { desc = "Run all tests" })
        keymap.set("n", "<leader>tr", "<cmd>require('neotest').run.run()<cr>", { desc = "Run current test" })
        keymap.set("n", "<leader>td", "<cmd>require('neotest').run.run( { strategy = 'dap' } )<cr>", { desc = "Debug current test" })
        keymap.set("n", "<leader>to", "<cmd>require('neotest').output.open( { short = true, enter = true, last_run = true, auto_close = true } )<cr>", { desc = "Open last test run output" })
        keymap.set("n", "<leader>et", "<cmd>require('neotest').output_panel.toggle()<cr>", { desc = "Toggle test view" })
        keymap.set("n", "<leader>tn", "<cmd>require('neotest').jump.next({ status = 'failed'})<cr>", { desc = "Go to next failed test" })
        keymap.set("n", "<leader>tp", "<cmd>require('neotest').jump.prev({ status = 'failed'})<cr>", { desc = "Go to previous failed test" })
    end
}
