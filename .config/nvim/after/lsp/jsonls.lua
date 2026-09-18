-- Upstream sets no `settings` at all; this wires up schemastore.
-- Inherited: cmd (prefers a project-local binary), filetypes, init_options, root_markers.
---@type vim.lsp.Config
return {
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
}
