-- Narrow emmet to where it is actually wanted; upstream lists ~17 filetypes
-- (astro, eruby, htmlangular, htmldjango, less, pug, sass, ...).
-- Inherited: cmd, root_markers.
---@type vim.lsp.Config
return {
  filetypes = { "html", "css", "scss", "javascriptreact", "typescriptreact" },
}
