return {
    "folke/trouble.nvim",
    lazy = false,
    cmd = "Trouble",
    keys = {
        -- {
        --     "<leader>D",
        --     "<cmd>Trouble diagnostics toggle win.size=.25 preview.type=split preview.relative=win preview.position=right preview.size=0.5 filter.severity=vim.diagnostic.severity.ERROR<cr>",
        --     desc = "Diagnostics (Trouble)",
        -- },
        {
            "<leader>cs",
            "<cmd>Trouble symbols toggle focus=false<cr>",
            desc = "Symbols (Trouble)",
        },
        -- {
        --     "<leader>gr",
l       --     "<cmd>Trouble lsp_references toggle focus=true win.size=.25 preview.type=split preview.relative=win preview.position=right preview.size=0.5<cr>",
        --     desc = "LSP Definitions / references / ... (Trouble)",
        -- },
    },
    config = function()
        local trouble = require("trouble")

        local lspOpts = {
            focus = true,
            win = {
                size = 0.25
            },
            preview = {
                type = "split",
                relative = "win",
                position = "right",
                size = 0.5
            },
            keys = {
                ["<cr>"] = "jump_close",
                ["<c-v>"] = "jump_vsplit_close",
                ["<c-h>"] = "jump_split_close",
            }
        }

        local diagOpts = {
            follow = true,
            win = {
                size = .25,
            },
            -- preview = {
            --     type = "split",
            --     relative = "win",
            --     position = "right",
            --     size = 0.5,
            -- },
            filter = {
                severity = { vim.diagnostic.severity.WARN, vim.diagnostic.severity.ERROR }
            }
        }

        local showDiagnostics = function()
            local diagnosticOpts = vim.deepcopy(diagOpts)
            diagnosticOpts.mode = "diagnostics"
            trouble.toggle(diagnosticOpts)
        end

        local showQuicklist = function()
            local quickfixOpts = vim.deepcopy(diagOpts)
            quickfixOpts.mode = "quickfix"
            trouble.toggle(quickfixOpts)
        end

        local gotoReferences = function()
            local referencesOpts = vim.deepcopy(lspOpts)
            referencesOpts.mode = "lsp_references"
            trouble.open(referencesOpts)
        end

        local gotoDefinitions = function()
            local definitionsOpts = vim.deepcopy(lspOpts)
            definitionsOpts.mode = "lsp_definitions"
            trouble.open(definitionsOpts)
        end

        local gotoImplementations = function()
            local implementationsOpts  = vim.deepcopy(lspOpts)
            implementationsOpts.mode = "lsp_implementations"
            trouble.open(implementationsOpts)
        end

        vim.keymap.set("n", "<leader>qa", showDiagnostics, { desc = "Show Diagnostics" } ) 
        vim.keymap.set("n", "<leader>qq", showQuicklist, { desc = "Show Quick Fix List" } ) 
        vim.keymap.set("n", "gr", gotoReferences, { desc = "Go to references" } ) 
        vim.keymap.set("n", "gd", gotoDefinitions, { desc = "Go to definitions" } ) 
        vim.keymap.set("n", "gi", gotoImplementations, { desc = "Go to implementations" } ) 
        vim.keymap.set("n", "<A-n>", function()
            trouble.next()
            trouble.jump()
        end, { desc = "Next Trouble" } ) 
        vim.keymap.set("n", "<A-p>", function()
            trouble.prev()
            trouble.jump()
        end, { desc = "Previous Trouble" } ) 

    end,
}
