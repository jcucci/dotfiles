return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")

        telescope.setup({
            defaults = {
                layout_strategy = "horizontal",
                path_display = { "truncate " },
                mappings = {
                    i = {
                        ["<C-k>"] = actions.move_selection_previous,
                        ["<C-j>"] = actions.move_selection_next,
                        ["<C-h>"] = actions.select_horizontal,
                        ["<C-v>"] = actions.select_vertical,
                    },
                },
            },
            extensions = {
                fzf = {}
            }
        })

        telescope.load_extension("fzf")

        -- set keymaps
        -- local keymap = vim.keymap -- for conciseness
        --
        -- keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Fuzzy find help" })
        -- keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
        -- keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })
        -- keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
        --
        -- keymap.set("n", "<leader>ft", function() 
        --     require'telescope.builtin'.lsp_dynamic_workspace_symbols(require('telescope.themes').get_ivy({
        --         path_display = "hidden",
        --         symbol_width = 50,
        --         symbols = { "class", "enum", "record", "interface" }
        --     }))
        -- end, { desc = "Find symbols" } )

    end,
}
