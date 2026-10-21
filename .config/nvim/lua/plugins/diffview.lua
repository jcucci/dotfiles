-- diffview.nvim - Git merge conflict resolution and diff viewer
-- Keybinds follow the <leader>gc* pattern for conflict operations
return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  keys = {
    -- Main diffview commands under <leader>gd
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
    { "<leader>gD", "<cmd>DiffviewOpen HEAD~1<cr>", desc = "Diffview HEAD~1" },
    { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
    { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (current)" },
    { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "File History (all)" },
    -- Conflict-specific: open diffview in merge mode (during active merge/rebase)
    { "<leader>gm", "<cmd>DiffviewOpen<cr>", desc = "Merge Tool" },
  },
  opts = {
    enhanced_diff_hl = true, -- Better diff highlighting
    view = {
      default = {
        layout = "diff2_horizontal",
        disable_diagnostics = false,
        winbar_info = false,
      },
      merge_tool = {
        -- 3-way diff for merge conflicts: OURS | BASE | THEIRS with MERGED below
        layout = "diff3_mixed",
        disable_diagnostics = true,
        winbar_info = true, -- Show which version is which in winbar
      },
      file_history = {
        layout = "diff2_horizontal",
        disable_diagnostics = false,
        winbar_info = false,
      },
    },
    file_panel = {
      listing_style = "tree",
      tree_options = {
        flatten_dirs = true,
        folder_statuses = "only_folded",
      },
      win_config = {
        position = "left",
        width = 35,
      },
    },
    keymaps = {
      disable_defaults = false, -- Keep defaults, we're extending them
      view = {
        -- Conflict resolution with <leader>gc* prefix (matches our unified keybind plan)
        { "n", "<leader>gco", "<cmd>lua require('diffview.actions').conflict_choose('ours')()<cr>", { desc = "Conflict: Choose OURS" } },
        { "n", "<leader>gct", "<cmd>lua require('diffview.actions').conflict_choose('theirs')()<cr>", { desc = "Conflict: Choose THEIRS" } },
        { "n", "<leader>gcb", "<cmd>lua require('diffview.actions').conflict_choose('base')()<cr>", { desc = "Conflict: Choose BASE" } },
        { "n", "<leader>gca", "<cmd>lua require('diffview.actions').conflict_choose('all')()<cr>", { desc = "Conflict: Choose ALL" } },
        { "n", "<leader>gcn", "<cmd>lua require('diffview.actions').conflict_choose('none')()<cr>", { desc = "Conflict: Choose NONE" } },
        -- Whole file conflict resolution
        { "n", "<leader>gcO", "<cmd>lua require('diffview.actions').conflict_choose_all('ours')()<cr>", { desc = "Conflict: Choose OURS (whole file)" } },
        { "n", "<leader>gcT", "<cmd>lua require('diffview.actions').conflict_choose_all('theirs')()<cr>", { desc = "Conflict: Choose THEIRS (whole file)" } },
        { "n", "<leader>gcB", "<cmd>lua require('diffview.actions').conflict_choose_all('base')()<cr>", { desc = "Conflict: Choose BASE (whole file)" } },
        { "n", "<leader>gcA", "<cmd>lua require('diffview.actions').conflict_choose_all('all')()<cr>", { desc = "Conflict: Choose ALL (whole file)" } },
        { "n", "<leader>gcN", "<cmd>lua require('diffview.actions').conflict_choose_all('none')()<cr>", { desc = "Conflict: Choose NONE (whole file)" } },
        -- Quick close
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
      },
      file_panel = {
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
      },
      file_history_panel = {
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
      },
    },
  },
}
