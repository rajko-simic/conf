-- Where the new project goes: in place when nvim's directory is empty, otherwise into a
-- subfolder named after the project. This is the wizard's built-in "name" step.

local ui = require "configs.newproject.ui"

local M = {}

-- A directory holding nothing but a fresh `git init` still counts as empty: that is the
-- `mkdir foo && cd foo && git init && nvim` flow, where scaffolding in place is exactly
-- what was meant. Anything else present means the directory is occupied.
local IGNORED = { [".git"] = true, [".gitignore"] = true }

---@param dir string
---@return boolean
function M.is_empty(dir)
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
function M.protected(dir)
  return dir == vim.env.HOME or dir == "/" or dir == vim.fn.stdpath "config"
end

-- Sets ctx.name and ctx.dir, prompting only when it has to. Re-prompts rather than
-- aborting on a bad answer: having to restart the whole wizard over a name collision
-- would be worse than the collision.
---@param ctx NewProject.Ctx
---@param done fun(ok: boolean)
function M.resolve(ctx, done)
  local normalize = ctx.provider.normalize

  if M.is_empty(ctx.cwd) and not M.protected(ctx.cwd) then
    ctx.dir, ctx.name = ctx.cwd, normalize(vim.fs.basename(ctx.cwd))
    return done(true)
  end

  local short = vim.fn.fnamemodify(ctx.cwd, ":~")
  ui.input(('Project name (under %s, "." for here)'):format(short), nil, function(raw)
    if not raw then
      return done(false)
    end

    if raw == "." then
      if M.protected(ctx.cwd) then
        ui.notify("Refusing to scaffold directly into " .. short, vim.log.levels.ERROR)
        return done(false)
      end
      ctx.dir, ctx.name = ctx.cwd, normalize(vim.fs.basename(ctx.cwd))
      return done(true)
    end

    if raw:match "^[/~]" or raw:find "%.%." then
      ui.notify("Give a name relative to " .. short .. ", without ..", vim.log.levels.WARN)
      return M.resolve(ctx, done)
    end

    local name = normalize(raw)
    local dir = ctx.cwd .. "/" .. name
    local stat = vim.uv.fs_stat(dir)
    if stat and (stat.type ~= "directory" or not M.is_empty(dir)) then
      ui.notify(vim.fn.fnamemodify(dir, ":~") .. " already exists", vim.log.levels.WARN)
      return M.resolve(ctx, done)
    end

    ctx.dir, ctx.name = dir, name
    done(true)
  end)
end

return M
