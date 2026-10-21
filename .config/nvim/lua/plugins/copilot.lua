return {
  -- Copilot core - provides the LSP backend
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = { enabled = true },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
      },
    },
  },

  -- blink-copilot kept as dependency but no longer used as a blink source
  {
    "fang2hou/blink-copilot",
    enabled = false,
  },
}
