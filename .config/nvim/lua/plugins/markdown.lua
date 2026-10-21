-- Show all markdown formatting characters and disable background colors

-- Always show format characters (don't conceal them)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "markdown.mdx" },
  callback = function()
    vim.opt_local.conceallevel = 0
    vim.opt_local.wrap = false
  end,
})

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      heading = {
        -- Disable background highlighting on heading lines
        backgrounds = {},
      },
      code = {
        -- Disable background on all code blocks
        disable_background = true,
        -- Disable background on inline code
        highlight_inline = "",
      },
    },
  },

  -- Disable markdown linting
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        markdown = {},
      },
    },
  },

  -- Format markdown with prettier (aligns tables, wraps text, etc.)
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "prettier" },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        markdown = { "prettier" },
        ["markdown.mdx"] = { "prettier" },
      },
    },
  },
}
