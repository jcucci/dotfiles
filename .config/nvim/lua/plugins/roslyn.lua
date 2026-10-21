return {
  -- Mason with Roslyn registry
  {
    "mason-org/mason.nvim",
    opts = {
      registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry", -- For Roslyn LSP
      },
    },
  },

  -- Roslyn LSP for C#
  {
    "seblyng/roslyn.nvim",
    ft = { "cs" },
    dependencies = { "mason-org/mason.nvim" },
    init = function()
      -- Bound the LSP shutdown wait so quitting nvim in C# repos is fast.
      -- Roslyn is slow to honor the graceful `shutdown` request; without this,
      -- nvim waits for its stdio pipes to close on exit (multi-second hang).
      -- A number = try graceful shutdown for N ms, then force-stop.
      -- Use `exit_timeout = true` instead for instant force-kill if 200ms still lags.
      vim.lsp.config("roslyn", { exit_timeout = 200 })
    end,
    opts = {
      broad_search = true, -- Search parent directories for .sln files

      -- Ignore test solution files
      ignore_target = function(target)
        return string.match(target, "%.Tests%.sln$") ~= nil
            or string.match(target, "%.Api%.Tests%.sln$") ~= nil
      end,

      -- Prefer non-test solutions
      choose_target = function(targets)
        return vim.iter(targets):find(function(item)
          return not string.match(item, "Tests%.sln$")
        end)
      end,
    },
    keys = {
      { "<leader>nS", "<cmd>Roslyn target<cr>", desc = "Switch Roslyn solution" },
    },
  },
}
