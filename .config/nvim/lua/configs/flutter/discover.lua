-- Pure flavor/project discovery for flutter. No flutter-tools require, so the
-- cmdpicker can call this while deciding whether to offer flutter at all,
-- without lazy.nvim pulling the plugin in.
--
-- The gradle parser is lua-pattern/brace-count based: it handles the common
-- Groovy (`dev { ... }`) and Kotlin DSL (`create("dev") { ... }`,
-- `register("dev")`) forms, but not exotic constructs (flavors created in
-- loops, braces inside comments or strings).

local M = {}

local uv = vim.uv
local cache = {} -- root -> { mtimes = { [path] = sec }, flavors = string[] }

-- Directories never descended into by the downward project scan: VCS/tooling
-- junk plus flutter platform dirs. A repo-level folder that happens to share a
-- platform dir name ("android", "web", ...) is the known blind spot.
local skip_dirs = {
  [".git"] = true,
  [".dart_tool"] = true,
  [".gradle"] = true,
  [".idea"] = true,
  [".fvm"] = true,
  ["node_modules"] = true,
  ["build"] = true,
  ["android"] = true,
  ["ios"] = true,
  ["macos"] = true,
  ["linux"] = true,
  ["windows"] = true,
  ["web"] = true,
}

local function gradle_files(root)
  local files = {}
  for _, name in ipairs { "build.gradle", "build.gradle.kts" } do
    local path = root .. "/android/app/" .. name
    if uv.fs_stat(path) then
      files[#files + 1] = path
    end
  end
  return files
end

-- Body of the first `productFlavors { ... }` block, via brace counting.
local function product_flavors_block(src)
  local start = src:find "productFlavors%s*{"
  if not start then
    return nil
  end
  local open = src:find("{", start, true)
  local depth = 0
  for i = open, #src do
    local c = src:sub(i, i)
    if c == "{" then
      depth = depth + 1
    elseif c == "}" then
      depth = depth - 1
      if depth == 0 then
        return src:sub(open + 1, i - 1)
      end
    end
  end
  return nil
end

local creators = { create = true, register = true, getByName = true, maybeCreate = true }
local not_flavors = { all = true, each = true, configureEach = true }

local function parse_flavors(src)
  local block = product_flavors_block(src)
  if not block then
    return {}
  end
  local names, seen, depth = {}, {}, 0
  for line in block:gmatch "[^\r\n]+" do
    if depth == 0 then
      -- method form: create("dev") { ... }, register("dev"), ...
      local fn, name = line:match "([%w_]+)%s*%(%s*['\"]([%w_%-%.]+)['\"]"
      if not (fn and creators[fn]) then
        -- Groovy block form: dev { ... }
        name = line:match "^%s*([%w_]+)%s*{"
      end
      if name and not seen[name] and not not_flavors[name] then
        seen[name], names[#names + 1] = true, name
      end
    end
    local _, opens = line:gsub("{", "")
    local _, closes = line:gsub("}", "")
    depth = depth + opens - closes
  end
  return names
end

local function mtimes_of(files)
  local mtimes = {}
  for _, path in ipairs(files) do
    local stat = uv.fs_stat(path)
    mtimes[path] = stat and stat.mtime.sec or 0
  end
  return mtimes
end

--- Bounded downward scan for flutter projects (dirs holding a pubspec.yaml)
--- under base. Depth-capped and pruned via skip_dirs, so it stays cheap even
--- in large repos.
---@return string[] roots absolute paths, sorted
function M.projects(base)
  local roots = {}
  for name, kind in
    vim.fs.dir(base, {
      depth = 4,
      skip = function(dir)
        return not skip_dirs[vim.fs.basename(dir)]
      end,
    })
  do
    if kind == "file" and vim.fs.basename(name) == "pubspec.yaml" then
      local dir = vim.fs.dirname(name)
      roots[#roots + 1] = dir == "." and base or vim.fs.joinpath(base, dir)
    end
  end
  table.sort(roots)
  return roots
end

--- Heuristic for "runnable app" (vs a pure dart package) when listing several
--- projects found by the downward scan.
function M.is_app(root)
  return uv.fs_stat(root .. "/lib/main.dart") ~= nil
end

--- Flavors declared in root's android gradle file(s). Cached per root, keyed
--- on gradle mtimes; force bypasses the cache.
---@return string[] flavors, boolean changed true when the cached value was stale
function M.flavors(root, force)
  local files = gradle_files(root)
  local mtimes = mtimes_of(files)
  local cached = cache[root]
  if cached and not force and vim.deep_equal(cached.mtimes, mtimes) then
    return cached.flavors, false
  end

  local flavors, seen = {}, {}
  for _, path in ipairs(files) do
    local fd = io.open(path, "r")
    if fd then
      local src = fd:read "*a"
      fd:close()
      for _, name in ipairs(parse_flavors(src)) do
        if not seen[name] then
          seen[name], flavors[#flavors + 1] = true, name
        end
      end
    end
  end
  cache[root] = { mtimes = mtimes, flavors = flavors }
  return flavors, true
end

return M
