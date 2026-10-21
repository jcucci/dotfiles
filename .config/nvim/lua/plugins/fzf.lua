return {
  {
    "ibhagwan/fzf-lua",
    keys = {
      { "<C-j>", "<Down>", ft = "fzf", mode = "t", nowait = true },
      { "<C-k>", "<Up>", ft = "fzf", mode = "t", nowait = true },
    },
    opts = {
      files = {
        fd_opts = "--type f --hidden --follow --exclude .git --exclude api-tests",
      },
      grep = {
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden -g '!.git' -g '!api-tests'",
      },
      lsp = {
        async_or_timeout = true, -- Async mode, window shows immediately
      },
      fzf_opts = {
        ["--info"] = "default", -- Shows loading indicator
      },
    },
  },
}
