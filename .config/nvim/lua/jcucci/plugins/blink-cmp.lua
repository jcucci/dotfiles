return {
    'saghen/blink.cmp',
    dependencies = { 'rafamadriz/friendly-snippets', 'milanglacier/minuet-ai.nvim' },
    version = '*',
    opts_extend = { "sources.default" },
    config = function()
        local blink = require("blink-cmp")
        local minuet = require("minuet")

        blink.setup({
            -- keymap = { preset = 'default' },
            keymap = { preset = 'default', ['<A-y>'] = minuet.make_blink_map(), },

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

            appearance = {
                use_nvim_cmp_as_default = true,
                nerd_font_variant = 'mono',
            },

            sources = {
                default = { 'lsp', 'path', 'snippets', 'buffer', 'minuet' },
                providers = {
                    minuet = {
                        name = 'minuet',
                        module = 'minuet.blink',
                        score_offset = 8, -- Gives minuet higher priority among suggestions
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
