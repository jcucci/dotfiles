return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "Issafalcon/neotest-dotnet",
      "fredrikaverpil/neotest-golang",
      "nvim-neotest/neotest-jest",
      "marilari88/neotest-vitest",
      "rouge8/neotest-rust",
    },
    -- Load neotest when opening test files (not just on keypress)
    event = "BufRead *test*.cs,*Test*.cs,*_test.go,*.test.ts,*.test.js,*.spec.ts,*.spec.js",
    opts = function(_, opts)
      -- Filter out api-tests directories from discovery
      opts.discovery = opts.discovery or {}
      opts.discovery.filter_dir = function(name, rel_path, root)
        return name ~= "api-tests" and name ~= "api-tests-runner"
      end

      -- Add adapters
      opts.adapters = opts.adapters or {}
      table.insert(
        opts.adapters,
        require("neotest-dotnet")({
          dap = {
            adapter_name = "coreclr",
          },
          discovery_root = "solution",
        })
      )
      table.insert(opts.adapters, require("neotest-golang")({ dap_go_enabled = true }))
      table.insert(opts.adapters, require("neotest-jest")({ jestCommand = "npm test --" }))
      table.insert(opts.adapters, require("neotest-vitest"))
      table.insert(opts.adapters, require("neotest-rust"))

      return opts
    end,
    keys = {
      -- Override default keymaps to ensure discovery before running
      {
        "<leader>tr",
        function()
          require("neotest").run.run()
        end,
        desc = "Run nearest test",
      },
      {
        "<leader>tt",
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "Run test file",
      },
      {
        "<leader>ta",
        function()
          require("neotest").run.run(vim.uv.cwd())
        end,
        desc = "Run all tests",
      },
      {
        "<leader>td",
        function()
          require("neotest").run.run({ strategy = "dap" })
        end,
        desc = "Debug nearest test",
      },
      {
        "<leader>ts",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "Toggle test summary",
      },
      {
        "<leader>to",
        function()
          require("neotest").output.open({ enter = true })
        end,
        desc = "Show test output",
      },
      {
        "<leader>tS",
        function()
          require("neotest").run.stop()
        end,
        desc = "Stop tests",
      },
    },
  },
}
