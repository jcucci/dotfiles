local opt = vim.opt

-- line numbers
opt.relativenumber = true
opt.number = true

-- indents
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true

-- wrapping
opt.wrap = false

-- search
opt.ignorecase = true
opt.smartcase = true

-- appearance
opt.cursorline = true
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"

-- behavior
opt.backspace = "indent,eol,start"
opt.clipboard = "unnamedplus"

-- splits
opt.splitright = true
opt.splitbelow = true

-- system
opt.swapfile = false

-- Lua initialization file
--vim.g.nightflyTransparent = true
