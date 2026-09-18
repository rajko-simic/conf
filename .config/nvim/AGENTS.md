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

## Directory layout

| Path | Purpose |
|---|---|
| `init.lua` | Entry point: lazy bootstrap, `{ import = "plugins" }`, theme load, core module requires |
| `lua/chadrc.lua` | NvChad UI config (theme, dashboard, tabufline, terminal) — mirrors `nvconfig.lua` from `nvchad/ui` |
| `lua/options.lua` | All `vim.opt`/`vim.o` settings |
| `lua/mappings.lua` | All global keymaps (see **Keymaps** below) |
| `lua/autocmds.lua` | Autocommands, incl. the `User FilePost` event most plugins lazy-load on |
| `lua/plugins/*.lua` | **Plugin specs, split by domain** — see below |
| `lua/configs/*.lua` | Per-plugin config (dap, treesitter, mason, telescope, blink, …) |
| `lua/configs/lsp.lua` | Shared LSP behaviour: `on_attach` keymaps, capabilities, diagnostics, `defaults()` |
| `lua/configs/lspconfig.lua` | Calls `configs.lsp.defaults()`, then the server list for `vim.lsp.enable()` |
| `lua/configs/lazy.lua` | lazy.nvim options (all plugins lazy by default) |
| `lsp/*.lua` | Per-server `vim.lsp.config` overrides (native `lsp/` runtime dir) |
| `themes/vs2022.lua` | Custom base46 theme (base_30 + base_16 palette) |

## Plugin specs

`init.lua` does a single `{ import = "plugins" }`; lazy.nvim loads **every** file in `lua/plugins/`, so a new domain file needs no registration.

| File | Contents |
|---|---|
| `core.lua` | plenary, base46, nvchad/ui, volt, minty, nvim-web-devicons (sole icon provider) |
| `ui.lua` | noice, which-key, indent-blankline, nvim-tree, precognition |
| `lsp.lua` | nvim-lspconfig, mason, blink.cmp, lspsaga, symbol-usage, trouble, schemastore |
| `editor.lua` | telescope, treesitter (+context), conform, refactoring, neovim-project |
| `git.lua` | gitsigns, lazygit |
| `debug.lua` | nvim-dap, nvim-dap-view, nvim-dap-virtual-text, nvim-nio |
| `test.lua` | neotest (+ neotest-vstest) |
| `lang.lua` | easy-dotnet, flutter-tools, pubspec-assist (TypeScript is served by `ts_ls`, see LSP) |
| `markdown.lua` | render-markdown, markdown-plus |

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
| `<leader>f` | find (telescope: `ff` files, `fa` all files, `fw` grep, `fb` buffers, `fo` oldfiles, `fz` in-buffer, `fh` help, `fM` marks, `fc`/`fs` git commits/status, `ft` terms) + `fm` format (conform) | `mappings.lua` |
| `<leader>l` | LSP actions via lspsaga (`la` code action, `lp` peek, `lr`/`lR` rename, `le` line diagnostics, `li`/`lo` calls) | `configs/lsp.lua` `on_attach`, **buffer-local** |
| `<leader>r` | refactoring.nvim (`rr` select, `re` extract fn, `rf` extract to file, `rv` extract var, `ri`/`rI` inline var/fn) | `mappings.lua` |
| `<leader>d` | DAP + dap-view (`db`/`dB` breakpoints, `dl` run last, `do`/`dx`/`dt` view, `dw` watch, `dj`…`dr` jump to view) | `mappings.lua` |
| `<leader>t` / `<leader>T` | Trouble (`tx`/`tX` diagnostics, `ts` symbols, `tL`/`tQ` loclist/qflist) / neotest | `mappings.lua` |
| `<leader>g` | git (`gw`/`gf` lazygit, `gb`/`gl` blame, `gd` deleted, `gc` commit) | `mappings.lua` |
| `<leader>p` | projects (`pl`, `ph`, `pd*`) | `mappings.lua` |
| `<leader>s` | settings/toggles (`sn`, `sr`, `sw`, `sp` precognition, `sc` cheatsheet, `st` theme) | `mappings.lua` |
| `<leader>w` | which-key (`wk`, `wK`) | `mappings.lua` |
| `<leader>c` / `\` | project command picker (`configs/cmdpicker`) | `mappings.lua` |
| `<leader>e`, `<leader>n`, `<leader>x`, `<leader>h`, `<leader>v`, `<leader>/` | NvChad singles: tree focus, new buffer, close buffer, h/v terminal, comment | `mappings.lua` |

LSP navigation (buffer-local, `configs/lsp.lua`): `gd` definition, `gD` declaration, `gy` type definition, `gh` lspsaga finder (definition + references + implementation), `K` hover, `]d`/`[d` diagnostics — all lspsaga except `gD`. Do **not** map bare `gr`: Neovim 0.11+ ships native `grr/grn/gra/gri/grt/grx` and a `gr` map delays every one of them by `timeoutlen`.

Rules: no two maps on the same `lhs`+mode (the later one silently wins — `:checkhealth which-key` reports overlaps); LSP maps go in `configs/lsp.lua` `on_attach`, everything else in `mappings.lua`.

## Lua formatting — StyLua (`.stylua.toml`)

- `column_width = 120`
- `indent_type = "Spaces"`, `indent_width = 2`
- `quote_style = "AutoPreferDouble"`
- `call_parentheses = "None"` — omit parens on single-arg calls, e.g. `require "foo"` not `require("foo")`

Run formatter: `stylua <file>` (installed via Mason). Note `lua/mappings.lua` and `lua/configs/cmdpicker/` are deliberately kept in a compact one-line-per-mapping style that StyLua would expand; don't bulk-reformat them.

## LSP

Servers are listed in `lua/configs/lspconfig.lua` and enabled via `vim.lsp.enable(servers)`. To add a server: append its name to the `servers` table, then ensure it is installed via Mason (`lua/configs/mason.lua`). Per-server settings go in `lsp/<server>.lua`.

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

## Completion

**blink.cmp** is the active completion engine (`lua/configs/blink.lua`). Do not reference `nvim-cmp` or LuaSnip APIs in new code — neither is installed.

## DAP (debugging)

Adapters configured in `lua/configs/dap.lua`:
- **Go**: `dlv` (delve)
- **Rust**: `codelldb`

Debug keymaps: `<F5>` continue, `<F10>` step over, `<F11>` step into, `<F12>` step out, `<leader>db` toggle breakpoint, `<leader>dB` conditional breakpoint, `<leader>dl` run last. DAP View is under `<leader>d*` too (`configs/dapview.lua` opens/closes it via `dap.listeners` keyed `dap_view`).

## Treesitter

`nvim-treesitter` tracks the `main` branch. Its `setup()` only takes `install_dir`; `highlight`/`indent`/`ensure_installed` opts from the old API are ignored. `lua/configs/treesitter.lua` therefore installs parsers from `M.ensure_installed` itself and starts highlighting + `indentexpr` per buffer from a `FileType` autocmd. Add languages to `M.ensure_installed`; never re-add `highlight = { enable = true }`.

## Theme

Active theme: `material-deep-ocean` (set in `lua/chadrc.lua`). Custom theme `vs2022` is defined in `themes/vs2022.lua` as a base46 palette.

After any theme or highlight change, regenerate the base46 cache:
```
:lua require("base46").load_all_highlights()
```

## Mason

Mason auto-installs LSP servers, formatters, and debuggers on startup via `lua/configs/mason.lua`. It uses both the official registry and `Crashdummyy/mason-lspconfig-extensions` (for Roslyn). Do not manually install Mason-managed tools outside of that config file.
