-- The one provider that needs more than declarative steps: the full template list has to
-- be asked of the SDK, and some templates live in a NuGet pack that may not be installed.
-- Both are custom `ask` steps, gated by `when`, so each stands on its own.

local ui = require "configs.newproject.ui"

-- The template table is parsed by slicing on its ruler, so the output has to be the
-- English one; a localized header would shift every column. NOLOGO keeps the first-run
-- welcome banner out of the parse.
local ENV = { DOTNET_CLI_UI_LANGUAGE = "en", DOTNET_NOLOGO = "1" }

local ALL = "*"

-- Hand-picked, in rough order of how often they are wanted. `sln` is here rather than in
-- the queried list because it is not of type `project` -- `dotnet new list --type
-- solution` matches nothing at all.
local TEMPLATES = {
  { label = "Web API", value = "webapi" },
  { label = "Azure Functions (isolated worker)", value = "func" },
  { label = "Console App", value = "console" },
  { label = "Class Library", value = "classlib" },
  { label = "Blazor Web App", value = "blazor" },
  { label = "Blazor WebAssembly", value = "blazorwasm" },
  { label = "Web App (MVC)", value = "mvc" },
  { label = "Web App (Razor Pages)", value = "webapp" },
  { label = "Worker Service", value = "worker" },
  { label = "gRPC Service", value = "grpc" },
  { label = "xUnit Test Project", value = "xunit" },
  { label = "Solution file (.slnx)", value = "sln" },
  { label = "All templates…", value = ALL },
}

-- Templates that ship in a NuGet pack rather than with the SDK, by short name.
local PACKAGES = {
  func = "Microsoft.Azure.Functions.Worker.ProjectTemplates",
}

-- `dotnet new list` prints a fixed-width table whose `----  ----  ----` ruler is the
-- authoritative column map -- the header row's own padding is not, and splitting on runs
-- of spaces breaks on names like "ASP.NET Core Web App (Razor Pages)".
---@param stdout string
---@return { label: string, value: string }[]
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
      items[#items + 1] = { label = ("%s  (%s)"):format(cell(1), short), value = short }
    end
  end
  return items
end

-- Swaps the ALL sentinel in ctx.template for a template picked from what is installed.
local function all_templates(ctx, done)
  ui.notify "Reading installed templates…"
  ui.system({ "dotnet", "new", "list", "--type", "project" }, { env = ENV }, function(res)
    if ctx.cancelled then
      return
    end
    local items = res.code == 0 and parse_templates(res.stdout) or {}
    if #items == 0 then
      ui.notify("Could not read the template list\n" .. ui.output(res), vim.log.levels.ERROR)
      return done(false)
    end
    ui.select("Template", items, function(choice)
      if not choice then
        return done(false)
      end
      ctx.template = choice.value
      done(true)
    end)
  end)
end

-- Probe first, and never install without asking: `dotnet new install` writes to
-- ~/.templateengine, which is a machine-global side effect, and it needs the network.
local function ensure_package(ctx, done)
  local short, pkg = ctx.template, PACKAGES[ctx.template]
  ui.notify("Looking for the " .. short .. " template…")
  ui.system({ "dotnet", "new", "list", short, "--type", "project" }, { env = ENV }, function(res)
    if ctx.cancelled then
      return
    end
    if res.code == 0 and #parse_templates(res.stdout) > 0 then
      return done(true)
    end
    ui.select(('The "%s" template is not installed'):format(short), {
      { label = "Install " .. pkg, install = true },
      { label = "Cancel" },
    }, function(choice)
      if not (choice and choice.install) then
        return done(false)
      end
      ui.notify("Installing " .. pkg .. "…")
      ui.system({ "dotnet", "new", "install", pkg }, { env = ENV, timeout = 300000 }, function(installed)
        if installed.code ~= 0 then
          ui.notify("Install failed\n" .. ui.output(installed), vim.log.levels.ERROR)
          return done(false)
        end
        done(true)
      end)
    end)
  end)
end

---@type NewProject.Provider
local M = {
  name = "Dotnet",
  icon = "\u{f031b} ", -- nf-md-language_csharp, the file tree's glyph for .cs
  bin = "dotnet",
  order = 10,

  steps = {
    { key = "template", prompt = "Template", choices = TEMPLATES },
    {
      ask = all_templates,
      when = function(ctx)
        return ctx.template == ALL
      end,
    },
    {
      ask = ensure_package,
      when = function(ctx)
        return PACKAGES[ctx.template] ~= nil
      end,
    },
  },

  -- -n explicitly rather than letting the directory name decide, so the project name is
  -- the one that was confirmed
  command = function(ctx)
    return { "dotnet", "new", ctx.template, "-n", ctx.name, "-o", "." }
  end,

  _parse_templates = parse_templates, -- for the tests
}

return M
