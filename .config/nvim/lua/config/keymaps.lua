-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Unified run command across languages
local function run_file()
  local ft = vim.bo.filetype
  local runners = {
    cs = function()
      vim.cmd("Dotnet run")
    end,
    rust = function()
      vim.cmd("RustLsp runnables")
    end,
    go = function()
      vim.cmd("!go run " .. vim.fn.expand("%"))
    end,
    typescript = function()
      vim.cmd("!npx tsx " .. vim.fn.expand("%"))
    end,
    javascript = function()
      vim.cmd("!node " .. vim.fn.expand("%"))
    end,
    lua = function()
      vim.cmd("source %")
    end,
    sh = function()
      vim.cmd("!bash " .. vim.fn.expand("%"))
    end,
    bash = function()
      vim.cmd("!bash " .. vim.fn.expand("%"))
    end,
  }
  local runner = runners[ft]
  if runner then
    runner()
  else
    vim.notify("No runner configured for " .. ft, vim.log.levels.WARN)
  end
end

-- Unified build command
local function build_project()
  local ft = vim.bo.filetype
  local builders = {
    cs = function()
      vim.cmd("Dotnet build")
    end,
    rust = function()
      vim.cmd("!cargo build")
    end,
    go = function()
      vim.cmd("!go build ./...")
    end,
    typescript = function()
      vim.cmd("!npm run build")
    end,
  }
  local builder = builders[ft]
  if builder then
    builder()
  else
    vim.notify("No build configured for " .. ft, vim.log.levels.WARN)
  end
end

vim.keymap.set("n", "<leader>rr", run_file, { desc = "Run file/project" })
-- Test keymaps removed - using neotest instead (<leader>t*)
vim.keymap.set("n", "<leader>rb", build_project, { desc = "Build project" })

-- Window resize with Ctrl+Shift+hjkl
vim.keymap.set("n", "<C-S-h>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-S-l>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })
vim.keymap.set("n", "<C-S-j>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-S-k>", "<cmd>resize +2<cr>", { desc = "Increase window height" })

-- Floating terminal (replaces default split terminals)
vim.keymap.set({ "n", "t" }, "<C-\\>", function()
  Snacks.terminal.toggle(nil, {
    win = {
      style = "float",
      border = "rounded",
      width = 0.7,
      height = 0.7,
    },
  })
end, { desc = "Toggle floating terminal" })

-- Remove default terminal keymaps (using wezterm for splits instead)
vim.keymap.del({ "n", "t" }, "<C-/>")
vim.keymap.del("n", "<leader>ft")
vim.keymap.del("n", "<leader>fT")
