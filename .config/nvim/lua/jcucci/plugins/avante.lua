return {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false, -- set this if you want to always pull the latest change
    opts = {
        provider = "gemini",
        behaviour = {
            auto_suggestions = false,
        },
        file_selector = {
            provider = "fzf",
            provider_opts = {},
        },
        gemini = {
            endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
            model = "gemini-2.0-flash",
            timeout = 30000, -- Timeout in milliseconds
            temperature = 1,
            max_tokens = 100000,
        },
    },
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = "make",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "stevearc/dressing.nvim",
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    },
}
