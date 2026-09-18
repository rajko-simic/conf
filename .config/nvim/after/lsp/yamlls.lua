-- Extra schema mappings layered on top of lsp/yamlls.lua's schemastore set.
--
-- `settings.yaml.schemas` is a map, so tbl_deep_extend merges these into the
-- schemastore table rather than replacing it. schemastore does not map the Kubernetes
-- schema onto arbitrary manifest paths, so that part is done by hand.
local k8s = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/master-standalone-strict/all.json"

---@type vim.lsp.Config
return {
  settings = {
    yaml = {
      schemas = {
        [k8s] = {
          "*.k8s.yaml",
          "k8s/**/*.yaml",
          "k8s/**/*.yml",
          "manifests/**/*.yaml",
          "manifests/**/*.yml",
          "kube/**/*.yaml",
        },
      },
    },
  },
}
