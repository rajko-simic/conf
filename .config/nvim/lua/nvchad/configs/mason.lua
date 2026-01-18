dofile(vim.g.base46_cache .. "mason")

return {
  PATH = "skip",
  ui = {
    icons = {
      package_pending = " ",
      package_installed = " ",
      package_uninstalled = " ",
    },
  },
  registries = {
      "github:mason-org/mason-registry",
      "github:Crashdummyy/mason-registry",
  },
  max_concurrent_installers = 10,
}
