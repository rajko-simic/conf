-- Point at the mason-installed PowerShellEditorServices bundle. Upstream instead
-- discovers the module by shelling out to `pwsh`, which is not installed here, so its
-- cmd would fail to resolve.
-- Inherited: filetypes, root_markers, init_options.
---@type vim.lsp.Config
return {
  cmd = function(dispatchers)
    local bundle_path = vim.fn.stdpath "data" .. "/mason/packages/powershell-editor-services"
    local temp_path = vim.fn.stdpath "cache"
    local command = string.format(
      [[& '%s/PowerShellEditorServices/Start-EditorServices.ps1' -BundledModulesPath '%s' -LogPath '%s/powershell_es.log' -SessionDetailsPath '%s/powershell_es.session.json' -FeatureFlags @() -AdditionalModules @() -HostName nvim -HostProfileId 0 -HostVersion 1.0.0 -Stdio -LogLevel Normal]],
      bundle_path,
      bundle_path,
      temp_path,
      temp_path
    )
    return vim.lsp.rpc.start({ "pwsh", "-NoLogo", "-NoProfile", "-Command", command }, dispatchers)
  end,
}
