return {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
        -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
        "MunifTanjim/nui.nvim",
        -- OPTIONAL:
        --   `nvim-notify` is only needed, if you want to use the notification view.
        --   If not available, we use `mini` as the fallback
        "rcarriga/nvim-notify",
    },
    config = function()
        local noice = require("noice")
        local notify = require("notify")

        noice.setup({
            lsp = {
                -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
                },
            },
            -- you can enable a preset for easier configuration
            presets = {
                bottom_search = true, -- use a classic bottom cmdline for search
                command_palette = true, -- position the cmdline and popupmenu together
                long_message_to_split = true, -- long messages will be sent to a split
                inc_rename = true, -- enables an input dialog for inc-rename.nvim
                lsp_doc_border = true, -- add a border to hover docs and signature help
            },
            routes = {
                {
                    filter = { event = "msg_show", kind = "" }, -- ignore silent messages
                    opts = { skip = false }, -- don't skip messages
                },
            },
            views = {
                cmdline_popup = {
                    position = {
                        row = "50%",  -- Set the row to 50% of the screen height
                        col = "50%",  -- Set the column to 50% of the screen width
                    },
                    size = {
                        min_width = 60,  -- Set the minimum width
                        width = "auto",  -- Set the width to automatic
                        height = "auto",  -- Set the height to automatic
                    },
                },
            },
        })

        notify.setup({
            background_colour = "#000000",
            render = "minimal",
            top_down = false
        })

    end
}
