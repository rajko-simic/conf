-- nvim-lspconfig deliberately ships no `cmd` for bicep ("does not make assumptions about
-- your path"), so this file is what makes the server start at all.
-- Inherited: filetypes, init_options.
---@type vim.lsp.Config
return {
  cmd = { "bicep-lsp" },
  -- upstream marks a root with `.git` only, which misses standalone bicep dirs
  root_markers = { ".git", "*.bicepparam", "*.bicep" },
}
