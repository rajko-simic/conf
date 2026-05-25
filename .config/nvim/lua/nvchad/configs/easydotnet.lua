require("easy-dotnet").setup {
  lsp = {
    enabled = true,
    roslynator_enabled = true,
    config = {
      settings = {
        ["csharp|background_analysis"] = {
          dotnet_analyzer_diagnostics_scope = "openFiles",
          dotnet_compiler_diagnostics_scope = "fullSolution",
        },
      },
    },
  },
}
