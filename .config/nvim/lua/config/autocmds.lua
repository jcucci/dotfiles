-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Re-sign treesitter parsers after compilation (macOS code signing requirement)
if vim.fn.has("mac") == 1 then
  vim.api.nvim_create_autocmd("User", {
    pattern = "TSUpdate",
    group = vim.api.nvim_create_augroup("codesign_parsers", { clear = true }),
    callback = function()
      local parser_dir = vim.fn.stdpath("data") .. "/site/parser"
      vim.fn.jobstart(
        { "sh", "-c", string.format('find "%s" -name "*.so" -exec codesign --force --sign - {} \\;', parser_dir) },
        { detach = true }
      )
    end,
  })
end
