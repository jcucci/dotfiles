vim.g.mapleader = " "

local keymap = vim.keymap

keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

keymap.set("n", "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", { desc = "Close all other buffers" })
keymap.set("n", "<S-Tab>", "<cmd>BufferLineCycleNext<CR>", { desc = "Go to next buffer" })
keymap.set("n", "<C-S-Tab>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Go to previous buffer" })
keymap.set("n", "<leader>bx", "<cmd>BufferLinePickClose<CR>", { desc = "Pick the buffer to close" })

keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Move a lot down" })
keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Move a lot up" })
keymap.set("i", "<C-b>", "<ESC>^i", { desc = "Move to beginning of line" })
keymap.set("i", "<C-e>", "<End>", { desc = "Move to end of line" })

keymap.set("n", "<Esc>", "<cmd> noh <CR>", { desc = "Escape and clear highlights" })
keymap.set("n", "<C-s>", "<cmd> w <CR>", { desc = "Save file" })
keymap.set("n", "<C-a><C-c>", "<cmd> %y+ <CR>", { desc = "Copy all" })
