-- schemastore instead of the server's built-in schema store, plus the Kubernetes
-- schema, which schemastore does not map onto arbitrary manifest paths.
-- Inherited: cmd (prefers a project-local binary), filetypes (upstream's list adds
-- yaml.helm-values, which helm charts need), root_markers.
local k8s = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/master-standalone-strict/all.json"

---@type vim.lsp.Config
return {
  settings = {
    yaml = {
      -- using schemastore.nvim instead
      schemaStore = { enable = false, url = "" },
      schemas = vim.tbl_extend("force", require("schemastore").yaml.schemas(), {
        [k8s] = {
          "*.k8s.yaml",
          "k8s/**/*.yaml",
          "k8s/**/*.yml",
          "manifests/**/*.yaml",
          "manifests/**/*.yml",
          "kube/**/*.yaml",
        },
      }),
    },
  },
}
