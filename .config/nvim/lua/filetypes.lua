-- Filetype detection for the DevOps toolchains.
--
-- Only rules Neovim does not already get right live here. Deliberately NOT repeated,
-- because nvim already handles them: bare `Jenkinsfile`, `Containerfile`, `*.spec`,
-- `*.tfvars`, and `*.tf` (content-detected -> terraform).
--
-- vim.filetype.match resolves in this order:
--   filename -> pattern (priority >= 0, desc) -> extension -> pattern (priority < 0)
-- The builtin yaml/yml extension rule therefore beats any negative-priority pattern,
-- which is why the Ansible content probe has to sit at priority 1 rather than -1.

-- true when `marker` exists in this file's directory or any directory above it
local function has_ancestor(path, marker)
  local dir = path and vim.fs.dirname(path)
  if not dir or dir == "" then
    return false
  end
  return vim.fs.find(marker, { path = dir, upward = true, type = "file", limit = 1 })[1] ~= nil
end

local function helm_template(path)
  return has_ancestor(path, "Chart.yaml") and "helm" or nil
end

local function helm_values(path)
  return has_ancestor(path, "Chart.yaml") and "yaml.helm-values" or nil
end

-- A playbook, role file or inventory that none of the path rules caught. Reads the buffer,
-- so it only fires for a real buffer -- never for a bare vim.filetype.match { filename = x }.
local ANSIBLE_HINTS = {
  "^%s*%-?%s*hosts:",
  "^%s*tasks:",
  "^%s*become:",
  "^%s*gather_facts:",
  "ansible%.builtin%.",
}

local function ansible_probe(_, bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 40, false)) do
    for _, hint in ipairs(ANSIBLE_HINTS) do
      if line:match(hint) then
        return "yaml.ansible"
      end
    end
  end
end

local pattern = {
  -- Ansible, by well-known layout. Priority 10 so these beat the content probe below.
  [".*/playbooks/.*%.ya?ml"] = { "yaml.ansible", { priority = 10 } },
  [".*/tasks/.*%.ya?ml"] = { "yaml.ansible", { priority = 10 } },
  [".*/handlers/.*%.ya?ml"] = { "yaml.ansible", { priority = 10 } },
  [".*/group_vars/.*%.ya?ml"] = { "yaml.ansible", { priority = 10 } },
  [".*/host_vars/.*%.ya?ml"] = { "yaml.ansible", { priority = 10 } },
  [".*/roles/[^/]+/vars/.*%.ya?ml"] = { "yaml.ansible", { priority = 10 } },
  [".*/roles/[^/]+/defaults/.*%.ya?ml"] = { "yaml.ansible", { priority = 10 } },
  [".*/roles/[^/]+/meta/.*%.ya?ml"] = { "yaml.ansible", { priority = 10 } },
  [".*/molecule/[^/]+/.*%.ya?ml"] = { "yaml.ansible", { priority = 10 } },

  -- Helm. Gated on a Chart.yaml ancestor so an unrelated templates/ dir is left alone.
  [".*/templates/.*%.ya?ml"] = { helm_template, { priority = 10 } },
  [".*/templates/.*%.tpl"] = { helm_template, { priority = 10 } },
  [".*/values%.ya?ml"] = { helm_values, { priority = 10 } },
  [".*/values%-.*%.ya?ml"] = { helm_values, { priority = 10 } },

  -- Anything else that looks like a playbook. Priority 1: after the layout rules above,
  -- still ahead of the builtin yaml extension rule.
  [".*%.ya?ml"] = { ansible_probe, { priority = 1 } },

  -- Compose variants beyond the exact filenames below
  ["compose%..*%.ya?ml"] = "yaml.docker-compose",
  ["docker%-compose%..*%.ya?ml"] = "yaml.docker-compose",

  -- GitLab CI includes
  [".*/%.gitlab/.*%.ya?ml"] = "yaml.gitlab",

  -- Jenkinsfile variants (bare `Jenkinsfile` is builtin)
  ["Jenkinsfile%..*"] = "groovy",
  [".*%.[jJ]enkinsfile"] = "groovy",

  -- Dockerfile variants. Without this, `Dockerfile.builder` is detected as ruby.
  ["Dockerfile%..*"] = "dockerfile",
  [".*%.[dD]ockerfile"] = "dockerfile",

  -- Podman quadlets. Only `.container` is unambiguous enough for a bare extension rule
  -- (below); the rest are path-scoped so they cannot hijack unrelated files. Real
  -- /containers/systemd/ and /etc/containers/systemd/ paths are already builtin.
  [".*/quadlet/.*%.volume"] = "systemd",
  [".*/quadlet/.*%.network"] = "systemd",
  [".*/quadlet/.*%.pod"] = "systemd",
  [".*/quadlet/.*%.kube"] = "systemd",
  [".*/quadlet/.*%.build"] = "systemd",
  [".*/quadlet/.*%.image"] = "systemd",

  -- udev rules; nvim otherwise guesses `hog`
  [".*/udev/rules%.d/.*%.rules"] = "udevrules",
  [".*/rules%.d/.*%.rules"] = "udevrules",
}

vim.filetype.add {
  filename = {
    [".gitlab-ci.yml"] = "yaml.gitlab",
    [".gitlab-ci.yaml"] = "yaml.gitlab",
    ["compose.yml"] = "yaml.docker-compose",
    ["compose.yaml"] = "yaml.docker-compose",
    ["docker-compose.yml"] = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["ansible.cfg"] = "dosini",
    ["values.yml"] = helm_values,
    ["values.yaml"] = helm_values,
  },

  extension = {
    -- Jinja templates. This loses the underlying language -- nginx.conf.j2 and
    -- defaults.yml.j2 both become `jinja` -- but there is no combined parser, and
    -- getting the delimiters right is what keeps playbooks working.
    j2 = "jinja",
    jinja2 = "jinja",

    -- systemd units. nvim only detects these under a path containing /systemd/.
    service = "systemd",
    timer = "systemd",
    socket = "systemd",
    mount = "systemd",
    automount = "systemd",
    slice = "systemd",
    target = "systemd",
    path = "systemd",
    container = "systemd",

    -- dnf/yum repository files
    repo = "dosini",

    -- MSBuild fragments. nvim already detects .csproj and .slnx as xml, but not these,
    -- so they get no filetype and therefore no lemminx / typos_lsp at all.
    props = "xml",
    targets = "xml",
  },

  pattern = pattern,
}
