return {
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory (Oil)" },
      { "<leader>o", "<cmd>Oil --float<cr>", desc = "Oil (float)" },
    },
    opts = {
      default_file_explorer = true,
      view_options = {
        show_hidden = true,
      },
      float = {
        padding = 2,
        max_width = 120,
        max_height = 40,
      },
      keymaps = {
        ["<C-j>"] = "actions.select",
        ["<C-k>"] = "actions.parent",
        ["q"] = "actions.close",
      },
    },
  },
}
