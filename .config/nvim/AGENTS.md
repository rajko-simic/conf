# AGENTS.md

## Repo identity

This is a personal Neovim config built on **NvChad v2.5**. NvChad itself is consumed as a lazy.nvim plugin (`NvChad/NvChad`, branch `v2.5`), not a local module. Do not edit files under `lua/nvchad/` expecting them to be the canonical source — they are part of the NvChad plugin loaded at runtime.

## Directory layout

| Path | Purpose |
|---|---|
| `init.lua` | Entry point: lazy bootstrap, plugin setup, theme load, core module requires |
| `lua/chadrc.lua` | NvChad UI config (theme, dashboard, tabufline, terminal) |
| `lua/options.lua` | User options (thin wrapper over `nvchad.options`) |
| `lua/mappings.lua` | User keymaps (extends `nvchad.mappings`) |
| `lua/plugins/init.lua` | **User plugin specs** — add new plugins here |
| `lua/configs/lspconfig.lua` | LSP server list passed to `vim.lsp.enable()` |
| `lua/configs/conform.lua` | Formatter config (only `stylua` for Lua is active) |
| `lua/configs/lazy.lua` | lazy.nvim options (all plugins lazy by default) |
| `lua/nvchad/plugins/init.lua` | Full plugin registry (NvChad-side); edit to configure existing plugins |
| `lua/nvchad/configs/` | Per-plugin config files (dap, lspconfig, treesitter, mason, etc.) |
| `themes/vs2022.lua` | Custom base46 theme (base_30 + base_16 palette) |

## Lua formatting — StyLua (`.stylua.toml`)

All Lua must match:
- `column_width = 120`
- `indent_type = "Spaces"`, `indent_width = 2`
- `quote_style = "AutoPreferDouble"`
- `call_parentheses = "None"` — omit parens on single-arg calls, e.g. `require "foo"` not `require("foo")`

Run formatter: `stylua <file>` (installed via Mason).

## Adding plugins

1. Add spec to `lua/plugins/init.lua` (user layer).
2. Put the config function/file in `lua/nvchad/configs/<plugin>.lua` or inline in the spec.
3. All plugins are `lazy = true` by default — set an appropriate trigger (`event`, `ft`, `cmd`, `keys`).

## LSP

Servers are listed in `lua/configs/lspconfig.lua` and enabled via `vim.lsp.enable(servers)`. To add a server: append its name to the `servers` table, then ensure it is installed via Mason (`lua/nvchad/configs/mason.lua`).

Inlay hints are enabled globally in `init.lua` (`vim.lsp.inlay_hint.enable(true)`).

C# uses `easy-dotnet.nvim` with Roslyn LSP + roslynator — configured in `lua/nvchad/configs/easydotnet.lua`. Do not add `omnisharp` or `csharp_ls` to the servers list.

## Completion

**blink.cmp** is the active completion engine (`lua/nvchad/configs/blink.lua`). A legacy `cmp.lua` config exists but is not wired up — do not reference `nvim-cmp` APIs in new code.

## DAP (debugging)

Adapters configured in `lua/nvchad/configs/dap.lua`:
- **Go**: `dlv` (delve)
- **Rust**: `codelldb`

Debug keymaps: `<F5>` continue, `<F10>` step over, `<F11>` step into, `<F12>` step out, `<leader>db` toggle breakpoint.

## Theme

Active theme: `material-deep-ocean` (set in `lua/chadrc.lua`). Custom theme `vs2022` is defined in `themes/vs2022.lua` as a base46 palette.

After any theme or highlight change, regenerate the base46 cache:
```
:lua require("base46").load_all_highlights()
```

## Mason

Mason auto-installs LSP servers, formatters, and debuggers on startup via `lua/nvchad/configs/mason.lua`. It uses both the official registry and `Crashdummyy/mason-lspconfig-extensions` (for Roslyn). Do not manually install Mason-managed tools outside of that config file.
