-- Toolchain providers for the project command picker.
--
-- Adding a language means adding one entry here.
--
--   name     label shown when more than one provider matches
--   plugin   lazy.nvim plugin to force-load before running anything
--   ensure   optional extra step to make the plugin's commands exist
--   lsp      LSP client name that also implies this toolchain is active
--   ft       filetypes this toolchain owns; a provider matching the current buffer's
--            filetype wins outright, so a repo with a Dockerfile + *.tf + Chart.yaml
--            does not force a chooser on every keypress
--   match    predicate over a filename, searched upward from the buffer/cwd
--   deep     optional fallback: scan downward when nothing matched upward
--   commands opens the toolchain's own command picker

local function ends_with(name, suffix)
  return name:sub(-#suffix) == suffix
end

local function current_file()
  return vim.fn.expand "%:p"
end

-- Directory holding `marker`, searched upward from the current file; cwd if not found.
local function root_for(marker)
  local from = current_file()
  from = from ~= "" and vim.fs.dirname(from) or vim.uv.cwd()
  local hit = vim.fs.find(marker, { path = from, upward = true, type = "file", limit = 1 })[1]
  return hit and vim.fs.dirname(hit) or vim.uv.cwd()
end

-- One reusable split for every toolchain command, so they do not pile up windows.
local function term(cmd)
  require("nvchad.term").runner { id = "devops", pos = "sp", cmd = cmd }
end

local function in_dir(dir, cmd)
  return "cd " .. vim.fn.shellescape(dir) .. " && " .. cmd
end

-- items: { { "label", "shell command" | function }, ... }
local function menu(prompt, items)
  vim.ui.select(items, { prompt = prompt, format_item = function(i) return i[1] end }, function(choice)
    if not choice then return end
    if type(choice[2]) == "function" then choice[2]() else term(choice[2]) end
  end)
end

-- ansible-doc has thousands of entries; list them off the main loop, then pick.
local function ansible_doc_picker(root)
  vim.system({ "ansible-doc", "-l" }, { cwd = root, text = true }, function(out)
    if out.code ~= 0 then
      vim.schedule(function() vim.notify("ansible-doc failed: " .. (out.stderr or ""), vim.log.levels.ERROR) end)
      return
    end
    local modules = {}
    for line in (out.stdout or ""):gmatch "[^\n]+" do
      local name = line:match "^(%S+)"
      if name then modules[#modules + 1] = name end
    end
    vim.schedule(function()
      vim.ui.select(modules, { prompt = "ansible-doc" }, function(m)
        if m then term(in_dir(root, "ansible-doc " .. vim.fn.shellescape(m))) end
      end)
    end)
  end)
end

-- ansible-vault needs a real tty, hence the terminal rather than vim.fn.system.
local function vault(root, action, file)
  term(in_dir(root, "ansible-vault " .. action .. " " .. vim.fn.shellescape(file)))
  if action == "decrypt" or action == "edit" then
    vim.notify("run :e! after the vault command finishes to reload the buffer", vim.log.levels.INFO)
  end
end

return {
  {
    name = "dotnet",
    plugin = "easy-dotnet.nvim",
    lsp = "easy_dotnet",
    -- .sln is filetype `solution` and .csproj/.props/.targets are `xml`; without those
    -- here, opening the picker from a project file falls back to the ambiguous list.
    ft = { "cs", "fsharp", "vb", "solution", "xml" },
    match = function(name)
      return ends_with(name, ".sln") or ends_with(name, ".slnx") or ends_with(name, ".csproj")
    end,
    commands = function() vim.cmd "Dotnet" end,
  },

  {
    name = "flutter",
    plugin = "flutter-tools.nvim",
    -- flutter-tools only registers its commands on BufEnter of a dart file or
    -- pubspec.yaml, so fire that autocmd ourselves when we came from elsewhere.
    ensure = function()
      if vim.fn.exists ":FlutterRun" ~= 2 then
        vim.api.nvim_exec_autocmds("BufEnter", { group = "FlutterToolsGroup", pattern = "pubspec.yaml" })
      end
    end,
    lsp = "dartls",
    ft = { "dart" },
    match = function(name) return name == "pubspec.yaml" end,
    -- repo root opened with the flutter project in a subfolder: nothing matches
    -- upward, so look below (bounded scan; discover never loads flutter-tools)
    deep = function() return #require("configs.flutter.discover").projects(vim.uv.cwd()) > 0 end,
    commands = function()
      require("configs.flutter").refresh()
      pcall(require("telescope").load_extension, "flutter")
      vim.cmd "Telescope flutter commands"
    end,
  },

  {
    name = "ansible",
    lsp = "ansiblels",
    ft = { "yaml.ansible" },
    match = function(name)
      return name == "ansible.cfg" or name == "site.yml" or name == "site.yaml" or name:match "^playbook.*%.ya?ml$" ~= nil
    end,
    commands = function()
      local root, file = root_for "ansible.cfg", current_file()
      local pb = vim.fn.shellescape(file)
      menu("ansible", {
        { "syntax-check this file", in_dir(root, "ansible-playbook --syntax-check " .. pb) },
        { "run (check mode, diff)", in_dir(root, "ansible-playbook --check --diff " .. pb) },
        { "run", in_dir(root, "ansible-playbook " .. pb) },
        { "list hosts", in_dir(root, "ansible-playbook --list-hosts " .. pb) },
        { "list tasks", in_dir(root, "ansible-playbook --list-tasks " .. pb) },
        { "inventory --graph", in_dir(root, "ansible-inventory --graph") },
        { "ansible-doc (word under cursor)", in_dir(root, "ansible-doc " .. vim.fn.shellescape(vim.fn.expand "<cword>")) },
        { "ansible-doc (pick module)", function() ansible_doc_picker(root) end },
        { "galaxy install -r requirements.yml", in_dir(root, "ansible-galaxy install -r requirements.yml") },
        { "vault view", function() vault(root, "view", file) end },
        { "vault edit", function() vault(root, "edit", file) end },
        { "vault encrypt", function() vault(root, "encrypt", file) end },
        { "vault decrypt", function() vault(root, "decrypt", file) end },
        { "molecule test", in_dir(root, "molecule test") },
        { "molecule converge", in_dir(root, "molecule converge") },
        { "molecule verify", in_dir(root, "molecule verify") },
      })
    end,
  },

  {
    name = "terraform",
    lsp = "terraformls",
    ft = { "terraform", "terraform-vars" },
    match = function(name) return ends_with(name, ".tf") end,
    commands = function()
      local root = root_for "main.tf"
      menu("terraform", {
        { "init", in_dir(root, "terraform init") },
        { "validate", in_dir(root, "terraform validate") },
        { "plan", in_dir(root, "terraform plan") },
        { "apply", in_dir(root, "terraform apply") },
        { "fmt -recursive", in_dir(root, "terraform fmt -recursive") },
        { "tflint", in_dir(root, "tflint") },
      })
    end,
  },

  {
    name = "container",
    lsp = "docker_language_server",
    ft = { "dockerfile", "yaml.docker-compose" },
    match = function(name)
      return name == "Dockerfile" or name == "Containerfile" or name:match "^docker%-compose%.ya?ml$" ~= nil
        or name:match "^compose%.ya?ml$" ~= nil
    end,
    commands = function()
      local root, file = root_for "Dockerfile", current_file()
      menu("container", {
        { "docker build .", in_dir(root, "docker build .") },
        { "podman build .", in_dir(root, "podman build .") },
        { "hadolint this file", in_dir(root, "hadolint " .. vim.fn.shellescape(file)) },
        { "compose up -d", in_dir(root, "docker compose up -d") },
        { "compose down", in_dir(root, "docker compose down") },
        { "compose logs -f", in_dir(root, "docker compose logs -f") },
        { "compose ps", in_dir(root, "docker compose ps") },
        { "podman ps -a", "podman ps -a" },
      })
    end,
  },

  {
    name = "helm",
    lsp = "helm_ls",
    ft = { "helm", "yaml.helm-values" },
    match = function(name) return name == "Chart.yaml" end,
    commands = function()
      local root = root_for "Chart.yaml"
      menu("helm", {
        { "lint", in_dir(root, "helm lint .") },
        { "template", in_dir(root, "helm template .") },
        { "template --debug", in_dir(root, "helm template --debug .") },
        { "dependency update", in_dir(root, "helm dependency update") },
      })
    end,
  },

  {
    name = "kubernetes",
    ft = { "yaml" },
    match = function(name) return name == "kustomization.yaml" or name == "kustomization.yml" end,
    commands = function()
      local root = root_for "kustomization.yaml"
      menu("kubernetes", {
        { "kustomize build", in_dir(root, "kustomize build .") },
        { "kubectl apply --dry-run=server -k .", in_dir(root, "kubectl apply --dry-run=server -k .") },
        { "kubectl diff -k .", in_dir(root, "kubectl diff -k .") },
        { "kube-linter lint .", in_dir(root, "kube-linter lint .") },
      })
    end,
  },

  {
    name = "rpm",
    lsp = "rpmspec",
    ft = { "spec" },
    match = function(name) return ends_with(name, ".spec") end,
    commands = function()
      local file = current_file()
      local root = vim.fs.dirname(file)
      local spec = vim.fn.shellescape(file)
      menu("rpm", {
        { "rpmlint", in_dir(root, "rpmlint " .. spec) },
        { "rpmspec -P (expand macros)", in_dir(root, "rpmspec -P " .. spec) },
        { "rpmspec -q --requires", in_dir(root, "rpmspec -q --requires " .. spec) },
        { "spectool -g -R (fetch sources)", in_dir(root, "spectool -g -R " .. spec) },
        { "dnf builddep", in_dir(root, "sudo dnf builddep " .. spec) },
        { "rpmbuild -bs (srpm)", in_dir(root, "rpmbuild -bs " .. spec) },
        { "rpmbuild -ba (full)", in_dir(root, "rpmbuild -ba " .. spec) },
        { "mock --rebuild (srpm in ~/rpmbuild/SRPMS)", in_dir(root, "mock --rebuild ~/rpmbuild/SRPMS/*.src.rpm") },
      })
    end,
  },

  {
    name = "systemd",
    lsp = "systemd_lsp",
    ft = { "systemd" },
    match = function(name)
      return name:match "%.service$" ~= nil or name:match "%.timer$" ~= nil or name:match "%.container$" ~= nil
    end,
    commands = function()
      local file = current_file()
      local unit = vim.fn.fnamemodify(file, ":t")
      menu("systemd", {
        { "systemd-analyze verify", "systemd-analyze verify " .. vim.fn.shellescape(file) },
        { "systemctl status " .. unit, "systemctl status " .. vim.fn.shellescape(unit) },
        { "systemctl --user status " .. unit, "systemctl --user status " .. vim.fn.shellescape(unit) },
        { "journalctl -u " .. unit .. " -f", "journalctl -u " .. vim.fn.shellescape(unit) .. " -f" },
        { "journalctl --user -u " .. unit .. " -f", "journalctl --user -u " .. vim.fn.shellescape(unit) .. " -f" },
        { "systemctl daemon-reload", "sudo systemctl daemon-reload" },
        { "systemctl --user daemon-reload", "systemctl --user daemon-reload" },
      })
    end,
  },

  {
    name = "jenkins",
    ft = { "groovy" },
    match = function(name) return name == "Jenkinsfile" or name:match "^Jenkinsfile%." ~= nil end,
    commands = function()
      local file = current_file()
      local root = root_for "Jenkinsfile"
      menu("jenkins", {
        { "npm-groovy-lint", in_dir(root, "npm-groovy-lint " .. vim.fn.shellescape(file)) },
        { "npm-groovy-lint --fix", in_dir(root, "npm-groovy-lint --fix " .. vim.fn.shellescape(file)) },
      })
    end,
  },
}
