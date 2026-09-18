-- Overrides for ansible-language-server.
--
-- This has to live in after/lsp/, not lsp/: nvim merges every lsp/<name>.lua on the
-- runtimepath with tbl_deep_extend("force", ...) and nvim-lspconfig sits *after*
-- ~/.config/nvim, so anything set in lsp/ansiblels.lua would be overwritten by its
-- bundled defaults (which hardcode "python" / "ansible" / "ansible-lint").

local mason_venv = vim.fn.stdpath "data" .. "/mason/packages/ansible-lint/venv/bin/"

-- Prefer whatever is on PATH (mason's bin dir is prepended in lua/options.lua, and the
-- dnf ansible-core lands in /usr/bin); fall back to the mason ansible-lint venv, which
-- pulls ansible-core in as a dependency but does not symlink its binaries.
local function pick(name)
  if vim.fn.executable(name) == 1 then
    return vim.fn.exepath(name)
  end
  if vim.fn.executable(mason_venv .. name) == 1 then
    return mason_venv .. name
  end
  return name
end

---@type vim.lsp.Config
return {
  root_markers = { "ansible.cfg", ".ansible-lint", "requirements.yml", ".git" },
  settings = {
    ansible = {
      python = { interpreterPath = pick "python3" },
      ansible = { path = pick "ansible" },
      executionEnvironment = { enabled = false },
      validation = {
        enabled = true,
        -- ansible-lint runs yamllint internally, which is why nvim-lint suppresses
        -- yamllint for yaml.ansible (see lua/configs/lint.lua).
        lint = { enabled = true, path = pick "ansible-lint" },
      },
    },
  },
}
