-- Prefix offered in the module-path prompt. Set it once to your own host and user and
-- every new Go project gets a usable default; empty just offers the project name, which
-- is a valid module path for something that is never published.
local MODULE_PREFIX = ""

-- `go mod init` leaves nothing but a go.mod, and Go has no scaffolder of its own, so the
-- entry point is written here. Never overwrites: the in-place path can land in a
-- directory that already has one.
local function write_main(ctx)
  local main = ctx.dir .. "/main.go"
  if vim.uv.fs_stat(main) then
    return
  end
  local src = table.concat({
    "package main",
    "",
    'import "fmt"',
    "",
    "func main() {",
    ('\tfmt.Println("hello, %s")'):format(ctx.name),
    "}",
    "",
  }, "\n")
  local fd = assert(vim.uv.fs_open(main, "w", 420)) -- 0644
  vim.uv.fs_write(fd, src)
  vim.uv.fs_close(fd)
end

---@type NewProject.Provider
local M = {
  name = "Go",
  icon = "\u{e627} ", -- nf-seti-go, the file tree's glyph for .go
  bin = "go",
  order = 40,
  -- the module path defaults off the name, so the name has to be known first
  name_first = true,

  steps = {
    {
      key = "module",
      prompt = "Module path",
      default = function(ctx)
        return MODULE_PREFIX ~= "" and (MODULE_PREFIX .. "/" .. ctx.name) or ctx.name
      end,
      validate = function(value)
        return value:find "%s" and "A module path cannot contain spaces" or nil
      end,
    },
  },

  command = function(ctx)
    return { "go", "mod", "init", ctx.module }
  end,

  after = write_main,
}

return M
