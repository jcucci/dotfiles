return {
  -- Disable bufferline (tabs at top)
  { "akinsho/bufferline.nvim", enabled = false },

  -- Disable vim-illuminate (symbol highlight under cursor)
  { "RRethy/vim-illuminate", enabled = false },

  -- Disable indent guides
  { "lukas-reineke/indent-blankline.nvim", enabled = false },
  {
    "folke/snacks.nvim",
    opts = {
      indent = { enabled = false },
      scroll = { enabled = false },
    },
    keys = {
      { "<leader>n", false }, -- Disable default (freeing for dotnet)
      { "<leader>N", function() Snacks.notifier.show_history() end, desc = "Notification History" },
    },
  },

  -- Disable LSP document highlight
  {
    "neovim/nvim-lspconfig",
    opts = {
      document_highlight = { enabled = false },
    },
  },

  -- Fallback: clear highlight autocommands if above doesn't work
  {
    "LazyVim/LazyVim",
    opts = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.server_capabilities.documentHighlightProvider then
            client.server_capabilities.documentHighlightProvider = false
          end
        end,
      })
    end,
  },
}
