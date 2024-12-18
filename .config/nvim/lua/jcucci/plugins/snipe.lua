return {
    "leath-dub/snipe.nvim",
    config = function()
        local snipe = require("snipe")

        snipe.setup({
            ui = {
                position = "center",

                open_win_override = {
                    border = "rounded",
                }
            }
        })

        vim.keymap.set("n", "<leader>hs", function() snipe.open_buffer_menu() end, { desc = "Open Snipe Buffers" } )
    end
}
