-- Upstream sets no root_markers, so the workspace root would fall back to the cwd.
-- Inherited: cmd (a function that prefers a project-local node_modules/.bin binary
-- over the global one -- deliberately not overridden), filetypes.
---@type vim.lsp.Config
return {
  root_markers = { "package.json", "tsconfig.json", ".git" },
}
