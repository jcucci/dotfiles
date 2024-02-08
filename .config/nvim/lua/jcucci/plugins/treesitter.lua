return {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
        local treesitter = require("nvim-treesitter.configs")

        treesitter.setup({
            highlight = { enable = true },
            indent = { enable = true },
            ensure_installed = {
                "json",
                "javascript",
                "typescript",
                "tsx",
                "yaml",
                "html",
                "css",
                "markdown",
                "markdown_inline",
                "bash",
                "lua",
                "vim",
                "dockerfile",
                "gitignore",
                "c_sharp",
                "go",
                "rust",
                "toml",
                "zig"
            },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<leader>ts",
                    node_incremental = "<leader>tn",
                    scope_incremental = false,
                    node_decremental = "<leader>tp",
                },
            },
        })
    end
}
