-- Follow the desktop light/dark preference.
--
-- Source of truth is the XDG portal setting `org.freedesktop.appearance` / `color-scheme`
-- (0 = no preference, 1 = prefer dark, 2 = prefer light). `chadrc.lua` calls `query()` so the
-- theme it hands to nvconfig is already the right half of `theme_toggle` = { dark, light };
-- `setup()` recompiles the base46 cache when the one on disk was built for the other half,
-- and `watch()` keeps a `dbus-monitor` job per nvim instance that re-applies the theme live
-- on the portal's `SettingChanged` signal.
--
-- Why the portal and not the terminal: nvim >= 0.11 re-detects 'background' on DEC mode 2031
-- theme notifications, but Konsole implements neither 2031 nor DECRQM, so that never fires.
-- Konsole swaps its own profile on the same desktop signal (SyncProfileWithSystemTheme), so
-- terminal and editor stay in step. Without a session bus (ssh, tty) `query()` is nil and the
-- dark half is used, i.e. the old static behaviour.

local M = {}

local NAMESPACE, KEY = "org.freedesktop.appearance", "color-scheme"

local function mode_of(value)
  return value == "1" and "dark" or "light"
end

--- Synchronous one-shot read of the portal setting (about 1 ms).
---@return "dark"|"light"|nil mode nil when there is no session bus or no portal
M.query = function()
  if vim.fn.executable "busctl" ~= 1 then
    return nil
  end
  local out = vim.fn.system {
    "busctl",
    "--user",
    "call",
    "org.freedesktop.portal.Desktop",
    "/org/freedesktop/portal/desktop",
    "org.freedesktop.portal.Settings",
    "ReadOne",
    "ss",
    NAMESPACE,
    KEY,
  }
  if vim.v.shell_error ~= 0 then
    return nil
  end
  local value = out:match "^v u (%d)"
  return value and mode_of(value) or nil
end

---@param mode "dark"|"light"
---@return string theme the matching half of chadrc's theme_toggle = { dark, light }
M.theme_for = function(mode)
  local pair = require("nvconfig").base46.theme_toggle
  return mode == "light" and pair[2] or pair[1]
end

--- Apply the theme for `mode` the way the `<leader>st` picker does. No-op when the live
--- theme and the compiled cache (visible through 'background') already match.
---@param mode "dark"|"light"
M.apply = function(mode)
  local cfg = require("nvconfig").base46
  local want = M.theme_for(mode)
  if cfg.theme == want and vim.o.background == mode then
    return
  end
  cfg.theme = want
  require("base46").load_all_highlights()
  pcall(function()
    require("plenary.reload").reload_module "volt.highlights"
    require "volt.highlights"
  end)
end

local proc ---@type vim.SystemObj? the dbus-monitor listener of this nvim instance

--- Start the portal signal listener. Idempotent; needs `dbus-monitor` and a session bus.
M.watch = function()
  if proc or vim.fn.executable "dbus-monitor" ~= 1 then
    return
  end
  local rule = table.concat({
    "type='signal'",
    "interface='org.freedesktop.portal.Settings'",
    "member='SettingChanged'",
    "path='/org/freedesktop/portal/desktop'",
    "arg0='" .. NAMESPACE .. "'",
    "arg1='" .. KEY .. "'",
  }, ",")
  local pending = ""
  proc = vim.system({ "dbus-monitor", "--session", rule }, {
    text = true,
    stdout = function(_, data)
      if not data then
        return
      end
      pending = pending .. data
      while true do
        local nl = pending:find("\n", 1, true)
        if not nl then
          break
        end
        local value = pending:sub(1, nl - 1):match "uint32 (%d)"
        pending = pending:sub(nl + 1)
        if value then
          vim.schedule(function()
            M.apply(mode_of(value))
          end)
        end
      end
    end,
  })
  -- vim.system children are not reaped on exit (neovim#29475)
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      proc:kill "sigterm"
    end,
  })
end

--- Called from init.lua right after the base46 cache is loaded, before the first draw.
M.setup = function()
  local mode = M.query()
  if mode then
    M.apply(mode)
  end
  -- UIEnter never fires under --headless, which keeps checkhealth and scripts listener-free
  vim.api.nvim_create_autocmd("UIEnter", { once = true, callback = M.watch })
end

return M
