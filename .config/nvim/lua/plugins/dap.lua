return {
  -- Override LazyVim's DAP icons (basic Unicode - swap for Nerd Font icons if desired)
  {
    "LazyVim/LazyVim",
    opts = {
      icons = {
        dap = {
          Breakpoint = "●",
          BreakpointCondition = "◆",
          BreakpointRejected = "○",
          LogPoint = "◇",
          Stopped = { "→", "DiagnosticWarn", "DapStoppedLine" },
        },
      },
    },
  },

  -- netcoredbg for macOS ARM (Apple Silicon)
  -- Register the coreclr adapter and configurations
  {
    "Cliffback/netcoredbg-macOS-arm64.nvim",
    dependencies = { "mfussenegger/nvim-dap" },
    ft = "cs",
    config = function()
      local dap = require("dap")
      local lazy_path = vim.fn.stdpath("data") .. "/lazy"
      local netcoredbg_path = lazy_path .. "/netcoredbg-macOS-arm64.nvim/netcoredbg/netcoredbg"

      -- Register coreclr adapter
      dap.adapters.coreclr = {
        type = "executable",
        command = netcoredbg_path,
        args = { "--interpreter=vscode" },
      }

      -- Add coreclr configurations
      dap.configurations.cs = dap.configurations.cs or {}

      -- Insert at beginning so they appear first in picker
      table.insert(dap.configurations.cs, 1, {
        type = "coreclr",
        name = "Launch DLL",
        request = "launch",
        program = function()
          local cwd = vim.fn.getcwd()
          return vim.fn.input("Path to dll: ", cwd .. "/bin/Debug/", "file")
        end,
        cwd = "${fileDirname}",
        stopAtEntry = false,
      })

      table.insert(dap.configurations.cs, 2, {
        type = "coreclr",
        name = "Attach to process",
        request = "attach",
        processId = require("dap.utils").pick_process,
      })
    end,
  },

  -- nvim-dap-go for Go debugging with delve
  {
    "leoluz/nvim-dap-go",
    ft = "go",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {
      dap_configurations = {
        {
          type = "go",
          name = "Debug test (go.mod)",
          request = "launch",
          mode = "test",
          program = "./${relativeFileDirname}",
        },
      },
      delve = {
        build_flags = {},
      },
    },
    -- Test keymaps removed - using neotest instead (<leader>td to debug)
  },

  -- TypeScript/JavaScript DAP configuration
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")

      -- Define breakpoint signs
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DapBreakpointRejected", linehl = "", numhl = "" })
      vim.fn.sign_define("DapLogPoint", { text = "◇", texthl = "DapLogPoint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "→", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" })

      -- TypeScript/JavaScript configuration with js-debug-adapter
      for _, adapter in ipairs({ "pwa-node", "pwa-chrome" }) do
        dap.adapters[adapter] = {
          type = "server",
          host = "localhost",
          port = "${port}",
          executable = {
            command = "js-debug-adapter",
            args = { "${port}" },
          },
        }
      end

      local js_based_languages = { "typescript", "javascript", "typescriptreact", "javascriptreact" }
      for _, language in ipairs(js_based_languages) do
        dap.configurations[language] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to process",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-node",
            request = "launch",
            name = "Debug with ts-node",
            runtimeExecutable = "npx",
            runtimeArgs = { "ts-node" },
            program = "${file}",
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            resolveSourceMapLocations = {
              "${workspaceFolder}/**",
              "!**/node_modules/**",
            },
          },
          -- Jest test debugging
          {
            type = "pwa-node",
            request = "launch",
            name = "Debug Jest tests",
            runtimeExecutable = "npx",
            runtimeArgs = {
              "jest",
              "--runInBand",
              "--no-coverage",
              "${file}",
            },
            cwd = "${workspaceFolder}",
            console = "integratedTerminal",
            internalConsoleOptions = "neverOpen",
          },
          -- Vitest test debugging
          {
            type = "pwa-node",
            request = "launch",
            name = "Debug Vitest tests",
            runtimeExecutable = "npx",
            runtimeArgs = {
              "vitest",
              "run",
              "--no-coverage",
              "${file}",
            },
            cwd = "${workspaceFolder}",
            console = "integratedTerminal",
            internalConsoleOptions = "neverOpen",
          },
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch Chrome",
            url = "http://localhost:3000",
            webRoot = "${workspaceFolder}",
          },
        }
      end

      -- Rust is configured automatically by rustaceanvim with codelldb
      -- Use :RustLsp debuggables to debug tests
      -- Go is configured automatically by nvim-dap-go with delve
    end,
  },

  -- Ensure debug adapters are installed via Mason
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = {
      ensure_installed = {
        "codelldb", -- Rust (used by rustaceanvim)
        "delve", -- Go
        "js-debug-adapter", -- TypeScript/JavaScript
        -- netcoredbg handled by netcoredbg-macOS-arm64.nvim plugin above
      },
      handlers = {
        -- Let rustaceanvim handle codelldb configuration
        codelldb = function() end,
        -- Let nvim-dap-go handle delve configuration
        delve = function() end,
      },
    },
  },
}
