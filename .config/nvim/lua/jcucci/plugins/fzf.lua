return {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local fzf = require("fzf-lua")
        fzf.setup()

        vim.keymap.set("n", "<leader>fb", function() fzf.buffers() end, { desc = "Find help" })
        vim.keymap.set("n", "<leader>fh", function() fzf.helptags() end, { desc = "Find help" })
        vim.keymap.set("n", "<leader>ff", function() fzf.files() end, { desc = "Find files" })
        vim.keymap.set("n", "<leader>fm", function() fzf.marks() end, { desc = "Find marks" })
        vim.keymap.set("n", "<leader>fr", function() fzf.oldfiles() end, { desc = "Find recent files" })
        vim.keymap.set("n", "<leader>fg", function() fzf.grep_project() end, { desc = "Grep" })
        vim.keymap.set("n", "<leader>ft", function() fzf.lsp_live_workspace_symbols() end, { desc = "Find symbols" })

    end
}
