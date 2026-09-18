-- :checkhealth lsp_overrides
--
-- Every server customization lives in after/lsp/<name>.lua. `after/` is last on the
-- runtimepath, so those files always beat nvim-lspconfig -- the shadowing direction that
-- silently broke lemminx for months is structurally impossible there.
--
-- The failure mode that remains is the opposite one: a key drifting into agreement with
-- upstream. That is dead weight, and worse, a frozen copy that blocks future upstream
-- fixes. This check finds those.

local M = {}

local config_dir = vim.fn.stdpath "config"

-- What nvim would resolve for `name` from the runtimepath if our after/lsp file did not
-- exist -- in practice, nvim-lspconfig's bundled definition.
local function upstream(name)
  local merged
  for _, file in ipairs(vim.api.nvim_get_runtime_file("lsp/" .. name .. ".lua", true)) do
    if not vim.startswith(file, config_dir) then
      local ok, cfg = pcall(dofile, file)
      if ok and type(cfg) == "table" then
        merged = vim.tbl_deep_extend("force", merged or {}, cfg)
      end
    end
  end
  return merged
end

function M.check()
  vim.health.start "LSP overrides (after/lsp)"

  local dir = config_dir .. "/after/lsp"
  if vim.fn.isdirectory(dir) == 0 then
    vim.health.info "no after/lsp directory"
    return
  end

  local names = {}
  for entry in vim.fs.dir(dir) do
    local name = entry:match "^(.*)%.lua$"
    if name then
      names[#names + 1] = name
    end
  end
  table.sort(names)

  if #names == 0 then
    vim.health.info "no overrides"
    return
  end

  local redundant = 0

  for _, name in ipairs(names) do
    local ok, ours = pcall(dofile, dir .. "/" .. name .. ".lua")
    if not ok or type(ours) ~= "table" then
      vim.health.error(("%s: does not return a table (%s)"):format(name, ours))
      goto continue
    end

    local up = upstream(name)
    if not up then
      vim.health.ok(("%s: defines the server outright (no upstream definition)"):format(name))
      goto continue
    end

    local adds, overrides, dead = {}, {}, {}
    for key, value in pairs(ours) do
      if up[key] == nil then
        adds[#adds + 1] = key
      elseif type(value) == "function" or type(up[key]) == "function" then
        overrides[#overrides + 1] = key .. " (function)"
      elseif vim.deep_equal(value, up[key]) then
        dead[#dead + 1] = key
      else
        overrides[#overrides + 1] = key
      end
    end
    table.sort(adds)
    table.sort(overrides)
    table.sort(dead)

    local parts = {}
    if #overrides > 0 then
      parts[#parts + 1] = "overrides " .. table.concat(overrides, ", ")
    end
    if #adds > 0 then
      parts[#parts + 1] = "adds " .. table.concat(adds, ", ")
    end

    if #dead > 0 then
      redundant = redundant + 1
      vim.health.warn(
        ("%s: %s now equals upstream -- delete %s"):format(
          name,
          table.concat(dead, ", "),
          #dead == 1 and "that key" or "those keys"
        ),
        #parts > 0 and { "still useful: " .. table.concat(parts, "; ") } or { "the whole file is redundant; delete it" }
      )
    else
      vim.health.ok(("%s: %s"):format(name, #parts > 0 and table.concat(parts, "; ") or "no keys?"))
    end

    ::continue::
  end

  if redundant == 0 then
    vim.health.ok(("all %d overrides still differ from upstream"):format(#names))
  end
end

return M
