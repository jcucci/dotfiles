return {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
  --  after = "catppuccin",
    version = "*",
    -- config = function()
    --     local bufferline = require("bufferline")
    --     local cat_bufferline = require("catppuccin.groups.integrations.bufferline")
    --
    --     bufferline.setup({
    --         highlights = cat_bufferline.get()
    --     })
    -- end,
    opts = {
        options = {
            mode = "buffers",
            style_preset = "bold",
            themable = true,
            tab_size = 20,
            diagnostics = "nvim_lsp",
            offsets = {
                {
                    filetype = "NvimTree",
                    text = "File Explorer",
                    text_align = "center",
                    separator = true
                }
            },
            show_close_icon = false,
      --      separator_style = "slope",
        },
    },
}
