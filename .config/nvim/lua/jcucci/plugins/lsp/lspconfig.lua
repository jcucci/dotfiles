return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "saghen/blink.cmp",
        "seblj/roslyn.nvim",
        { "antosha417/nvim-lsp-file-operations", config = true }
    },
    config = function()
        local roslyn = require("roslyn")
        local blink_cmp = require("blink.cmp")
        local lspconfig = require("lspconfig")
        local builder = require("jcucci.core.makes.builder")
        local runners = require("jcucci.core.testers.runners")
        local keymap = vim.keymap -- for conciseness
        local opts = { noremap = true, silent = true }
        local snyk_token = os.getenv("SNYK_TOKEN")

        local function code_action_current_line()
            local line = vim.api.nvim_win_get_cursor(0)[1]
            local line_text = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1] or ""

            local range = {
                start = {line, 1},
                ['end'] = {line, #line_text}
            }

            vim.lsp.buf.code_action({
                range = range,
                context = { only = {"quickfix"} }
            })
        end

        local on_attach = function(client, bufnr)

            opts.buffer = bufnr

            opts.desc = "Compile workspace"
            keymap.set({ "n", "v" }, "<leader>bb", function() builder.compile_project(false) end, opts)

            opts.desc = "Compile workspace (Full)"
            keymap.set({ "n", "v" }, "<leader>B", function() builder.compile_project(true) end, opts)

            opts.desc = "Run Tests"
            keymap.set({ "n", "v" }, "<leader>tt", runners.run_tests, opts)

            opts.desc = "Run Tests (Full)"
            keymap.set({ "n", "v" }, "<leader>T", runners.run_tests, opts)

            opts.desc = "See available code actions"
            keymap.set({ "n", "v" }, "<leader>ca", code_action_current_line, opts)

            opts.desc = "Smart rename"
            keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

            opts.desc = "Go to previous diagnostic"
            keymap.set("n", "<leader>dp", function() vim.diagnostic.goto_prev( { serverity = vim.diagnostic.severity.ERROR } ) end, opts) -- jump to previous diagnostic in buffer

            opts.desc = "Go to next diagnostic"
            keymap.set("n", "<leader>dn", function() vim.diagnostic.goto_next( { serverity = vim.diagnostic.severity.ERROR } ) end, opts) -- jump to next diagnostic in buffer

            opts.desc = "Show documentation for what is under cursor"
            keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

            opts.desc = "Restart LSP"
            keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary

            opts.desc = "Format document"
            keymap.set("n", "<leader>fm",
                function()
                    vim.lsp.buf.format { async = true }
                end, opts)
        end

        local capabilities = blink_cmp.get_lsp_capabilities()

        local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
        for type, icon in pairs(signs) do
            local hl = "DiagnosticSign" .. type
            vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
        end

        vim.opt.updatetime = 250

        vim.diagnostic.config({
            update_in_insert = true,
            virtual_text = true,
            underline = false,
            severity_sort = true
        })

        -- configure html server
        lspconfig["html"].setup({
            capabilities = capabilities,
            on_attach = on_attach,
        })

        -- configure css server
        lspconfig["cssls"].setup({
            capabilities = capabilities,
            on_attach = on_attach,
        })

        lspconfig["snyk_ls"].setup({
            capabilities = capabilities,
            on_attach = on_attach,
            token = snyk_token
        })

        roslyn.setup({
            broad_search = true,
            choose_target = function(sln)
                return vim.iter(sln):find(function(item)
                    if not string.find(item, "Tests", 1, true) then
                        return item
                    end
                end)
            end,
            config = {
                capabilities = capabilities,
                filetypes = { 'cs' },
                on_attach = on_attach,
                settings = {
                    ["csharp|background_analysis"] = {
                        dotnet_analyzer_diagnostics_scope = "fullSolution",
                        dotnet_compiler_diagnostics_scope = "fullSolution"
                    },
                    ["csharp|code_lens"] = {
                        dotnet_enable_references_code_lens = true,
                        dotnet_enable_tests_code_lens = true,
                    },
                    ["csharp|symbol_search"] = {
                        dotnet_search_reference_assemblies = true
                    }
                }
            }
        })

        -- lspconfig["omnisharp"].setup({
        --     capabilities = capabilities,
        --     on_attach = on_attach,
        --     cmd = { "dotnet", vim.fn.stdpath "data" .. "/mason/packages/omnisharp/libexec/OmniSharp.dll" },
        --     enable_import_completion = true,
        --     organize_imports_on_format = true,
        --     enable_roslyn_analyzers = true,
        --     root_dir = function ()
        --         return vim.loop.cwd() -- current working directory
        --     end,
        -- })
        --
        -- configure rust server
        lspconfig["rust_analyzer"].setup({
            capabilities = capabilities,
            on_attach = on_attach,
        })

        -- bash
        lspconfig["bashls"].setup({
            capabilities = capabilities,
            on_attach = on_attach,
        })

        -- configure zig server
        lspconfig["zls"].setup({
            capabilities = capabilities,
            on_attach = on_attach,
        })

        -- configure lua server (with special settings)
        lspconfig["lua_ls"].setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = { -- custom settings for lua
                Lua = {
                    -- make the language server recognize "vim" global
                    diagnostics = {
                        globals = { "vim" },
                    },
                    workspace = {
                        -- make language server aware of runtime files
                        library = {
                            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                            [vim.fn.stdpath("config") .. "/lua"] = true,
                        },
                    },
                },
            },
        })
    end,
}
