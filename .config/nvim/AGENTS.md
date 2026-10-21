# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a LazyVim-based Neovim configuration. LazyVim is a Neovim setup powered by lazy.nvim that provides sensible defaults and a plugin ecosystem. The official documentation is at https://lazyvim.github.io.

## Architecture

```
init.lua              # Entry point - loads config.lazy
lua/
  config/
    lazy.lua          # lazy.nvim bootstrap and plugin setup
    options.lua       # Vim options (extends LazyVim defaults)
    keymaps.lua       # Custom keymaps (extends LazyVim defaults)
    autocmds.lua      # Autocommands (extends LazyVim defaults)
  plugins/
    *.lua             # Plugin specs - each file is auto-loaded by lazy.nvim
```

## Key Concepts

- **Plugin specs** in `lua/plugins/` are automatically loaded by lazy.nvim
- Config files in `lua/config/` extend LazyVim's defaults (not replace them)
- LazyVim defaults are at: https://github.com/LazyVim/LazyVim/tree/main/lua/lazyvim/config
- To disable a LazyVim plugin: `{ "plugin/name", enabled = false }`
- To modify a LazyVim plugin: use `opts` to merge or `opts = function(_, opts)` to extend

## Common Commands

- `:Lazy` - Open lazy.nvim UI (install/update/clean plugins)
- `:LazyExtras` - Enable/disable LazyVim extras (language support, UI features)
- `:Mason` - Manage LSP servers, formatters, linters
- `:checkhealth` - Diagnose issues with Neovim/plugins

## Adding Functionality

- **New plugin**: Create a file in `lua/plugins/` returning a plugin spec table
- **Language support**: Use `:LazyExtras` to enable built-in language extras (e.g., `lang.typescript`, `lang.python`)
- **LSP server**: Add to nvim-lspconfig opts or use Mason
- **Keymaps**: Add to `lua/config/keymaps.lua`
- **Options**: Add to `lua/config/options.lua`
