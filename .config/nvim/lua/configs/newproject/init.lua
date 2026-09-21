-- The dashboard's "New Project" button (key `n`), and :NewProject.
--
-- Pick a toolchain, answer whatever that toolchain needs, confirm, and the project is
-- scaffolded into nvim's current directory: in place when that directory is empty,
-- otherwise into a subfolder named after the project. On success neovim-project switches
-- to it, so it lands in the dashboard's Projects list straight away.
--
--   providers.lua   the contract a toolchain implements, and the registry
--   providers/      one file per toolchain -- adding a file here is all it takes
--   target.lua      where the project goes (the name step)
--   scaffold.lua    running the command, and landing in the result
--   ui.lua          prompts, notifications, processes
--
-- This file is the wizard itself: it asks the steps a provider declares and knows
-- nothing about any particular one. No step touches the project directory; that starts
-- in scaffold.lua, after the confirmation.
--
-- easy-dotnet's `:Dotnet new` is deliberately not reused. It is the other operation: it
-- adds a project to the *current solution*, defaults its output there and prefixes the
-- name with the solution's. This one starts a project in an empty directory. Both stay.

local providers = require "configs.newproject.providers"
local scaffold = require "configs.newproject.scaffold"
local target = require "configs.newproject.target"
local ui = require "configs.newproject.ui"

local M = {}

-- The wizard in flight. Opening another one supersedes it instead of being refused: a
-- lock held across the prompts would stay held forever if a provider's step threw, and
-- a lock around the scaffold alone is not enough, because a custom step can sit waiting
-- on a process with no window open and the dashboard's `n` live again.
---@type NewProject.Ctx?
local current

-------------------------------------------------------------------------------- steps

---@param step NewProject.Step
---@param ctx NewProject.Ctx
---@param done fun(ok: boolean)
local function choose(step, ctx, done)
  ui.select(step.prompt, step.choices, function(choice)
    if not choice then
      return done(false)
    end
    ctx[step.key] = choice.value
    done(true)
  end)
end

---@param step NewProject.Step
---@param ctx NewProject.Ctx
---@param done fun(ok: boolean)
local function input(step, ctx, done)
  local default = step.default
  if type(default) == "function" then
    default = default(ctx)
  end
  ui.input(step.prompt, default, function(value)
    if not value then
      return done(false)
    end
    local problem = step.validate and step.validate(value, ctx)
    if problem then
      ui.notify(problem, vim.log.levels.WARN)
      return input(step, ctx, done)
    end
    ctx[step.key] = value
    done(true)
  end)
end

-- vim.system walks argv by length, so a nil spliced into the middle of it -- an answer
-- that was legitimately left empty -- would cut the command short without a word.
local function is_argv(argv)
  if type(argv) ~= "table" or #argv == 0 or not vim.islist(argv) then
    return false
  end
  for _, arg in ipairs(argv) do
    if type(arg) ~= "string" then
      return false
    end
  end
  return true
end

-- The last step, and the only thing standing between a mistyped `n` and a scaffold. The
-- command is the choice itself, so what is about to run is on screen before it runs.
---@param ctx NewProject.Ctx
---@param done fun(ok: boolean)
local function confirm(ctx, done)
  local argv = ctx.provider.command(ctx)
  if not is_argv(argv) then
    ui.notify(
      ctx.provider.name .. ": command() must return a list of strings with no gaps -- got " .. vim.inspect(argv),
      vim.log.levels.ERROR
    )
    return done(false)
  end
  ctx.argv = argv

  ui.select("New project in " .. vim.fn.fnamemodify(ctx.dir, ":~"), {
    { label = table.concat(argv, " "), go = true },
    { label = "Cancel" },
  }, function(choice)
    done(choice ~= nil and choice.go == true)
  end)
end

-- Steps write into ctx and answer with a boolean rather than handing a value back,
-- because "carry on with nothing set" is a real answer here -- Flutter's "All platforms"
-- leaves the flag off entirely -- and must not read as a cancel.
---@param ctx NewProject.Ctx
---@param steps NewProject.Step[]
---@param i integer
---@param done fun()
local function run(ctx, steps, i, done)
  if ctx.cancelled then
    return
  end
  local step = steps[i]
  if not step then
    return done()
  end
  if step.when and not step.when(ctx) then
    return run(ctx, steps, i + 1, done)
  end

  local function answered(ok)
    if ok then
      run(ctx, steps, i + 1, done)
    end
  end
  if step.ask then
    step.ask(ctx, answered)
  elseif step.choices then
    choose(step, ctx, answered)
  else
    input(step, ctx, answered)
  end
end

--------------------------------------------------------------------------------- entry

function M.open()
  if scaffold.busy() then
    return ui.notify("A project is already being created", vim.log.levels.WARN)
  end

  local cwd = vim.uv.cwd()
  if not cwd then
    return ui.notify("Cannot determine the current directory", vim.log.levels.ERROR)
  end

  local items = {}
  for _, provider in ipairs(providers.load()) do
    -- Unavailable toolchains are shown disabled rather than hidden: a menu that changes
    -- shape between machines hides the reason something is missing.
    local available = vim.fn.executable(provider.bin) == 1
    items[#items + 1] = {
      label = provider.icon .. provider.name .. (available and "" or ("  (" .. provider.bin .. " not found)")),
      provider = provider,
      available = available,
    }
  end
  if #items == 0 then
    return ui.notify("No providers found in newproject/providers/", vim.log.levels.ERROR)
  end

  if current then
    current.cancelled = true
  end
  local ctx = { cwd = cwd }
  current = ctx

  ui.select("New project in " .. vim.fn.fnamemodify(cwd, ":~"), items, function(choice)
    if not choice or ctx.cancelled then
      return
    end
    if not choice.available then
      return ui.notify(choice.provider.bin .. " is not on PATH", vim.log.levels.ERROR)
    end

    local provider = choice.provider
    ctx.provider = provider

    -- The name is asked last, after the "what am I making" questions, unless a step
    -- needs it. Name and confirmation are ordinary custom steps, so one loop runs it all.
    local name = { ask = target.resolve }
    local steps = provider.name_first and { name } or {}
    vim.list_extend(steps, provider.steps)
    if not provider.name_first then
      steps[#steps + 1] = name
    end
    steps[#steps + 1] = { ask = confirm }

    run(ctx, steps, 1, function()
      scaffold.run(ctx)
    end)
  end)
end

return M
