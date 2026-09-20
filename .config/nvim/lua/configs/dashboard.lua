-- snacks.dashboard, replacing NvChad's nvdash (disabled via nvdash.load_on_startup
-- in chadrc.lua; its own config is left untouched).
--
-- Left pane  : the nvdash buttons, re-keyed to single letters.
-- Right pane : the 10 most recent neovim-project projects (keys 1-9 then 0) and the
--              3 most recent files (deliberately keyless -- informational only).
--
-- No `header` section: that is what draws the big NEOVIM banner, and it is omitted on
-- purpose.
--
-- Theming needs no work. snacks links SnacksDashboard{Header,Title,Icon,Key,Desc,File,
-- Dir,Footer} to Special / Title / Number / NonText / Normal with `default = true`, and
-- base46 themes all of those -- so the dashboard picks up the active base46 theme and
-- follows a theme switch with it.

local M = {}

-- neovim-project owns the project list, so go through it rather than snacks' own
-- `projects` section: that one derives directories from oldfiles + git roots and would
-- `chdir` instead of restoring the session.
local function projects()
  local ok, history = pcall(require, "neovim-project.utils.history")
  if not ok then
    return {}
  end

  local dirs = history.get_recent_projects() or {}
  local items = {}

  -- history is oldest-first; show most recent first
  for i = #dirs, 1, -1 do
    if #items >= 10 then
      break
    end
    local dir = dirs[i]
    local n = #items + 1
    items[#items + 1] = {
      file = dir,
      icon = "directory",
      key = n == 10 and "0" or tostring(n),
      action = function()
        require("neovim-project.project").switch_project(dir)
      end,
    }
  end

  return items
end

-- snacks' recent_files items carry `autokey = true`; strip it so these stay keyless and
-- do not eat keys from the autokey pool.
local function recent_files()
  local items = require("snacks.dashboard").sections.recent_files { limit = 3 }()
  for _, item in ipairs(items) do
    item.autokey, item.key = nil, nil
  end
  return items
end

-- Git block. Icons are lifted verbatim from NvChad's statusline
-- (nvchad/stl/utils.lua M.git) so the two agree: branch U+EA68, added U+F055,
-- changed U+F459, removed U+F146. The statusline has no ahead/behind, so the
-- arrow-circle pair below is a choice, picked to sit with the plus-circle it does use.
local GIT_ICONS = {
  branch = "\u{ea68}",
  incoming = "\u{f0ab}",
  outgoing = "\u{f0aa}",
  added = "\u{f055}",
  changed = "\u{f459}",
  removed = "\u{f146}",
}

-- The statusline paints every git icon with St_gitIcons. Here the working-tree counts
-- use base46's semantic Added/Changed/Removed instead, which reads better on a
-- dashboard; set them all to St_gitIcons to match the statusline exactly.
local GIT_HL = { head = "St_gitIcons", added = "Added", changed = "Changed", removed = "Removed" }

-- One `git status --porcelain=v1 --branch` yields branch, ahead, behind and the
-- working-tree counts (~10ms). Resolved synchronously, which is why it is guarded: with
-- no repo the git process is never spawned.
--
-- Counts are per FILE. The statusline's come from gitsigns and are per hunk, so the two
-- will not always agree -- matching would mean loading gitsigns for unopened buffers.
local function git()
  local ok, snacks_git = pcall(require, "snacks.git")
  if not ok then
    return {}
  end
  local root = snacks_git.get_root()
  if not root then
    return {}
  end

  local res = vim.system({ "git", "status", "--porcelain=v1", "--branch" }, { cwd = root, text = true }):wait(2000)
  if res.code ~= 0 or not res.stdout then
    return {}
  end

  local lines = vim.split(res.stdout, "\n", { trimempty = true })
  local head = lines[1] or ""
  -- "## b...origin/b [ahead 1, behind 2]" | "## b...origin/b" | "## b" | "## No commits yet on b"
  local branch = head:match "^## No commits yet on (%S+)" or head:match "^## ([^%.%s]+)" or "?"
  local behind = tonumber(head:match "behind (%d+)") or 0
  local ahead = tonumber(head:match "ahead (%d+)") or 0

  local added, changed, removed = 0, 0, 0
  for i = 2, #lines do
    local xy = lines[i]:sub(1, 2)
    if xy == "??" or xy:find "A" then -- untracked counts as added
      added = added + 1
    elseif xy:find "D" then
      removed = removed + 1
    else
      changed = changed + 1
    end
  end

  local items = { { text = { { GIT_ICONS.branch .. "  " .. branch, hl = GIT_HL.head } } } }

  -- zero counts are omitted, the same way the statusline suppresses them
  local parts = {}
  local function part(icon, n, hl)
    if n > 0 then
      parts[#parts + 1] = { ("%s %d   "):format(icon, n), hl = hl }
    end
  end
  part(GIT_ICONS.incoming, behind, GIT_HL.head)
  part(GIT_ICONS.outgoing, ahead, GIT_HL.head)
  part(GIT_ICONS.added, added, GIT_HL.added)
  part(GIT_ICONS.changed, changed, GIT_HL.changed)
  part(GIT_ICONS.removed, removed, GIT_HL.removed)

  if #parts > 0 then
    items[#items + 1] = { text = parts }
  end

  return items
end

M.opts = {
  preset = {
    keys = {
      { icon = " ", key = "l", desc = "Last Project", action = ":NeovimProjectLoadRecent" },
      { icon = " ", key = "p", desc = "Recent Projects", action = ":NeovimProjectHistory" },
      { icon = " ", key = "a", desc = "Projects (Alphabet)", action = ":NeovimProjectDiscover alphabetical_name" },
      { icon = " ", key = "h", desc = "Projects (History)", action = ":NeovimProjectDiscover history" },
      { icon = " ", key = "d", desc = "Projects (Path)", action = ":NeovimProjectDiscover alphabetical_path" },
      { icon = " ", key = "f", desc = "Find File", action = ":Telescope find_files" },
      { icon = " ", key = "o", desc = "Recent Files", action = ":Telescope oldfiles" },
      { icon = "󰈭 ", key = "w", desc = "Find Word", action = ":Telescope live_grep" },
      { icon = " ", key = "c", desc = "Mappings", action = ":NvCheatsheet" },
    },
  },

  sections = {
    { pane = 1, indent = 2, padding = 1, git },
    { pane = 1, section = "keys", gap = 1, padding = 1 },
    { pane = 2, icon = " ", title = "Projects", indent = 2, padding = 1, projects },
    { pane = 2, icon = " ", title = "Recent Files", indent = 2, padding = 1, recent_files },
    { pane = 1, section = "startup" },
  },
}

return M
