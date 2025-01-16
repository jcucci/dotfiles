return {
    'milanglacier/minuet-ai.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'Saghen/blink.cmp' },
    config = function()
        local minuet = require("minuet")

        minuet.setup {
            blink = {
                enable_auto_complete = false,
            },
            -- virtualtext = {
            --     auto_trigger_ft = { 'cs' },
            --     keymap = {
            --         accept = '<A-a>',
            --         accept_line = '<A-A>',
            --         prev = '<A-p>',
            --         next = '<A-n>',
            --         dismiss = '<A-e>',
            --     },
            -- },
            provider = "gemini",
        }
    end
}
