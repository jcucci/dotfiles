return {
    "lewis6991/gitsigns.nvim",
    config = function()
        local signs = require("gitsigns")
        signs.setup({
            current_line_blame = true,
            current_line_blame_opts = {
                delay = 3000,
                ignore_whitespace = true
            }
        })

        vim.keymap.set("n", "<leader>gl", signs.blame_line, { desc = "Git Blame Line" } )
        vim.keymap.set("n", "<leader>gb", signs.blame, { desc = "Git Blame" } )
        vim.keymap.set("n", "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", { desc = "Git File History" })
        vim.keymap.set("n", "<leader>gx", "<cmd>DiffviewClose<CR>", { desc = "Close Git File History" })
    end
}
