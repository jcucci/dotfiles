return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
        local cat = require("catppuccin")

        cat.setup({
            flavour = "mocha",
            background = { -- :h background
                light = "latte",
                dark = "mocha",
            },
            transparent_background = true, -- disables setting the background color.
            show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
            term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
            dim_inactive = {
                enabled = false, -- dims the background color of inactive window
                shade = "dark",
                percentage = 0.15, -- percentage of the shade to apply to the inactive window
            },
            no_italic = true, -- Force no italic
            no_bold = true, -- Force no bold
            no_underline = true, -- Force no underline
            styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
                comments = {}, -- Change the style of comments
                conditionals = {},
                loops = {},
                functions = {},
                keywords = {},
                strings = {},
                variables = {},
                numbers = {},
                booleans = {},
                properties = {},
                types = {},
                operators = {},
                -- miscs = {}, -- Uncomment to turn off hard-coded styles
            },
            color_overrides = {},
            custom_highlights = {},
            default_integrations = true,
            integrations = {
                alpha = true,
                cmp = true,
                dap = true,
                dap_ui = true,
                diffview = true,
                gitsigns = true,
                neogit = true,
                neotest = true,
                nvimtree = true,
                treesitter = true,
                noice = true,
                notify = false,
                mini = {
                    enabled = true,
                    indentscope_color = "",
                },
                rainbow_delimiters = true,
            },
            telescope = {
                enabled = true
            },
            which_key = true
        })

        vim.cmd([[colorscheme catppuccin]])

    end


    -- "Mofiqul/vscode.nvim",
    -- config = function()
    --     local vs = require("vscode")
    --     vs.setup({
    --         style = "dark",
    --         transparent = true,
    --         italic_comments = true,
    --         underline_links = true,
    --         disable_nvimtree_bg = true,
    --     })
    --
    --     vim.cmd([[colorscheme vscode]])
    -- end ]]
}
