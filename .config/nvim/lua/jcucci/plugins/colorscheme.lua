return {
    -- "catppuccin/nvim",
    -- name = "catppuccin",
    -- priority = 1000,
    -- config = function()
    --     local cat = require("catppuccin")
    --
    --     cat.setup({
    --         flavour = "mocha",
    --         color_overrides = {
    --             mocha = {
    --                 base = "#1d1d1d",
    --                 mantle = "#191919",
    --                 crust = "#141414"
    --             }
    --         },
    --         custom_highlights = function(config)
    --             return {
    --                 MsgSeparator = { bg = config.mantle }
    --             }
    --         end,
    --         integrations = {
    --             cmp = true,
    --             dap = true,
    --             dap_ui = true,
    --             gitsigns = true,
    --             mason = true,
    --             neotest = true,
    --             nvimtree = true,
    --             treesitter = true,
    --             treesitter_context = true,
    --             telescope = { enabled = true },
    --             which_key = true,
    --             native_lsp = {
    --                 enabled = true,
    --                 virtual_text = {
    --                     errors = {},
    --                     hints = {},
    --                     warnings = {},
    --                     information = {},
    --                 },
    --                 underlines = {
    --                     errors = { "undercurl" },
    --                     hints = { "undercurl" },
    --                     warnings = { "undercurl" },
    --                     information = { "undercurl" },
    --                 }
    --             }
    --         },
    --         no_italic = true,
    --     })
    --
    --     vim.cmd([[colorscheme catppuccin]])
    --     vim.cmd([[highlight Normal guibg=none]])
    --     vim.cmd([[highlight NonText guibg=none]])
    --     vim.cmd([[highlight Normal ctermbg=none]])
    --     vim.cmd([[highlight NonText ctermbg=none]])
    --
    -- end
    -- {
        "bluz71/vim-nightfly-guicolors",
        priority = 1000,
        config = function()
            vim.cmd([[colorscheme nightfly]])
            -- vim.cmd([[highlight Normal guibg=none]])
            -- vim.cmd([[highlight NonText guibg=none]])
            -- vim.cmd([[highlight Normal ctermbg=none]])
            -- vim.cmd([[highlight NonText ctermbg=none]])
        end
    -- }
}
