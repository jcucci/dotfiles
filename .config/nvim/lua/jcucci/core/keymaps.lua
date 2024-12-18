vim.g.mapleader = " "

local keymap = vim.keymap

keymap.set("n", "<leader>|", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>-", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>=", "<C-w>=", { desc = "Make splits equal size" })

keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Move a lot down" })
keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Move a lot up" })
keymap.set("i", "<C-b>", "<ESC>^i", { desc = "Move to beginning of line" })
keymap.set("i", "<C-e>", "<End>", { desc = "Move to end of line" })

keymap.set("n", "<Esc>", "<cmd> noh <CR>", { desc = "Escape and clear highlights" })
keymap.set("n", "<C-s>", "<cmd> w <CR>", { desc = "Save file" })

keymap.set("n", "<leader>z", "<cmd>ZenMode<CR>", { desc = "Zen Mode" })

keymap.set("n", "<leader>aa", "<cmd>AvanteToggle<CR>", { desc = "Avante Toggle" })
