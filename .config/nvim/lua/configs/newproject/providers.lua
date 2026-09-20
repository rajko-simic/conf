-- Toolchains the New Project wizard can scaffold.
--
--   name      label in the first picker
--   icon      glyph prefix, two cells
--   bin       executable that must be on PATH; a missing one is shown disabled, not hidden
--   normalize optional, turns a typed name into one the toolchain will accept
--   steps     extra questions, asked in order after the name/target step
--   build     ctx -> argv, always run with cwd = ctx.dir, which exists by then
--   after     optional Lua to run after a successful scaffold
--   timeout   optional ms override, for toolchains that go and fetch packages
--
-- Every provider builds a `.`-relative command and the runner runs it inside the target
-- directory, having created that directory first. That collapses "scaffold in place" and
-- "scaffold into a subfolder" into one case, and works around `go mod init`, the only one
-- of the four that cannot create its own directory.
--
-- A step's `ask` writes into ctx and answers with a boolean -- see the note on the runner
-- in init.lua for why it is not a value.

local ui = require "configs.newproject.ui"

local M = {}

------------------------------------------------------------------------------- dotnet

-- The template table is parsed by slicing on its ruler, so the output has to be the
-- English one; a localized header would shift every column. NOLOGO keeps the first-run
-- welcome banner out of the parse.
local DOTNET_ENV = { DOTNET_CLI_UI_LANGUAGE = "en", DOTNET_NOLOGO = "1" }

-- Hand-picked, in rough order of how often they are wanted. `sln` is here rather than in
-- the queried list because it is not of type `project` -- `dotnet new list --type
-- solution` matches nothing at all.
local DOTNET_TEMPLATES = {
  { label = "Web API", short = "webapi" },
  -- Not installed on this machine; picking it offers to install the package first.
  {
    label = "Azure Functions (isolated worker)",
    short = "func",
    pkg = "Microsoft.Azure.Functions.Worker.ProjectTemplates",
  },
  { label = "Console App", short = "console" },
  { label = "Class Library", short = "classlib" },
  { label = "Blazor Web App", short = "blazor" },
  { label = "Blazor WebAssembly", short = "blazorwasm" },
  { label = "Web App (MVC)", short = "mvc" },
  { label = "Web App (Razor Pages)", short = "webapp" },
  { label = "Worker Service", short = "worker" },
  { label = "gRPC Service", short = "grpc" },
  { label = "xUnit Test Project", short = "xunit" },
  { label = "Solution file (.slnx)", short = "sln" },
  { label = "All templates…", all = true },
}

-- `dotnet new list` prints a fixed-width table whose `----  ----  ----` ruler is the
-- authoritative column map -- the header row's own padding is not, and splitting on runs
-- of spaces breaks on names like "ASP.NET Core Web App (Razor Pages)".
---@param stdout string
---@return table[]
local function parse_templates(stdout)
  local lines = vim.split(stdout or "", "\n", { plain = true })

  local ruler, cols
  for i, line in ipairs(lines) do
    if line:match "^%-%-%-+[%-%s]*$" then
      ruler, cols = i, {}
      local pos = 1
      while true do
        local s, e = line:find("%-+", pos)
        if not s then
          break
        end
        cols[#cols + 1] = { s, e }
        pos = e + 1
      end
      break
    end
  end
  if not ruler or #cols < 2 then
    return {}
  end

  local items = {}
  for i = ruler + 1, #lines do
    local line = lines[i]
    local function cell(n)
      return cols[n] and vim.trim(line:sub(cols[n][1], cols[n][2])) or ""
    end

    -- string.sub counts bytes, so a non-ASCII template name from some third-party pack
    -- would desync every later column on that row. Whitespace inside what should be a
    -- short name is the tell; drop the row rather than invent a template from it.
    local short = cell(2):match "^[^,]*"
    if short ~= "" and not short:find "%s" then
      items[#items + 1] = { label = ("%s  (%s)"):format(cell(1), short), short = short }
    end
  end
  return items
end

---@param cb fun(ok: boolean)
local function dotnet_all_templates(ctx, cb)
  ui.notify "Reading installed templates…"
  vim.system({ "dotnet", "new", "list", "--type", "project" }, { text = true, env = DOTNET_ENV }, function(res)
    vim.schedule(function()
      local items = res.code == 0 and parse_templates(res.stdout) or {}
      if #items == 0 then
        ui.notify("Could not read the template list\n" .. ui.output(res), vim.log.levels.ERROR)
        return cb(false)
      end
      ui.select("Template", items, function(choice)
        if not choice then
          return cb(false)
        end
        ctx.template, ctx.label = choice.short, choice.label
        cb(true)
      end)
    end)
  end)
end

-- Curated entries may name a NuGet package that carries them. Probe first, and never
-- install without asking: `dotnet new install` writes to ~/.templateengine, which is a
-- machine-global side effect, and it needs the network.
---@param cb fun(ok: boolean)
local function ensure_template(ctx, entry, cb)
  ui.notify("Looking for the " .. entry.short .. " template…")
  vim.system(
    { "dotnet", "new", "list", entry.short, "--type", "project" },
    { text = true, env = DOTNET_ENV },
    function(res)
      vim.schedule(function()
        if res.code == 0 and #parse_templates(res.stdout) > 0 then
          return cb(true)
        end
        ui.select(entry.label .. " is not installed", {
          { label = "Install " .. entry.pkg, install = true },
          { label = "Cancel" },
        }, function(choice)
          if not choice or not choice.install then
            return cb(false)
          end
          ui.notify("Installing " .. entry.pkg .. "…")
          vim.system(
            { "dotnet", "new", "install", entry.pkg },
            { text = true, env = DOTNET_ENV, timeout = 300000 },
            function(installed)
              vim.schedule(function()
                if installed.code ~= 0 then
                  ui.notify("Install failed\n" .. ui.output(installed), vim.log.levels.ERROR)
                  return cb(false)
                end
                cb(true)
              end)
            end
          )
        end)
      end)
    end
  )
end

local function dotnet_template(ctx, cb)
  ui.select("Template", DOTNET_TEMPLATES, function(choice)
    if not choice then
      return cb(false)
    end
    if choice.all then
      return dotnet_all_templates(ctx, cb)
    end
    ctx.template, ctx.label = choice.short, choice.label
    if choice.pkg then
      return ensure_template(ctx, choice, cb)
    end
    cb(true)
  end)
end

--------------------------------------------------------------------------------- rust

local function rust_kind(ctx, cb)
  ui.select("Crate type", {
    { label = "Binary (application)", flag = "--bin" },
    { label = "Library", flag = "--lib" },
  }, function(choice)
    if not choice then
      return cb(false)
    end
    ctx.kind, ctx.label = choice.flag, choice.label
    cb(true)
  end)
end

----------------------------------------------------------------------------------- go

-- Prefix offered in the module-path prompt. Set it once to your own host and user and
-- every new Go project gets a usable default; empty just offers the project name, which
-- is a valid module path for something that is never published.
local GO_MODULE_PREFIX = ""

local function go_module(ctx, cb)
  local default = GO_MODULE_PREFIX ~= "" and (GO_MODULE_PREFIX .. "/" .. ctx.name) or ctx.name
  ui.input("Module path", default, function(value)
    if not value then
      return cb(false)
    end
    if value:find "%s" then
      ui.notify("A module path cannot contain spaces", vim.log.levels.WARN)
      return go_module(ctx, cb)
    end
    ctx.module = value
    cb(true)
  end)
end

-- `go mod init` leaves nothing but a go.mod, and Go has no scaffolder of its own, so the
-- entry point is written here. Never overwrites: the in-place path can land in a
-- directory that already has one.
local function go_main(ctx)
  local main = ctx.dir .. "/main.go"
  if vim.uv.fs_stat(main) then
    return
  end
  local src = table.concat({
    "package main",
    "",
    'import "fmt"',
    "",
    "func main() {",
    ('\tfmt.Println("hello, %s")'):format(ctx.name),
    "}",
    "",
  }, "\n")
  local fd = assert(vim.uv.fs_open(main, "w", 420)) -- 0644
  vim.uv.fs_write(fd, src)
  vim.uv.fs_close(fd)
end

------------------------------------------------------------------------------ flutter

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

-- --platforms is only accepted for the app and plugin templates.
local FLUTTER_PLATFORMS = {
  { label = "All platforms" }, -- no `value`: the flag is left off entirely
  { label = "Mobile (android, ios)", value = "android,ios" },
  { label = "Desktop (linux, windows, macos)", value = "linux,windows,macos" },
  { label = "Web", value = "web" },
  { label = "Linux", value = "linux" },
  { label = "Android", value = "android" },
}

local function flutter_template(ctx, cb)
  ui.select("Flutter template", {
    { label = "Application", value = "app" },
    { label = "Package", value = "package" },
    { label = "Plugin", value = "plugin" },
    { label = "Module", value = "module" },
  }, function(choice)
    if not choice then
      return cb(false)
    end
    ctx.template, ctx.label = choice.value, choice.label
    cb(true)
  end)
end

local function flutter_platforms(ctx, cb)
  ui.select("Platforms", FLUTTER_PLATFORMS, function(choice)
    if not choice then
      return cb(false)
    end
    ctx.platforms = choice.value
    cb(true)
  end)
end

--------------------------------------------------------------------------------------

M.list = {
  {
    name = "Dotnet",
    icon = "󰌛 ",
    bin = "dotnet",
    steps = { { ask = dotnet_template } },
    build = function(ctx)
      -- -n explicitly rather than letting the directory name decide, so the project name
      -- is the one that was confirmed
      return { "dotnet", "new", ctx.template, "-n", ctx.name, "-o", "." }
    end,
  },

  {
    name = "Rust",
    icon = " ",
    bin = "cargo",
    normalize = function(s)
      return (s:lower():gsub("[^%w_%-]", "-"))
    end,
    steps = { { ask = rust_kind } },
    -- `cargo init` rather than `cargo new`, because the directory already exists. It
    -- skips its own `git init` when the parent is already a repository, which is right.
    build = function(ctx)
      return { "cargo", "init", ctx.kind, "--name", ctx.name }
    end,
  },

  {
    name = "Flutter",
    icon = " ",
    bin = "flutter",
    normalize = dart_name,
    steps = {
      { ask = flutter_template },
      {
        ask = flutter_platforms,
        when = function(ctx)
          return ctx.template == "app" or ctx.template == "plugin"
        end,
      },
    },
    build = function(ctx)
      local argv = { "flutter", "create", "--project-name", ctx.name, "-t", ctx.template }
      if ctx.platforms then
        argv[#argv + 1] = "--platforms"
        argv[#argv + 1] = ctx.platforms
      end
      argv[#argv + 1] = "."
      return argv
    end,
    -- it runs `pub get`, which is a network round trip
    timeout = 240000,
  },

  {
    name = "Go",
    icon = " ",
    bin = "go",
    -- the only provider that needs the name up front: the module path defaults off it
    name_first = true,
    steps = { { ask = go_module } },
    build = function(ctx)
      return { "go", "mod", "init", ctx.module }
    end,
    after = go_main,
  },
}

-- exported for the headless tests
M._parse_templates = parse_templates
M._dart_name = dart_name

return M
