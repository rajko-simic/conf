-- snacks.dashboard, replacing NvChad's nvdash (disabled via nvdash.load_on_startup
-- in chadrc.lua; its own config is left untouched).
--
-- Left pane  : the nvdash buttons re-keyed to single letters, plus Quit.
-- Right pane : 10 most recent neovim-project projects (keys 1-9 then 0), the 3 most
--              recent files (keyless), and a git block at the bottom.
--
-- No `header` section: that is what draws the big NEOVIM banner, omitted on purpose.
--
-- Theming needs no work. snacks links SnacksDashboard{Header,Title,Icon,Key,Desc,File,
-- Dir,Footer} to Special / Title / Number / NonText / Normal with `default = true`, and
-- base46 themes all of those -- so the dashboard follows the active base46 theme.

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

--------------------------------------------------------------------------------- git

-- Icons are lifted verbatim from NvChad's statusline (nvchad/stl/utils.lua M.git) so the
-- two agree: branch U+EA68, added U+F055, changed U+F459, removed U+F146. The statusline
-- has no ahead/behind, so the arrow-circle pair is a choice, picked to sit with the
-- plus-circle it does use.
local ICON = {
  branch = "\u{ea68}",
  incoming = "\u{f0ab}",
  outgoing = "\u{f0aa}",
  added = "\u{f055}",
  changed = "\u{f459}",
  removed = "\u{f146}",
}

-- The statusline paints every git icon with St_gitIcons. The working-tree counts here use
-- base46's semantic Added/Changed/Removed instead, which reads better on a dashboard; set
-- them all to St_gitIcons to match the statusline exactly.
local HL = { head = "St_gitIcons", added = "Added", changed = "Changed", removed = "Removed" }

local SPINNER = { "/", "-", "\\", "|" }
local FETCH_EVERY = 5 * 60 -- seconds; throttled off .git/FETCH_HEAD mtime
local PANE_WIDTH = 60

local git_state = { root = nil, data = nil, fetching = false, frame = 1, timer = nil }

local function sh(root, args)
  local res = vim.system(args, { cwd = root, text = true }):wait(5000)
  if res.code ~= 0 or not res.stdout then
    return {}
  end
  return vim.split(res.stdout, "\n", { trimempty = true })
end

-- All local plumbing: no network, measured at ~15 ms for all three commands together,
-- which is why this stays synchronous. Only the `git fetch` below is async.
local function read_local(root)
  local d = { branch = "?", ahead = 0, behind = 0, added = 0, changed = 0, removed = 0, commits = {}, branches = {} }

  -- "## b...origin/b [ahead 1, behind 2]" | "## b...origin/b" | "## b" | "## No commits yet on b"
  local status = sh(root, { "git", "status", "--porcelain=v1", "--branch" })
  local head = status[1] or ""
  d.branch = head:match "^## No commits yet on (%S+)" or head:match "^## ([^%.%s]+)" or "?"
  d.behind = tonumber(head:match "behind (%d+)") or 0
  d.ahead = tonumber(head:match "ahead (%d+)") or 0
  for i = 2, #status do
    local xy = status[i]:sub(1, 2)
    if xy == "??" or xy:find "A" then -- untracked counts as added
      d.added = d.added + 1
    elseif xy:find "D" then
      d.removed = d.removed + 1
    else
      d.changed = d.changed + 1
    end
  end

  for _, line in ipairs(sh(root, { "git", "log", "--max-count=3", "--format=%h\t%s" })) do
    local hash, subject = line:match "^(%S+)\t(.*)$"
    if hash then
      d.commits[#d.commits + 1] = { hash = hash, subject = subject }
    end
  end

  -- %(upstream:track,nobracket) is local knowledge, i.e. as of the last fetch
  local fmt = "%(refname:short)\t%(upstream:short)\t%(upstream:track,nobracket)"
  for _, line in
    ipairs(sh(root, { "git", "for-each-ref", "--sort=-committerdate", "--count=3", "--format=" .. fmt, "refs/heads/" }))
  do
    local name, upstream, track = line:match "^([^\t]*)\t([^\t]*)\t(.*)$"
    if name and name ~= "" then
      d.branches[#d.branches + 1] = {
        name = name,
        tracked = upstream ~= "",
        ahead = tonumber((track or ""):match "ahead (%d+)") or 0,
        behind = tonumber((track or ""):match "behind (%d+)") or 0,
      }
    end
  end

  return d
end

local function stop_spinner()
  if git_state.timer then
    git_state.timer:stop()
    git_state.timer:close()
    git_state.timer = nil
  end
  git_state.fetching = false
end

local function redraw()
  pcall(function()
    require("snacks.dashboard").update()
  end)
end

-- A real `git fetch` costs ~1.1 s here, so it never blocks: the dashboard renders from
-- local data first and this refreshes the ahead/behind numbers when it lands.
-- Throttled off FETCH_HEAD so opening nvim repeatedly does not hammer the remote, and
-- run with prompts disabled so a credential request can never hang the editor.
local function maybe_fetch(root)
  if git_state.fetching then
    return
  end
  local head = vim.uv.fs_stat(root .. "/.git/FETCH_HEAD")
  if head and os.time() - head.mtime.sec < FETCH_EVERY then
    return
  end

  git_state.fetching = true
  git_state.frame = 1
  git_state.timer = vim.uv.new_timer()
  git_state.timer:start(
    150,
    150,
    vim.schedule_wrap(function()
      git_state.frame = git_state.frame % #SPINNER + 1
      redraw()
    end)
  )

  vim.system({ "git", "fetch", "--quiet", "--no-tags" }, {
    cwd = root,
    env = { GIT_TERMINAL_PROMPT = "0", GIT_SSH_COMMAND = "ssh -o BatchMode=yes -o ConnectTimeout=5" },
    timeout = 20000,
  }, function()
    vim.schedule(function()
      stop_spinner()
      -- offline or auth failure is fine: the local snapshot is simply not newer
      git_state.data = read_local(root)
      redraw()
    end)
  end)
end

local function truncate(s, n)
  return #s > n and (s:sub(1, n - 1) .. "\u{2026}") or s
end

local function render(d)
  local items = {}
  local function row(text)
    items[#items + 1] = { text = text }
  end

  -- 1. branch, with the fetch spinner while the remote is being checked
  local head = { { ICON.branch .. "  " .. d.branch, hl = HL.head } }
  if git_state.fetching then
    head[#head + 1] = { "  " .. SPINNER[git_state.frame], hl = "dir" }
  end
  row(head)

  -- 2. working tree; zeros omitted, the way the statusline suppresses them
  local counts = {}
  local function part(icon, n, hl)
    if n > 0 then
      counts[#counts + 1] = { ("%s %d   "):format(icon, n), hl = hl }
    end
  end
  part(ICON.incoming, d.behind, HL.head)
  part(ICON.outgoing, d.ahead, HL.head)
  part(ICON.added, d.added, HL.added)
  part(ICON.changed, d.changed, HL.changed)
  part(ICON.removed, d.removed, HL.removed)
  if #counts > 0 then
    row(counts)
  end

  -- 3. three most recent commits
  for _, c in ipairs(d.commits) do
    row {
      { c.hash .. "  ", hl = HL.head },
      { truncate(c.subject, PANE_WIDTH - #c.hash - 8), hl = "desc" },
    }
  end

  -- 4. three most recently committed branches, with their drift from origin
  for _, b in ipairs(d.branches) do
    local parts = { { truncate(b.name, 30), hl = "dir" } }
    if not b.tracked then
      parts[#parts + 1] = { "  (local)", hl = "desc" }
    else
      if b.behind > 0 then
        parts[#parts + 1] = { ("  %s %d"):format(ICON.incoming, b.behind), hl = HL.head }
      end
      if b.ahead > 0 then
        parts[#parts + 1] = { ("  %s %d"):format(ICON.outgoing, b.ahead), hl = HL.head }
      end
    end
    row(parts)
  end

  return items
end

local function git()
  local ok, snacks_git = pcall(require, "snacks.git")
  if not ok then
    return {}
  end
  local root = snacks_git.get_root()
  if not root then
    return {}
  end

  -- cached, so spinner frames and resizes re-render without re-running git
  if git_state.root ~= root or not git_state.data then
    git_state.root = root
    git_state.data = read_local(root)
    maybe_fetch(root)
  end

  return render(git_state.data)
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
      -- snacks binds q to `:bd` in D:init, but item keys are applied later in
      -- D:update -> D:keys, so this wins.
      { icon = " ", key = "q", desc = "Quit", action = ":qa" },
    },
  },

  sections = {
    { pane = 1, section = "keys", gap = 1, padding = 1 },
    { pane = 2, icon = " ", title = "Projects", indent = 2, padding = 1, projects },
    { pane = 2, icon = " ", title = "Recent Files", indent = 2, padding = 1, recent_files },
    { pane = 2, icon = " ", title = "Git", indent = 2, padding = 1, git },
    { pane = 1, section = "startup" },
  },
}

return M
