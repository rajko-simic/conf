# AGENTS.md

## Repo identity

This is a personal Neovim config built on the **NvChad v2.5 runtime**, but it is *not* a stock NvChad install. There is no `NvChad/NvChad` dependency and no `lua/nvchad/` directory — the config owns all of its own options, mappings, autocmds, plugin specs, and per-plugin configs.

What is still consumed from NvChad upstream, as ordinary lazy.nvim plugins:

| Plugin | Provides |
|---|---|
| `nvchad/ui` | The `nvchad.*` lua namespace (`nvchad` init, `nvchad.stl`, `nvchad.tabufline`, `nvchad.term`, `nvchad.themes`, `nvchad.lsp`, `nvchad.icons`, `nvchad.nvdash`, `nvchad.cheatsheet`), plus `nvconfig` and `colors/nvchad.lua` |
| `nvchad/base46` | Theme/highlight compiler (`vim.g.base46_cache`) |
| `nvzone/volt`, `nvzone/menu`, `nvzone/minty` | UI primitives, right-click menu, colour pickers |

**Important:** `require "nvchad.…"` in this config always refers to the `nvchad/ui` plugin. Do not rename or "localise" those requires — they are not config-local modules.

## Directory layout

| Path | Purpose |
|---|---|
| `init.lua` | Entry point: lazy bootstrap, `{ import = "plugins" }`, theme load, core module requires |
| `lua/chadrc.lua` | NvChad UI config (theme, dashboard, tabufline, terminal) — mirrors `nvconfig.lua` from `nvchad/ui` |
| `lua/options.lua` | All `vim.opt`/`vim.o` settings |
| `lua/mappings.lua` | All keymaps |
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
| `core.lua` | plenary, base46, nvchad/ui, volt, menu, minty, devicons, mini.icons |
| `ui.lua` | noice, nvim-notify, which-key, indent-blankline, nvim-tree, precognition |
| `lsp.lua` | nvim-lspconfig, mason, blink.cmp, lspsaga, symbol-usage, trouble, schemastore |
| `editor.lua` | telescope, treesitter (+context), conform, refactoring, neovim-project |
| `git.lua` | gitsigns, lazygit |
| `debug.lua` | nvim-dap, nvim-dap-view, nvim-dap-virtual-text, nvim-nio |
| `test.lua` | neotest (+ neotest-vstest) |
| `lang.lua` | easy-dotnet, typescript-tools, flutter-tools, pubspec-assist |
| `markdown.lua` | render-markdown, markdown-plus |

### Adding plugins

1. Add the spec to the matching `lua/plugins/<domain>.lua`. **Declare each plugin exactly once** — a plugin split across two files silently merges and the later spec's fields win, which is how this config previously ended up with duplicate `conform`/`lspsaga`/`lspconfig` entries.
2. Put non-trivial config in `lua/configs/<plugin>.lua` and reference it as `opts = require "configs.<plugin>"` or `config = function() require "configs.<plugin>" end`.
3. All plugins are `lazy = true` by default — set an appropriate trigger (`event`, `ft`, `cmd`, `keys`). `event = "User FilePost"` is the config's "a real file is open" event, fired from `lua/autocmds.lua`.
4. Keep `require` calls inside the keymap/config callback rather than at the top of `lua/mappings.lua` — a top-level `require` forces the plugin to load at startup and defeats its lazy trigger.

## Lua formatting — StyLua (`.stylua.toml`)

- `column_width = 120`
- `indent_type = "Spaces"`, `indent_width = 2`
- `quote_style = "AutoPreferDouble"`
- `call_parentheses = "None"` — omit parens on single-arg calls, e.g. `require "foo"` not `require("foo")`

Run formatter: `stylua <file>` (installed via Mason). Note `lua/mappings.lua` and `lua/configs/cmdpicker/` are deliberately kept in a compact one-line-per-mapping style that StyLua would expand; don't bulk-reformat them.

## LSP

Servers are listed in `lua/configs/lspconfig.lua` and enabled via `vim.lsp.enable(servers)`. To add a server: append its name to the `servers` table, then ensure it is installed via Mason (`lua/configs/mason.lua`). Per-server settings go in `lsp/<server>.lua`.

Shared behaviour (on-attach keymaps, blink capabilities, diagnostic config, semantic-token suppression) lives in `lua/configs/lsp.lua`. Inlay hints are enabled globally in `init.lua` and per-buffer on `LspAttach`.

C# uses `easy-dotnet.nvim` with Roslyn LSP + roslynator — configured in `lua/configs/easydotnet.lua`. Do not add `omnisharp` or `csharp_ls` to the servers list.

## Completion

**blink.cmp** is the active completion engine (`lua/configs/blink.lua`). Do not reference `nvim-cmp` or LuaSnip APIs in new code — neither is installed.

## DAP (debugging)

Adapters configured in `lua/configs/dap.lua`:
- **Go**: `dlv` (delve)
- **Rust**: `codelldb`

Debug keymaps: `<F5>` continue, `<F10>` step over, `<F11>` step into, `<F12>` step out, `<leader>bb` toggle breakpoint, `<leader>bc` conditional breakpoint. DAP View is under `<leader>d*`.

## Theme

Active theme: `material-deep-ocean` (set in `lua/chadrc.lua`). Custom theme `vs2022` is defined in `themes/vs2022.lua` as a base46 palette.

After any theme or highlight change, regenerate the base46 cache:
```
:lua require("base46").load_all_highlights()
```

## Mason

Mason auto-installs LSP servers, formatters, and debuggers on startup via `lua/configs/mason.lua`. It uses both the official registry and `Crashdummyy/mason-lspconfig-extensions` (for Roslyn). Do not manually install Mason-managed tools outside of that config file.
