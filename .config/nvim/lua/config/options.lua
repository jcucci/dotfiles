-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Use fzf-lua as the picker (default in LazyVim 14+)
vim.g.lazyvim_picker = "fzf"

-- Always use cwd as root (don't auto-detect based on .sln, .git, etc.)
vim.g.root_spec = { "cwd" }

-- Ensure screen updates immediately (helps with WezTerm redraw issues)
vim.o.lazyredraw = false
vim.o.ttyfast = true

-- Reduce update time for faster UI response (default is 4000ms)
vim.o.updatetime = 100

-- Disable display of special characters (tabs, trailing spaces, etc.)
vim.o.list = false
