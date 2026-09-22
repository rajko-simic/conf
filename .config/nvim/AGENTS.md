# AGENTS.md

## Repo identity

This is a personal Neovim config built on the **NvChad v2.5 runtime**, but it is *not* a stock NvChad install. There is no `NvChad/NvChad` dependency and no `lua/nvchad/` directory — the config owns all of its own options, mappings, autocmds, plugin specs, and per-plugin configs.

What is still consumed from NvChad upstream, as ordinary lazy.nvim plugins:

| Plugin | Provides |
|---|---|
| `nvchad/ui` | The `nvchad.*` lua namespace (`nvchad` init, `nvchad.stl`, `nvchad.tabufline`, `nvchad.term`, `nvchad.themes`, `nvchad.lsp`, `nvchad.icons`, `nvchad.nvdash`, `nvchad.cheatsheet`), plus `nvconfig` and `colors/nvchad.lua` |
| `nvchad/base46` | Theme/highlight compiler (`vim.g.base46_cache`) |
| `nvzone/volt`, `nvzone/minty` | UI primitives, colour pickers |

**Important:** `require "nvchad.…"` in this config always refers to the `nvchad/ui` plugin. Do not rename or "localise" those requires — they are not config-local modules.

## Version control

This directory is **not** its own git repo — it is tracked in the bare dotfiles repo at
`~/.dotfiles` with `$HOME` as the work tree. Use the shell alias:

```
dotfiles status --porcelain -- ':/.config/nvim'
dotfiles add -- ':/.config/nvim' && dotfiles commit
```

Plain `git` inside this directory resolves upward to a zero-commit repo at `/home/rajko` and
reports the whole home directory as untracked, which makes the config look unversioned. Pathspecs
are relative to the cwd, hence the `:/`-prefixed form above.

## Directory layout

| Path | Purpose |
|---|---|
| `init.lua` | Entry point: lazy bootstrap, `{ import = "plugins" }`, theme load, core module requires |
| `lua/chadrc.lua` | NvChad UI config (theme, dashboard, tabufline, terminal) — mirrors `nvconfig.lua` from `nvchad/ui` |
| `lua/options.lua` | All `vim.opt`/`vim.o` settings |
| `lua/mappings.lua` | All global keymaps (see **Keymaps** below) |
| `lua/filetypes.lua` | **All** `vim.filetype.add` rules (DevOps toolchains, MSBuild fragments). Required from `init.lua` *before* `lazy.setup` |
| `lua/autocmds.lua` | Autocommands, incl. the `User FilePost` event most plugins lazy-load on |
| `lua/plugins/*.lua` | **Plugin specs, split by domain** — see below |
| `lua/configs/*.lua` | Per-plugin config (dap, treesitter, mason, telescope, blink, …) |
| `lua/configs/lsp.lua` | Shared LSP behaviour: `on_attach` keymaps, capabilities, diagnostics, `defaults()` |
| `lua/configs/lspconfig.lua` | Calls `configs.lsp.defaults()`, then the server list for `vim.lsp.enable()` |
| `lua/configs/lazy.lua` | lazy.nvim options (all plugins lazy by default) |
| `after/lsp/*.lua` | **All** per-server overrides, one file per server. There is deliberately no `lsp/` dir — see **LSP** |
| `lua/lsp_overrides/health.lua` | `:checkhealth lsp_overrides` — flags an override that has drifted into a no-op |
| `snippets/` | blink.cmp's default snippet search path (`package.json` + per-language JSON) |
| `themes/vs2022.lua` | Custom base46 theme (base_30 + base_16 palette) |

## Plugin specs

`init.lua` does a single `{ import = "plugins" }`; lazy.nvim loads **every** file in `lua/plugins/`, so a new domain file needs no registration.

| File | Contents |
|---|---|
| `core.lua` | plenary, base46, nvchad/ui, volt, minty, nvim-web-devicons (sole icon provider) |
| `ui.lua` | noice, which-key, indent-blankline, nvim-tree, precognition |
| `lsp.lua` | nvim-lspconfig, mason, blink.cmp, lspsaga, symbol-usage, trouble, schemastore |
| `editor.lua` | telescope, undotree, treesitter (+context), conform, refactoring, neovim-project |
| `git.lua` | gitsigns, lazygit |
| `debug.lua` | nvim-dap, nvim-dap-view, nvim-dap-virtual-text, nvim-nio |
| `test.lua` | neotest, using easy-dotnet's built-in adapter (`require "easy-dotnet.neotest"`). `ft`-gated, **not** `VeryLazy`: easy-dotnet is a dependency, so a startup trigger would pull the .NET toolchain into every project |
| `lang.lua` | easy-dotnet, flutter-tools, pubspec-assist (TypeScript is served by `ts_ls`, see LSP) |
| `markdown.lua` | render-markdown, markdown-plus |
| `devops.lua` | nvim-lint (the linting layer) |

### Adding plugins

1. Add the spec to the matching `lua/plugins/<domain>.lua`. **Declare each plugin exactly once** — a plugin split across two files silently merges and the later spec's fields win, which is how this config previously ended up with duplicate `conform`/`lspsaga`/`lspconfig` entries.
2. Put non-trivial config in `lua/configs/<plugin>.lua` and reference it as `opts = require "configs.<plugin>"` or `config = function() require "configs.<plugin>" end`.
3. All plugins are `lazy = true` by default — set an appropriate trigger (`event`, `ft`, `cmd`, `keys`). `event = "User FilePost"` is the config's "a real file is open" event, fired from `lua/autocmds.lua`.
4. Keep `require` calls inside the keymap/config callback rather than at the top of `lua/mappings.lua` — a top-level `require` forces the plugin to load at startup and defeats its lazy trigger.
5. A plugin with no `event`/`cmd`/`ft` and no `require` from a keymap or another plugin never loads. Either wire it or delete it — do not leave dormant specs.

## Keymaps

Leader is `<Space>`, `timeoutlen = 400`. One prefix per domain; keep new maps inside the matching prefix:

| Prefix | Domain | Defined in |
|---|---|---|
| `<leader>f` | find (telescope: `ff` files, `fa` all files, `fw` grep, `fb` buffers, `fo` oldfiles, `fz` in-buffer, `fh` help, `fM` marks, `fc`/`fs` git commits/status, `ft` terms, `fj` jumplist scoped to cwd via `configs/jumplist.lua`) + `fm` format (conform) | `mappings.lua` |
| `<leader>l` | LSP actions via lspsaga (`la` code action, `lp` peek, `lr`/`lR` rename, `le` line diagnostics, `li`/`lo` calls) | `configs/lsp.lua` `on_attach`, **buffer-local** |
| `<leader>r` | refactoring.nvim (`rr` select, `re` extract fn, `rf` extract to file, `rv` extract var, `ri`/`rI` inline var/fn) | `mappings.lua` |
| `<leader>d` | DAP + dap-view (`db`/`dB` breakpoints, `dl` run last, `do`/`dx`/`dt` view, `dw` watch, `dj`…`dr` jump to view) | `mappings.lua` |
| `<leader>t` / `<leader>T` | Trouble (`tx`/`tX` diagnostics, `ts` symbols, `tL`/`tQ` loclist/qflist, `tl` lint buffer now) / neotest | `mappings.lua` |
| `<leader>g` | git (`gw`/`gf` lazygit, `gb`/`gl` blame, `gd` deleted, `gc` commit) | `mappings.lua` |
| `<leader>p` | projects (`pl`, `ph`, `pd*`) | `mappings.lua` |
| `<leader>s` | settings/toggles (`sn`, `sr`, `sw`, `sp` precognition, `sc` cheatsheet, `st` theme) | `mappings.lua` |
| `<leader>w` | which-key (`wk`, `wK`) | `mappings.lua` |
| `<leader>c` / `\` | project command picker (`configs/cmdpicker`) | `mappings.lua` |
| `<leader>e`, `<leader>u`, `<leader>n`, `<leader>x`, `<leader>h`, `<leader>v`, `<leader>/` | singles: tree focus, undotree toggle, new buffer, close buffer, h/v terminal, comment | `mappings.lua` |

LSP navigation (buffer-local, `configs/lsp.lua`): `gd` definition, `gD` declaration, `gy` type definition, `gh` lspsaga finder (definition + references + implementation), `K` hover, `]d`/`[d` diagnostics — all lspsaga except `gD`. Do **not** map bare `gr`: Neovim 0.11+ ships native `grr/grn/gra/gri/grt/grx` and a `gr` map delays every one of them by `timeoutlen`.

Rules: no two maps on the same `lhs`+mode (the later one silently wins — `:checkhealth which-key` reports overlaps); LSP maps go in `configs/lsp.lua` `on_attach`, everything else in `mappings.lua`.

## Lua formatting — StyLua (`.stylua.toml`)

- `column_width = 120`
- `indent_type = "Spaces"`, `indent_width = 2`
- `quote_style = "AutoPreferDouble"`
- `call_parentheses = "None"` — omit parens on single-arg calls, e.g. `require "foo"` not `require("foo")`

Run formatter: `stylua <file>` (installed via Mason). Note `lua/mappings.lua` and `lua/configs/cmdpicker/` are deliberately kept in a compact one-line-per-mapping style that StyLua would expand; don't bulk-reformat them.

## LSP

Servers are listed in `lua/configs/lspconfig.lua` and enabled via `vim.lsp.enable(servers)`. To add a server: append its name to the `servers` table, then ensure it is installed via Mason (`lua/configs/mason.lua`).

**Overrides go in `after/lsp/<server>.lua`. There is no `lsp/` directory, and adding one is a mistake.** `vim.lsp.config` merges *every* `lsp/<name>.lua` on the runtimepath with `tbl_deep_extend("force", ...)`, last one winning, and lazy.nvim puts plugin directories *after* `~/.config/nvim`. Measured rtp indices: `~/.config/nvim` = **1**, `nvim-lspconfig` = **7**, `~/.config/nvim/after` = **18**. A file in `lsp/` is therefore overwritten by lspconfig on every key they both set; a file in `after/lsp/` always wins. This was not theoretical: `emmet_ls`'s narrowed filetype list was being ignored, so it attached to ~17 filetypes instead of the 5 configured, and `bicep` fell back to `.git` as its only root marker.

**nvim-lspconfig is still required.** nvim 0.11+ owns the *mechanism* (`vim.lsp.config`, `vim.lsp.enable`, the `lsp/` runtime dir) but ships **zero** server definitions; `$VIMRUNTIME/lsp/` is empty while lspconfig ships 417. Of the 35 enabled servers, **19 have no local file at all** and exist only because lspconfig defines them.

**An override contains only what differs from upstream.** Never copy an upstream default in just to have it written down: it becomes a frozen snapshot that blocks future fixes, and since `after/` wins, a stale copy is actively harmful. Auditing the old `lsp/` directory found 7 of 16 files were exactly this — pure copies, or worse than upstream (a static `cmd` displacing lspconfig's function that prefers a project-local `node_modules/.bin` binary). Each file carries an `-- Inherited:` comment naming what it leaves to upstream.

Run **`:checkhealth lsp_overrides`** after touching these; it reports any key that now equals upstream and should be deleted.

A filetype that nothing ever produces is a dead entry. `csproj`, `props`, `targets` and `slnx` are *not* filetypes: nvim maps `.csproj`/`.slnx` to `xml`, and `.props`/`.targets` had no filetype at all until `lua/filetypes.lua` mapped them to `xml` too. Listing such names in a server's `filetypes` does nothing — fix detection in `lua/filetypes.lua` instead.

To check what a server actually resolved to: `:lua =vim.lsp.config.<name>`.

Compound filetypes do **not** fall back: `vim.lsp.enable` filters with an exact `vim.tbl_contains` on `filetypes`, so a server listing `yaml` never attaches to a `yaml.ansible` buffer. That is why `ansiblels` and `yamlls` coexist without conflict, and why anything that should see `yaml.helm-values` has to name it verbatim.

DevOps servers and their overrides:

| Server | Override | Note |
|---|---|---|
| `ansiblels` | `after/lsp/ansiblels.lua` | resolves `python3`/`ansible`/`ansible-lint` from PATH, falling back to the mason ansible-lint venv. Needs `ansible-core` + `ansible-lint` from dnf — mason has no `ansible`/`ansible-doc` package |
| `helm_ls` | `after/lsp/helm_ls.lua` | `helm-ls.yamlls.enabled = false`; it otherwise spawns a second yaml-language-server on values files |
| `yamlls` | `after/lsp/yamlls.lua` | schemastore set with Kubernetes/manifest globs merged in; inherits upstream's `cmd` and `filetypes` (the latter adds `yaml.helm-values`) |
| `bicep` | `after/lsp/bicep.lua` | **load-bearing**: lspconfig deliberately ships no `cmd` for bicep, so without this the server cannot start |
| `typos_lsp` | `after/lsp/typos_lsp.lua` | upstream sets no `filetypes`, and a nil list means the server attaches to *every* buffer |
| `docker_language_server` | — | replaced `dockerls`; covers dockerfile, compose *and* bake HCL in one process |
| `jinja_lsp` | — | validates *minijinja*, so `*.j2` Ansible templates show some false positives. Drop the name from `servers` to disable |
| `rpmspec`, `systemd_lsp`, `tflint` | — | upstream defaults are fine |

Shared behaviour (on-attach keymaps, blink capabilities, diagnostic config, semantic-token suppression) lives in `lua/configs/lsp.lua`. Inlay hints are enabled globally in `init.lua`.

**LSP UI ownership — one plugin per job, keep it that way:**

| Job | Owner | Disabled elsewhere |
|---|---|---|
| hover, finder, rename, code action, peek, diagnostics float/jump | lspsaga (`configs/lspsaga.lua`) | noice `lsp.hover`, native `K`/`gr*` not remapped |
| signature help (insert mode) | blink.cmp (`configs/blink.lua`, `<C-k>` toggle) | NvChad `M.lsp.signature = false` in `chadrc.lua`; noice `lsp.signature` |
| LSP progress | NvChad statusline `lsp_msg` | noice `lsp.progress` |
| diagnostics lists, document symbols | trouble.nvim (`<leader>t*`) | lspsaga outline not mapped |
| completion | blink.cmp | — |

TypeScript is served by `ts_ls` (`lsp/ts_ls.lua`). Do not add `typescript-tools.nvim` alongside it — they conflict.

C# uses `easy-dotnet.nvim` with Roslyn LSP + roslynator — configured in `lua/configs/easydotnet.lua`. Do not add `omnisharp` or `csharp_ls` to the servers list.

## snacks.nvim

One plugin, modules enabled individually. `Snacks.setup` turns on **exactly** the keys it is handed
(`snacks/init.lua`: `for k in pairs(opts) do opts[k].enabled = opts[k].enabled == nil or opts[k].enabled end`),
so an absent key is off. Config lives inline in the spec in `lua/plugins/ui.lua`.

On: `notifier` (the `vim.notify` backend — see **Notifications**), `picker` (**only** for
`ui_select`), `input`, `bigfile`, `quickfile`, `indent`, `words`, `scope`, `gitbrowse`, `scratch`.

Deliberately off, with the reason, so this is not re-litigated:

| module | why off |
|---|---|
| `picker` as a telescope replacement | telescope is a hard `dependencies` entry of easy-dotnet, flutter-tools and neovim-project, so it stays installed either way — swapping the UI buys no reduction. It is enabled for `ui_select` alone and rebinds nothing |
| `explorer` | nvim-tree carries 80 lines of configuration (right side, width 40, window picker with dap-view exclusions, diagnostic severity range) and is a persistent sidebar; explorer is a picker in disguise |
| `image` | Konsole has no kitty graphics protocol. `:checkhealth snacks` reports image errors regardless of the module being disabled — they are noise |
| `dashboard` | nvdash is base46-themed and already has the project buttons |
| `terminal` | `nvchad.term` is wired into `<A-i>/<A-h>/<A-v>` and `Telescope terms` |
| `toggle`, `bufdelete`, `zen`, `statuscolumn` | no gain over what is already mapped |

Retired by these modules: `lazygit.nvim` (→ `snacks.lazygit`), `indent-blankline.nvim`
(→ `snacks.indent`), `dressing.nvim` (→ `snacks.input` + `picker.ui_select`; it was only a soft dep
of flutter-tools and therefore only ever loaded for Dart buffers).

`snacks.lazygit` does **not** overwrite `~/.config/lazygit/config.yml` — it runs `lazygit -cd`, puts
the existing config first in `LG_CONFIG_FILE` and appends only a generated theme file, so the delta
`diffRenderers` wrapper survives.

`picker` and `input` attach on `UIEnter`, which never fires under `nvim --headless`; verifying
`vim.ui.select`/`vim.ui.input` requires a real session.

## Completion

**blink.cmp** is the active completion engine (`lua/configs/blink.lua`). Do not reference `nvim-cmp` or LuaSnip APIs in new code — neither is installed.

## DAP (debugging)

Adapters configured in `lua/configs/dap.lua`:
- **Go**: `dlv` (delve)
- **Rust**: `codelldb`
- **Python**: `debugpy` (prefers a project `.venv`/`venv`, else `python3` from PATH)
- **Bash/sh**: `bash-debug-adapter` (bashdb)
- **Ansible**: `ansibug`, registered for `yaml.ansible` **only when `ansibug` is on PATH**
  (`pip install --user ansibug`; it is not in mason and needs to import the dnf ansible-core)

There is no DAP for Groovy/Jenkinsfile or Terraform — none exists upstream.

Debug keymaps: `<F5>` continue, `<F10>` step over, `<F11>` step into, `<F12>` step out, `<leader>db` toggle breakpoint, `<leader>dB` conditional breakpoint, `<leader>dl` run last. DAP View is under `<leader>d*` too (`configs/dapview.lua` opens/closes it via `dap.listeners` keyed `dap_view`).

## Linting

`nvim-lint` (`lua/plugins/devops.lua` + `lua/configs/lint.lua`) covers the tools that have no
language server behind them. It runs on **`BufWritePost` only** — `npm-groovy-lint` starts a JVM
and `rpmlint`/`tfsec` are slow enough that `InsertLeave` stutters. `<leader>tl` lints on demand.

Three omissions that are deliberate, not oversights:

- **`shellcheck`** — bash-language-server runs it itself from PATH. Wiring it here double-reports.
- **`ansible_lint`** — ansible-language-server runs it, and ansible-lint runs yamllint in turn.
  That is also why `linters_by_ft["yaml.ansible"] = {}` suppresses the `yaml` yamllint entry.
- **`tflint`** — enabled as a language server instead, which is its better mode.

nvim-lint and conform resolve compound filetypes differently, and it matters:

| | suppressing `yaml.ansible` |
|---|---|
| nvim-lint | exact-key lookup first, and an empty table is truthy in Lua — `["yaml.ansible"] = {}` **works** |
| conform | walks `yaml.ansible` -> `ansible` -> `yaml` and **skips empty tables** — needs the function form |

## Treesitter

`nvim-treesitter` tracks the `main` branch. Its `setup()` only takes `install_dir`; `highlight`/`indent`/`ensure_installed` opts from the old API are ignored. `lua/configs/treesitter.lua` therefore installs parsers from `M.ensure_installed` itself and starts highlighting + `indentexpr` per buffer from a `FileType` autocmd. Add languages to `M.ensure_installed`; never re-add `highlight = { enable = true }`.

No `vim.treesitter.language.register` calls are needed. nvim strips sub-filetypes itself
(`get_lang("yaml.ansible") == "yaml"`), and nvim-treesitter's own `plugin/filetypes.lua` already
maps `sh`->`bash`, `terraform-vars`->`terraform` and `dosini`->`ini`. `.spec` files have no parser
and fall back to nvim's built-in `syntax/spec.vim`, which is fine.

## Theme

Themes are a `{ dark, light }` pair, `theme_toggle` in `lua/chadrc.lua`: `material-deep-ocean` /
`default-light`. Custom theme `vs2022` is defined in `themes/vs2022.lua` as a base46 palette.

After any theme or highlight change, regenerate the base46 cache:
```
:lua require("base46").load_all_highlights()
```

### System light/dark

`lua/configs/systheme.lua` follows the desktop preference from the XDG portal
(`org.freedesktop.appearance` / `color-scheme`). `chadrc.lua` derives `theme` from that at load
time, so every path that re-reads chadrc (NvChad's reload-on-save, the picker's cancel) agrees
with the desktop; `init.lua` recompiles the cache when the one on disk was built for the other
half; and one `dbus-monitor` job per nvim instance re-applies the theme live on the portal's
`SettingChanged` signal, the same way the `<leader>st` picker does (`nvconfig.base46.theme` +
`load_all_highlights()`). Without a session bus (ssh, tty) the query is nil and the dark half is
used.

Why the portal and not the terminal, so this is not re-litigated: nvim >= 0.11 re-detects
`'background'` on DEC mode 2031 theme notifications, but Konsole implements neither 2031 nor
DECRQM (verified in `Vt102Emulation.cpp`), so that never fires here; a manual OSC 11 re-query
would need polling to catch scheduled day/night flips. Konsole swaps its own profile on the same
desktop signal (`SyncProfileWithSystemTheme` in `~/.config/konsolerc`), so the two stay in step.
`'background'` is an *output* of base46 -- set from the theme's `type` when the cache is
compiled -- not a driver; do not build on `OptionSet background`.

Consequences: a manual `<leader>st` pick or the tabufline toggle lasts until the next desktop
flip or config reload. The picker's `<CR>` persists by rewriting the quoted theme name in
`chadrc.lua`, which now redefines the matching half of the pair; `toggle_theme()`'s
`theme = "<name>"` rewrite no longer matches anything and is a no-op on disk.

## Mason

`lua/configs/mason.lua` holds `ensure_installed` and a hand-rolled install loop (there is no
mason-lspconfig and no mason-tool-installer). Only the official registry is used — Roslyn comes
from easy-dotnet.nvim, not from `Crashdummyy/mason-lspconfig-extensions`.

mason.nvim is **`cmd`-lazy** and nothing else requires it, so the loop does *not* run on startup.
It runs when you open `:Mason` or invoke **`:MasonEnsure`**. Package lookups are `pcall`-wrapped, so
one unknown name warns instead of aborting every install after it.

`PATH = "skip"`; `lua/options.lua` prepends the mason bin dir manually. That is load-bearing —
bash-language-server finds `shellcheck` through it.

Do not manually install Mason-managed tools outside of that config file. Known gap: `nil` (Nix LSP)
is a cargo source build and is not installed.
