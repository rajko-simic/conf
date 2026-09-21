require("easy-dotnet").setup {
  test_runner = {
    neotest_integration = true,
  },
  lsp = {
    enabled = true,
    roslynator_enabled = true,
    config = {
      settings = {
        ["csharp|background_analysis"] = {
          dotnet_analyzer_diagnostics_scope = "openFiles",
          dotnet_compiler_diagnostics_scope = "fullSolution",
        },
        ["csharp|code_lens"] = {
          dotnet_enable_references_code_lens = false,
          dotnet_enable_tests_code_lens = false,
        },
      },
    },
  },
}
