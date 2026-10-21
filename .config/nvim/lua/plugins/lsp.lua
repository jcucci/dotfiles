return {
  -- Rustaceanvim tweaks for better completion
  {
    "mrcjkb/rustaceanvim",
    opts = {
      server = {
        default_settings = {
          ["rust-analyzer"] = {
            completion = {
              callable = { snippets = "add_parentheses" },
            },
          },
        },
      },
    },
  },

  -- Bash LSP and tooling
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {},
      },
    },
  },

  -- Mason: ensure bash tools are installed
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- Bash
        "bash-language-server",
        "shellcheck",
        "shfmt",
      },
    },
  },

  -- Treesitter: add parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "c_sharp", -- Required for neotest-dotnet
      },
    },
  },
}
