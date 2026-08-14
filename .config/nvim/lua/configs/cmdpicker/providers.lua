-- Toolchain providers for the project command picker.
--
-- Adding a language means adding one entry here; init.lua never changes.
--
--   name     label shown when more than one provider matches
--   plugin   lazy.nvim plugin to force-load before running anything
--   ensure   optional extra step to make the plugin's commands exist
--   lsp      LSP client name that also implies this toolchain is active
--   match    predicate over a filename, searched upward from the buffer/cwd
--   commands opens the toolchain's own command picker

local function ends_with(name, suffix)
  return name:sub(-#suffix) == suffix
end

return {
  {
    name = "dotnet",
    plugin = "easy-dotnet.nvim",
    lsp = "easy_dotnet",
    match = function(name)
      return ends_with(name, ".sln") or ends_with(name, ".slnx") or ends_with(name, ".csproj")
    end,
    commands = function() vim.cmd "Dotnet" end,
  },

  {
    name = "flutter",
    plugin = "flutter-tools.nvim",
    -- flutter-tools only registers its commands on BufEnter of a dart file or
    -- pubspec.yaml, so fire that autocmd ourselves when we came from elsewhere.
    ensure = function()
      if vim.fn.exists ":FlutterRun" ~= 2 then
        vim.api.nvim_exec_autocmds("BufEnter", { group = "FlutterToolsGroup", pattern = "pubspec.yaml" })
      end
    end,
    lsp = "dartls",
    match = function(name) return name == "pubspec.yaml" end,
    commands = function()
      pcall(require("telescope").load_extension, "flutter")
      vim.cmd "Telescope flutter commands"
    end,
  },
}
