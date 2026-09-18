-- helm-ls spawns its *own* yaml-language-server for values files. This config already
-- runs yamlls (with schemastore + kubernetes schemas) on yaml.helm-values, so the
-- internal one is pure duplicate diagnostics. Turn it off and keep ours.
---@type vim.lsp.Config
return {
  settings = {
    ["helm-ls"] = {
      yamlls = { enabled = false },
    },
  },
}
