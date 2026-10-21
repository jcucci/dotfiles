return {
  {
    "saghen/blink.cmp",
    opts = {
      -- Use Rust fuzzy matcher for better performance
      fuzzy = { implementation = "prefer_rust_with_warning" },

      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        -- Add easy-dotnet source for C# files
        per_filetype = {
          cs = { "lsp", "easy-dotnet", "path", "snippets", "buffer" },
        },
        providers = {
          ["easy-dotnet"] = {
            name = "easy-dotnet",
            enabled = true,
            module = "easy-dotnet.completion.blink",
            score_offset = 10000, -- Prioritize .NET completions
            async = true,
          },
        },
      },

      completion = {
        accept = {
          auto_brackets = { enabled = true },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
        ghost_text = { enabled = false },
      },

      signature = { enabled = true },

      keymap = {
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
      },
    },
  },
}
