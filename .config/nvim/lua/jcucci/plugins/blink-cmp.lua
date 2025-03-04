return {
    'saghen/blink.cmp',
    dependencies = { 'rafamadriz/friendly-snippets', 'milanglacier/minuet-ai.nvim', 'saghen/blink.compat' },
    version = '*',
    opts_extend = { "sources.default" },
    config = function()
        local blink = require("blink-cmp")

        blink.setup({
            completion = {
                menu = {
                    border = "rounded",
                    winhighlight = "Normal:MyHighlight",
                    winblend = 0
                },
                documentation = {
                    window = {
                        border = "rounded",
                        winhighlight = "Normal:MyHighlight",
                        winblend = 0
                    },
                },
            },

            keymap = {
                preset = "super-tab"
            },

            appearance = {
                use_nvim_cmp_as_default = true,
                nerd_font_variant = 'mono',
            },

            sources = {
                default = { 'lsp', 'path', 'snippets', 'buffer', 'avante_commands', 'avante_mentions', 'avante_files' },
                providers = {
                    avante_commands = {
                        name = "avante_commands",
                        module = "blink.compat.source",
                        score_offset = 90, -- show at a higher priority than lsp
                        opts = {},
                    },
                    avante_files = {
                        name = "avante_commands",
                        module = "blink.compat.source",
                        score_offset = 100, -- show at a higher priority than lsp
                        opts = {},
                    },
                    avante_mentions = {
                        name = "avante_mentions",
                        module = "blink.compat.source",
                        score_offset = 1000, -- show at a higher priority than lsp
                        opts = {},
                    },
                },
            },

            signature = {
                enabled = true,
                window = {
                    border = "rounded",
                    winhighlight = "Normal:MyHighlight",
                    winblend = 0
                }
            }
        })
    end
}
