-- Runs the confirmed command and lands in the result. Everything here happens after the
-- confirmation step: it is the only part of the wizard that touches the filesystem.
--
-- The target directory is created first and the command always runs inside it, which
-- collapses "scaffold in place" and "scaffold into a subfolder" into one case -- and
-- covers toolchains like `go mod init` that cannot create a directory of their own.

local ui = require "configs.newproject.ui"

local M = {}

local SPINNER = { "/", "-", "\\", "|" }

-- True while a command is running. The one hard lock in the wizard: two scaffolders
-- writing into the same directory is the case that actually does damage.
local running = false

---@return boolean
function M.busy()
  return running
end

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

  local ok, err = pcall(ctx.provider.after, ctx)
  if not ok then
    ui.notify("Scaffolded, but the post-create step failed: " .. tostring(err), vim.log.levels.WARN)
  end

  -- Said before switching: switch_project can block for up to two seconds saving the
  -- outgoing session, and a spinner frozen over that looks like a hang.
  ui.notify(("Created %s (%s)"):format(ctx.name, ctx.provider.name))
  post_create(ctx)
end

---@param ctx NewProject.Ctx
function M.run(ctx)
  if running then
    return ui.notify("A project is already being created", vim.log.levels.WARN)
  end

  ctx.created = vim.uv.fs_stat(ctx.dir) == nil
  if vim.fn.mkdir(ctx.dir, "p") ~= 1 then
    return ui.notify("Could not create " .. ctx.dir, vim.log.levels.ERROR)
  end
  running = true

  local frame = 1
  local timer = assert(vim.uv.new_timer())
  timer:start(
    0,
    150,
    vim.schedule_wrap(function()
      -- a tick already queued when the command exits must not paint over its outcome
      if not running then
        return
      end
      ui.notify(("%s Creating %s…"):format(SPINNER[frame], ctx.name))
      frame = frame % #SPINNER + 1
    end)
  )

  ui.system(ctx.argv, { cwd = ctx.dir, timeout = ctx.provider.timeout }, function(res)
    timer:stop()
    timer:close()
    running = false
    finish(ctx, res)
  end)
end

return M
