-- The contract a toolchain implements, and the registry that finds the implementations.
-- Nothing in here, or anywhere else outside providers/, knows about a particular toolchain.
--
-- To add one, drop a file into providers/ that returns a NewProject.Provider. That is the
-- whole job: it is discovered, checked against the contract below and listed in the menu.
-- providers/rust.lua is the shortest complete example.
--
-- A provider answers two questions. What to ask (`steps`, plain data: the wizard owns the
-- windows, cancelling and storing the answers) and what to run (`command`, the one
-- required function). Every answer lands in `ctx` under the step's `key`, and `command`
-- reads it back from there.

---@class NewProject.Ctx
---@field cwd string                      nvim's directory when the wizard was opened
---@field provider NewProject.Provider
---@field name string                     project name, already through `normalize`
---@field dir string                      absolute target directory; exists by `command` time
---@field argv string[]                   what `command` returned, once confirmed
---@field created boolean                 whether the wizard made `dir` itself
---@field cancelled? boolean              set when a newer wizard supersedes this one; a
---                                       slow custom step may check it before opening a window
---@field [string] any                    the answers, keyed by step.key

---@class NewProject.Provider
---@field name string                     menu label
---@field icon string                     "\u{xxxx} " escape, never a typed glyph: private-use
---                                       codepoints do not survive being pasted into a file
---@field bin string                      executable that must be on PATH; a missing one is
---                                       listed as "(bin not found)" rather than hidden
---@field command fun(ctx: NewProject.Ctx): string[]  argv, run with cwd = ctx.dir, so the
---                                       output path is always `.`. Must not be interactive:
---                                       stdin is not connected.
---@field steps? NewProject.Step[]        questions, asked in order (default: none)
---@field name_first? boolean             ask the project name before `steps` rather than
---                                       after, for a step that defaults off it
---@field normalize? fun(name: string): string  typed name -> one the toolchain accepts
---@field after? fun(ctx: NewProject.Ctx) runs once the command has succeeded
---@field timeout? integer                ms, for toolchains that go and fetch packages
---@field order? integer                  menu position; ties sort by name

-- A step is exactly one of three kinds, told apart by the fields it carries:
--   select   key + prompt + choices   ctx[key] = the chosen choice's `value`. A choice with
--                                     no `value` is a real answer ("leave the flag off"),
--                                     so `command` must not splice ctx[key] in blindly.
--   input    key + prompt             ctx[key] = the typed text; `default` pre-fills it and
--                                     `validate` returns an error message to ask again
--   custom   ask                      the escape hatch, for anything asynchronous or
--                                     multi-window. It writes into ctx itself and answers
--                                     done(true) to carry on, done(false) to abort.
---@class NewProject.Step
---@field key? string
---@field prompt? string
---@field when? fun(ctx: NewProject.Ctx): boolean  the step is skipped when this is false
---@field choices? { label: string, value?: any }[]
---@field default? string|fun(ctx: NewProject.Ctx): string
---@field validate? fun(value: string, ctx: NewProject.Ctx): string?
---@field ask? fun(ctx: NewProject.Ctx, done: fun(ok: boolean))

local M = {}

local GLOB = "lua/configs/newproject/providers/*.lua"
local MODULE = "configs.newproject.providers."

-- Merged under every provider, so the wizard never has to nil-check an optional member.
local DEFAULTS = {
  steps = {},
  name_first = false,
  normalize = function(name)
    return name
  end,
  after = function() end,
  timeout = 120000,
  order = 100,
}

----------------------------------------------------------------------------- contract

-- Lua has no compiler to say "does not implement the interface", so this plays one: a
-- misspelt optional member (`timout`) would otherwise be silently ignored, and a missing
-- required one would only surface as a nil call halfway through the wizard.

local REQUIRED = { "name", "icon", "bin", "command" }

local PROVIDER = {
  name = "string",
  icon = "string",
  bin = "string",
  command = "function",
  steps = "table",
  name_first = "boolean",
  normalize = "function",
  after = "function",
  timeout = "number",
  order = "number",
}

local STEP = {
  key = "string",
  prompt = "string",
  when = "function",
  choices = "table",
  default = { "string", "function" },
  validate = "function",
  ask = "function",
}

-- ctx fields the wizard owns; a step storing its answer under one would corrupt the run.
local RESERVED = { cwd = 1, provider = 1, name = 1, dir = 1, argv = 1, created = 1, cancelled = 1 }

-- First member of `tbl` that is unknown or of the wrong type. A leading underscore marks
-- a private member (the providers' test exports) and is left alone.
---@return string? problem
local function check_members(tbl, schema, where)
  for member, value in pairs(tbl) do
    if type(member) ~= "string" then
      return ("%s[%s]: unexpected list entry"):format(where, tostring(member))
    end
    if member:sub(1, 1) ~= "_" then
      local expected = schema[member]
      if not expected then
        return ("%s%s: unknown member"):format(where, member)
      end
      expected = type(expected) == "table" and expected or { expected }
      if not vim.tbl_contains(expected, type(value)) then
        return ("%s%s: expected %s, got %s"):format(where, member, table.concat(expected, " or "), type(value))
      end
    end
  end
end

---@return string? problem
local function check_step(step, where)
  if type(step) ~= "table" then
    return where .. ": expected a table, got " .. type(step)
  end
  local problem = check_members(step, STEP, where .. ".")
  if problem then
    return problem
  end

  if step.ask then
    for _, member in ipairs { "key", "prompt", "choices", "default", "validate" } do
      if step[member] ~= nil then
        return ("%s.%s: a custom `ask` step is a step on its own and takes only `when`"):format(where, member)
      end
    end
    return
  end

  if not (step.key and step.prompt) then
    return where .. ": needs `key` + `prompt` (+ `choices` for a select), or `ask`"
  end
  if RESERVED[step.key] then
    return ("%s.key: %q is reserved by the wizard"):format(where, step.key)
  end
  if not step.choices then
    return
  end

  if step.default ~= nil or step.validate then
    return where .. ": `default` and `validate` belong to an input step, and this one has `choices`"
  end
  if #step.choices == 0 then
    return where .. ".choices: empty"
  end
  for i, choice in ipairs(step.choices) do
    if type(choice) ~= "table" or type(choice.label) ~= "string" then
      return ("%s.choices[%d].label: expected string"):format(where, i)
    end
  end
end

-- nil when `provider` honours the contract, otherwise the first thing wrong with it.
---@param provider any
---@return string? problem
function M.validate(provider)
  if type(provider) ~= "table" then
    return "must return a table, got " .. type(provider)
  end
  for _, member in ipairs(REQUIRED) do
    if provider[member] == nil then
      return member .. ": missing"
    end
  end
  local problem = check_members(provider, PROVIDER, "")
  if problem then
    return problem
  end
  for i, step in ipairs(provider.steps or {}) do
    problem = check_step(step, ("steps[%d]"):format(i))
    if problem then
      return problem
    end
  end
end

----------------------------------------------------------------------------- registry

-- Every valid provider on the runtimepath, in menu order. Read fresh each time rather
-- than cached: it is a glob and a handful of small files, and it means a provider that
-- was just added or edited is picked up by the next `n` instead of the next restart.
---@return NewProject.Provider[]
function M.load()
  local list, seen, problems = {}, {}, {}

  for _, path in ipairs(vim.api.nvim_get_runtime_file(GLOB, true)) do
    local id = vim.fn.fnamemodify(path, ":t:r")
    if id ~= "init" and not seen[id] then
      seen[id] = true

      local provider, problem
      if not id:match "^[%w_-]+$" then
        -- `asp.net.lua` would be required as the module providers/asp/net
        problem = "file name may only hold letters, digits, _ and -"
      else
        package.loaded[MODULE .. id] = nil
        local ok, result = pcall(require, MODULE .. id)
        if ok then
          provider, problem = result, M.validate(result)
        else
          problem = result
        end
      end

      if problem then
        problems[#problems + 1] = ("providers/%s.lua: %s"):format(id, problem)
      else
        list[#list + 1] = vim.tbl_extend("keep", provider, DEFAULTS)
      end
    end
  end

  -- One notification for the lot, and not through ui.notify: that one replaces itself
  -- in place, so a second broken file would erase the report about the first.
  if #problems > 0 then
    vim.notify(table.concat(problems, "\n"), vim.log.levels.WARN, { title = "New Project" })
  end

  table.sort(list, function(a, b)
    if a.order ~= b.order then
      return a.order < b.order
    end
    return a.name < b.name
  end)
  return list
end

return M
