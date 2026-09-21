-- `flutter create` rejects anything that is not a valid Dart package identifier, and the
-- directory name is what it derives the package name from by default -- so a directory
-- called `my-app` is a hard error unless the name is sanitised and passed explicitly.
---@param s string
---@return string
local function dart_name(s)
  s = s:lower()
  s = s:gsub("[^%l%d_]", "_")
  s = s:gsub("_+", "_")
  s = s:gsub("^[_%d]+", "")
  s = s:gsub("_+$", "")
  return s ~= "" and s or "app"
end

---@type NewProject.Provider
local M = {
  name = "Flutter",
  icon = "\u{e798} ", -- nf-dev-dart, the file tree's glyph for .dart
  bin = "flutter",
  order = 30,
  normalize = dart_name,
  -- it runs `pub get`, which is a network round trip
  timeout = 240000,

  steps = {
    {
      key = "template",
      prompt = "Flutter template",
      choices = {
        { label = "Application", value = "app" },
        { label = "Package", value = "package" },
        { label = "Plugin", value = "plugin" },
        { label = "Module", value = "module" },
      },
    },
    {
      key = "platforms",
      prompt = "Platforms",
      -- --platforms is only accepted for these two templates
      when = function(ctx)
        return ctx.template == "app" or ctx.template == "plugin"
      end,
      choices = {
        { label = "All platforms" }, -- no `value`: the flag is left off entirely
        { label = "Mobile (android, ios)", value = "android,ios" },
        { label = "Desktop (linux, windows, macos)", value = "linux,windows,macos" },
        { label = "Web", value = "web" },
        { label = "Linux", value = "linux" },
        { label = "Android", value = "android" },
      },
    },
  },

  command = function(ctx)
    local argv = { "flutter", "create", "--project-name", ctx.name, "-t", ctx.template }
    if ctx.platforms then
      vim.list_extend(argv, { "--platforms", ctx.platforms })
    end
    argv[#argv + 1] = "."
    return argv
  end,

  _dart_name = dart_name, -- for the tests
}

return M
