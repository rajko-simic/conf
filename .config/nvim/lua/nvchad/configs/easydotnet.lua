require("easy-dotnet").setup({
  lsp = {
    enabled = true,                       -- Enable builtin roslyn lsp
    preload_roslyn = false,               -- Roslyn starts when a cs file is opened
    roslynator_enabled = true,            -- Automatically enable roslynator analyzer
    easy_dotnet_analyzer_enabled = true,  -- Enable roslyn analyzer from easy-dotnet-server
    auto_refresh_codelens = false,
    analyzer_assemblies = {},             -- Any additional roslyn analyzers e.g. SonarAnalyzer.CSharp
    config = {
      settings = {
        ["csharp|code_lens"] = {
          dotnet_enable_references_code_lens = false,
          dotnet_enable_tests_code_lens = false,
        },
        ["csharp|inlay_hints"] = {
          csharp_enable_inlay_hints_for_implicit_object_creation = true,
          csharp_enable_inlay_hints_for_implicit_variable_types = true,
          csharp_enable_inlay_hints_for_lambda_parameter_types = true,
          csharp_enable_inlay_hints_for_types = true,
          dotnet_enable_inlay_hints_for_parameters = true,
          dotnet_enable_inlay_hints_for_literal_parameters = true,
          dotnet_enable_inlay_hints_for_indexer_parameters = true,
          dotnet_enable_inlay_hints_for_object_creation_parameters = true,
          dotnet_enable_inlay_hints_for_other_parameters = true,
          dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = false,
          dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
          dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
        },
      },
    },
  },
})
