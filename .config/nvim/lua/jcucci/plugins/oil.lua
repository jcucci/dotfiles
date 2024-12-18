return {
    'stevearc/oil.nvim',
    opts = {},
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
    config = function()
        local oil = require("oil")
        oil.setup()
        oil.set_columns({ "icon", "permissions", "size", "mtime" })

        vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
    end
}
