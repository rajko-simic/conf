local ok, project = pcall(require, "project_nvim")
if not ok then return end

project.setup({
  manual_mode = false,
  silent_chdir = false,
  display_type = 'full',
  sync_with_nvim_tree = true,
  detection_methods = { "pattern", "lsp" },
  patterns = { "." },
})
