---@type vim.lsp.Config
return {
  cmd = { "emmet-ls", "--stdio" },
  filetypes = { "html", "css", "scss", "javascriptreact", "typescriptreact" },
  root_markers = { ".git" },
}
