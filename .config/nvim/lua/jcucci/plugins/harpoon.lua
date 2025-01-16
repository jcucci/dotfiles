return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local harpoon = require("harpoon")

        harpoon.setup()

        harpoon:extend({
            UI_CREATE = function(cx)
                vim.keymap.set("n", "<C-v>", function()
                    harpoon.ui:select_menu_item({ vsplit = true })
                end, { buffer = cx.bufnr })
                
                vim.keymap.set("n", "<C-x>", function()
                    harpoon.ui:select_menu_item({ split = true })
                end, { buffer = cx.bufnr })
            end,
        })

        vim.keymap.set("n", "<leader>ha", function() harpoon:list():add() end, { desc = "Harpoon Add" } )
        vim.keymap.set("n", "<leader>hh", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon List" } )

        vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end, { desc = "Harpoon 1" } )
        vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end, { desc = "Harpoon 2" } )
        vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end, { desc = "Harpoon 3" } )
        vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end, { desc = "Harpoon 4" } )
        vim.keymap.set("n", "<leader>5", function() harpoon:list():select(5) end, { desc = "Harpoon 5" } )
        vim.keymap.set("n", "<leader>6", function() harpoon:list():select(6) end, { desc = "Harpoon 6" } )

        vim.keymap.set("n", "<leader>hp", function() harpoon:list():prev() end, { desc = "Previous Harpoon" } )
        vim.keymap.set("n", "<leader>hn", function() harpoon:list():next() end, { desc = "Next Harpoon" } )
    end
}
