local ok, project = pcall(require, "project_nvim")
if not ok then return end

project.setup({
  manual_mode = false,
  silent_chdir = false,
  detection_methods = { "lsp", "pattern" },
  patterns = { ".csproj", ".sln", "Cargo.toml", "go.mod", ".git" },
})

