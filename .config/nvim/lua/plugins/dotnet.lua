return {
  -- easy-dotnet for commands/test runner (LSP disabled - using roslyn.nvim instead)
  {
    "GustavEikaas/easy-dotnet.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "ibhagwan/fzf-lua" },
    ft = { "cs", "fsharp", "vb" },
    config = function()
      -- Get netcoredbg path from the arm64 plugin
      local lazy_path = vim.fn.stdpath("data") .. "/lazy"
      local netcoredbg_path = lazy_path .. "/netcoredbg-macOS-arm64.nvim/netcoredbg/netcoredbg"

      require("easy-dotnet").setup({
        lsp = {
          enabled = false, -- Disabled - using roslyn.nvim instead
        },
        debugger = {
          bin_path = netcoredbg_path, -- Use arm64 netcoredbg from plugin
          auto_register_dap = true,
          apply_value_converters = true,
        },
        test_runner = {
          viewmode = "float",
          enable_buffer_test_execution = true,
          noBuild = true, -- Don't rebuild on every test run
          -- These mappings only work inside the test runner buffer
          mappings = {
            run_test_from_buffer = { lhs = "<leader>r", desc = "run test from buffer" },
            peek_stack_trace_from_buffer = { lhs = "<leader>p", desc = "peek stack trace" },
            debug_test = { lhs = "<leader>d", desc = "debug test" },
            filter_failed_tests = { lhs = "<leader>fe", desc = "filter failed tests" },
            go_to_file = { lhs = "g", desc = "go to file" },
            run_all = { lhs = "<leader>R", desc = "run all tests" },
            run = { lhs = "<leader>r", desc = "run test" },
            peek_stacktrace = { lhs = "<leader>p", desc = "peek stacktrace" },
            expand = { lhs = "o", desc = "expand" },
            expand_node = { lhs = "E", desc = "expand node" },
            expand_all = { lhs = "-", desc = "expand all" },
            collapse_all = { lhs = "W", desc = "collapse all" },
            close = { lhs = "q", desc = "close testrunner" },
            refresh_testrunner = { lhs = "<C-r>", desc = "refresh testrunner" },
          },
        },
        picker = "fzf",
      })
    end,
    keys = {
      { "<leader>nn", "<cmd>Dotnet new<cr>", desc = "New .NET project" },
      { "<leader>nr", "<cmd>Dotnet run<cr>", desc = "Run project" },
      { "<leader>nb", "<cmd>Dotnet build<cr>", desc = "Build project" },
      -- Test runner removed - using neotest instead (<leader>t*)
      { "<leader>np", "<cmd>Dotnet project view<cr>", desc = "Project view" },
      { "<leader>no", "<cmd>Dotnet outdated<cr>", desc = "Outdated packages" },
      { "<leader>ns", "<cmd>Dotnet solution select<cr>", desc = "Select solution" },
      { "<leader>nR", "<cmd>Dotnet reset<cr>", desc = "Reset easy-dotnet state" },
      {
        "<leader>ni",
        function()
          local sln = require("easy-dotnet").try_get_selected_solution()
          if sln then
            vim.notify("Solution: " .. sln.path, vim.log.levels.INFO)
          else
            vim.notify("No solution selected", vim.log.levels.WARN)
          end
        end,
        desc = "Show current solution",
      },
    },
  },

  -- Disable OmniSharp if it gets enabled
  { "Hoffs/omnisharp-extended-lsp.nvim", enabled = false },
}
