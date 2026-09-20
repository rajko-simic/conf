-- The dashboard's "New Project" button (key `n`), and :NewProject.
--
-- Pick a toolchain, answer whatever that toolchain needs, confirm, and the project is
-- scaffolded into nvim's current directory: in place when that directory is empty,
-- otherwise into a subfolder named after the project. On success neovim-project switches
-- to it, so it lands in the dashboard's Projects list straight away.
--
-- Nothing touches the filesystem before the confirmation step, so cancelling at any point
-- up to it is a guaranteed no-op -- which matters when the whole thing hangs off one
-- unmodified letter on the dashboard.
--
-- easy-dotnet's `:Dotnet new` is deliberately not reused. It is the other operation: it
-- adds a project to the *current solution*, defaults its output there and prefixes the
-- name with the solution's. This one starts a project in an empty directory. Both stay.

local providers = require "configs.newproject.providers"
local ui = require "configs.newproject.ui"

local M = {}

-- Stops a second wizard being started over the same directory while one is in flight.
M.busy = false

local SPINNER = { "/", "-", "\\", "|" }
local DEFAULT_TIMEOUT = 120000

--------------------------------------------------------------------------- target dir

-- A directory holding nothing but a fresh `git init` still counts as empty: that is the
-- `mkdir foo && cd foo && git init && nvim` flow, where scaffolding in place is exactly
-- what was meant. Anything else present means the directory is occupied.
local IGNORED = { [".git"] = true, [".gitignore"] = true }

---@param dir string
---@return boolean
local function is_empty(dir)
  local fd = vim.uv.fs_scandir(dir)
  if not fd then
    return false
  end
  while true do
    local name = vim.uv.fs_scandir_next(fd)
    if not name then
      return true
    end
    if not IGNORED[name] then
      return false
    end
  end
end

-- Never scaffold straight into one of these, however empty they happen to look.
---@param dir string
---@return boolean
local function protected(dir)
  return dir == vim.env.HOME or dir == "/" or dir == vim.fn.stdpath "config"
end

local function normalize(ctx, raw)
  return ctx.provider.normalize and ctx.provider.normalize(raw) or raw
end

-- Resolves ctx.name and ctx.dir, prompting only when it has to. Re-prompts rather than
-- aborting on a bad answer: having to restart the whole wizard over a name collision
-- would be worse than the collision.
---@param cb fun(ok: boolean)
local function resolve_target(ctx, cb)
  if is_empty(ctx.cwd) and not protected(ctx.cwd) then
    ctx.dir, ctx.name = ctx.cwd, normalize(ctx, vim.fs.basename(ctx.cwd))
    return cb(true)
  end

  local short = vim.fn.fnamemodify(ctx.cwd, ":~")
  ui.input(('Project name (under %s, "." for here)'):format(short), nil, function(raw)
    if not raw then
      return cb(false)
    end

    if raw == "." then
      if protected(ctx.cwd) then
        ui.notify("Refusing to scaffold directly into " .. short, vim.log.levels.ERROR)
        return cb(false)
      end
      ctx.dir, ctx.name = ctx.cwd, normalize(ctx, vim.fs.basename(ctx.cwd))
      return cb(true)
    end

    if raw:match "^[/~]" or raw:find "%.%." then
      ui.notify("Give a name relative to " .. short .. ", without ..", vim.log.levels.WARN)
      return resolve_target(ctx, cb)
    end

    local name = normalize(ctx, raw)
    local dir = ctx.cwd .. "/" .. name
    local stat = vim.uv.fs_stat(dir)
    if stat and (stat.type ~= "directory" or not is_empty(dir)) then
      ui.notify(vim.fn.fnamemodify(dir, ":~") .. " already exists", vim.log.levels.WARN)
      return resolve_target(ctx, cb)
    end

    ctx.dir, ctx.name = dir, name
    cb(true)
  end)
end

-------------------------------------------------------------------------------- steps

---@class NewProject.Step
---@field when? fun(ctx: table): boolean
---@field ask fun(ctx: table, cb: fun(ok: boolean))

-- Steps write into ctx and answer with a boolean rather than handing a value back,
-- because "carry on with nothing set" is a real answer here -- Flutter's "All platforms"
-- leaves the flag off entirely -- and must not read as a cancel.
local function run(steps, i, ctx, done)
  local step = steps[i]
  if not step then
    return done(true)
  end
  if step.when and not step.when(ctx) then
    return run(steps, i + 1, ctx, done)
  end
  step.ask(ctx, function(ok)
    if not ok then
      return done(false)
    end
    run(steps, i + 1, ctx, done)
  end)
end

-- The last step, and the only thing standing between a mistyped `n` and a scaffold. The
-- command is the choice itself, so what is about to run is on screen before it runs.
---@param cb fun(ok: boolean)
local function confirm(ctx, cb)
  ctx.argv = ctx.provider.build(ctx)
  ui.select("New project in " .. vim.fn.fnamemodify(ctx.dir, ":~"), {
    { label = table.concat(ctx.argv, " "), go = true },
    { label = "Cancel" },
  }, function(choice)
    cb(choice ~= nil and choice.go == true)
  end)
end

------------------------------------------------------------------------------ scaffold

local function post_create(ctx)
  -- switch_project does the chdir itself. Doing it here first would trip
  -- neovim-project's own DirChangedPre handler, which tears down the very session it is
  -- about to load. It also records the project in the history the dashboard reads, so
  -- there is no add_session_project call to make either.
  require("neovim-project.project").switch_project(ctx.dir)

  -- After the switch: creating a session runs `silent! %bd`, and the cwd has to have
  -- moved before the tree picks up its root (sync_root_with_cwd). `tree.open` is
  -- idempotent, unlike NvimTreeToggle, which would close a tree that survived the %bd.
  vim.schedule(function()
    pcall(function()
      require("nvim-tree.api").tree.open()
    end)
  end)
end

local function finish(ctx, res)
  if res.code ~= 0 then
    local cmd = table.concat(ctx.argv, " ")
    ui.notify(("%s failed (%d)\n%s"):format(cmd, res.code, ui.output(res)), vim.log.levels.ERROR)
    -- fs_rmdir only ever removes an *empty* directory, so this cannot eat a partial
    -- scaffold; and it is skipped for a directory that was already there.
    if ctx.created then
      pcall(vim.uv.fs_rmdir, ctx.dir)
    end
    return
  end

  if ctx.provider.after then
    local ok, err = pcall(ctx.provider.after, ctx)
    if not ok then
      ui.notify("Scaffolded, but the post-create step failed: " .. tostring(err), vim.log.levels.WARN)
    end
  end

  -- Said before switching: switch_project can block for up to two seconds saving the
  -- outgoing session, and a spinner frozen over that looks like a hang.
  ui.notify(("Created %s (%s)"):format(ctx.name, ctx.label or ctx.provider.name))
  post_create(ctx)
end

local function execute(ctx)
  ctx.created = vim.uv.fs_stat(ctx.dir) == nil
  if vim.fn.mkdir(ctx.dir, "p") ~= 1 then
    ui.notify("Could not create " .. ctx.dir, vim.log.levels.ERROR)
    M.busy = false
    return
  end

  local frame = 1
  local timer = assert(vim.uv.new_timer())
  timer:start(
    0,
    150,
    vim.schedule_wrap(function()
      ui.notify(("%s Creating %s…"):format(SPINNER[frame], ctx.name))
      frame = frame % #SPINNER + 1
    end)
  )

  vim.system(ctx.argv, {
    cwd = ctx.dir,
    text = true,
    timeout = ctx.provider.timeout or DEFAULT_TIMEOUT,
  }, function(res)
    -- vim.system answers on the libuv thread, where touching the editor is illegal
    vim.schedule(function()
      timer:stop()
      timer:close()
      M.busy = false
      finish(ctx, res)
    end)
  end)
end

--------------------------------------------------------------------------------- entry

function M.open()
  if M.busy then
    return ui.notify("A project is already being created", vim.log.levels.WARN)
  end

  local cwd = vim.uv.cwd()
  if not cwd then
    return ui.notify("Cannot determine the current directory", vim.log.levels.ERROR)
  end

  local items = {}
  for _, provider in ipairs(providers.list) do
    -- Unavailable toolchains are shown disabled rather than hidden: a menu that changes
    -- shape between machines hides the reason something is missing.
    local available = vim.fn.executable(provider.bin) == 1
    items[#items + 1] = {
      label = provider.icon .. provider.name .. (available and "" or ("  (" .. provider.bin .. " not found)")),
      provider = provider,
      available = available,
    }
  end

  M.busy = true
  ui.select("New project in " .. vim.fn.fnamemodify(cwd, ":~"), items, function(choice)
    if not choice then
      M.busy = false
      return
    end
    if not choice.available then
      M.busy = false
      return ui.notify(choice.provider.bin .. " is not on PATH", vim.log.levels.ERROR)
    end

    local provider = choice.provider
    local ctx = { cwd = cwd, provider = provider }

    -- The name is asked last, after the "what am I making" questions -- except where a
    -- later step needs it, as Go's module path does.
    local steps = {}
    if provider.name_first then
      steps[#steps + 1] = { ask = resolve_target }
    end
    vim.list_extend(steps, provider.steps)
    if not provider.name_first then
      steps[#steps + 1] = { ask = resolve_target }
    end
    steps[#steps + 1] = { ask = confirm }

    run(steps, 1, ctx, function(ok)
      if not ok then
        M.busy = false
        return
      end
      execute(ctx)
    end)
  end)
end

-- exported for the headless tests
M._is_empty = is_empty
M._protected = protected
M._parse_templates = providers._parse_templates
M._dart_name = providers._dart_name

return M
