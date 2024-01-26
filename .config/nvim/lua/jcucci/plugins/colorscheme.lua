return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
        local cat = require("catppuccin")

        cat.setup({
            flavour = "mocha",
            color_overrides = {
                mocha = {
                    base = "#1d1d1d",
                    mantle = "#191919",
                    crust = "#141414"
                }
            },
            custom_highlights = function(config)
                return {
                    MsgSeparator = { bg = config.mantle }
                }
            end,
            integrations = {
                cmp = true,
                dap = true,
                dap_ui = true,
                gitsigns = true,
                mason = true,
                neotest = true,
                nvimtree = true,
                treesitter = true,
                treesitter_context = true,
                telescope = { enabled = true },
                which_key = true
            },
            no_italic = true
        })

        vim.cmd([[colorscheme catppuccin]])
    end
    -- {
    --     "bluz71/vim-nightfly-guicolors",
    --     priority = 1000,
    --     config = function()
    --         vim.cmd([[colorscheme nightfly]])
    --     end
    -- }
}
