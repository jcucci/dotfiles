return {
  dir = "~/projects/weavr.nvim",
  config = function()
    require("weavr").setup()
  end,
  keys = {
    { "<leader>wo", ":Weavr<CR>", desc = "Open weavr" },
    { "<leader>wa", ":WeavrAll<CR>", desc = "Open weavr (all files)" },
    { "<leader>wl", ":WeavrAcceptLeft<CR>", desc = "Accept left" },
    { "<leader>wr", ":WeavrAcceptRight<CR>", desc = "Accept right" },
    { "<leader>wb", ":WeavrAcceptBoth<CR>", desc = "Accept both" },
  },
}
