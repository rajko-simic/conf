-- Upstream sets no `filetypes`, so like typos_lsp it attaches to *every* buffer -- including
-- ones whose contents should never leave the machine. root_dir withholds on_dir for those,
-- which keeps the server off the buffer entirely.
-- Telemetry: upstream sends "all".
-- Inherited: cmd, init_options, on_attach (:LspCopilotSignIn / :LspCopilotSignOut).

local home = vim.env.HOME

-- Lua patterns matched against the full path of the buffer.
local secret_paths = {
  "/%.env$",
  "/%.env%.[^/]*$",
  "%.tfvars$",
  "%.tfstate$",
  "%.pem$",
  "%.key$",
  "%.p12$",
  "%.pfx$",
  "/%.netrc$",
  "/%.npmrc$",
  "/%.pgpass$",
  "/%.git%-credentials$",
  "^" .. vim.pesc(home) .. "/%.ssh/",
  "^" .. vim.pesc(home) .. "/%.gnupg/",
  "^" .. vim.pesc(home) .. "/%.aws/",
  "^" .. vim.pesc(home) .. "/%.azure/",
  "^" .. vim.pesc(home) .. "/%.kube/",
  "^" .. vim.pesc(home) .. "/%.docker/config%.json$",
}

---@type vim.lsp.Config
return {
  settings = {
    telemetry = { telemetryLevel = "off" },
  },

  root_dir = function(bufnr, on_dir)
    if vim.bo[bufnr].buftype ~= "" then
      return
    end
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path == "" then
      return
    end
    for _, pat in ipairs(secret_paths) do
      if path:find(pat) then
        return
      end
    end
    on_dir(vim.fs.root(bufnr, ".git") or vim.fs.dirname(path))
  end,
}
