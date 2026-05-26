---@type vim.lsp.Config
return {
  cmd = { "lemminx" },
  filetypes = { "xml", "xsd", "xsl", "xslt", "svg", "csproj", "props", "targets", "slnx" },
  root_markers = { ".git" },
}
