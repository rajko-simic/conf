---@type vim.lsp.Config
return {
  cmd = { "bicep-lsp" },
  filetypes = { "bicep", "bicep-params" },
  root_markers = { ".git", "*.bicepparam", "*.bicep" },
}
