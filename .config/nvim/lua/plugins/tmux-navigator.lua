-- vim-tmux-navigator: Seamless navigation between tmux panes and vim splits
-- Use Ctrl+h/j/k/l to navigate in both vim and tmux
return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
  },
  keys = {
    { "<c-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate Left (tmux/vim)" },
    { "<c-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate Down (tmux/vim)" },
    { "<c-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate Up (tmux/vim)" },
    { "<c-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate Right (tmux/vim)" },
  },
}
