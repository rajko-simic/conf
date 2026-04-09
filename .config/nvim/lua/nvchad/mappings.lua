local map = vim.keymap.set
local dap = require("dap")

map("i", "<C-b>", "<ESC>^i", { desc = "move beginning of line" })
map("i", "<C-e>", "<End>", { desc = "move end of line" })
map("i", "<C-h>", "<Left>", { desc = "move left" })
map("i", "<C-l>", "<Right>", { desc = "move right" })
map("i", "<C-j>", "<Down>", { desc = "move down" })
map("i", "<C-k>", "<Up>", { desc = "move up" })

map("n", "<C-h>", "<C-w>h", { desc = "window switch left" })
map("n", "<C-l>", "<C-w>l", { desc = "window switch right" })
map("n", "<C-j>", "<C-w>j", { desc = "window switch down" })
map("n", "<C-k>", "<C-w>k", { desc = "window switch up" })

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })
map("n", "<C-s>", "<cmd>w<CR>", { desc = "general save file" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "general copy whole file" })
map("n", "<leader>n", "<cmd>set nu!<CR>", { desc = "general toggle line number" })
map("n", "<leader>rn", "<cmd>set rnu!<CR>", { desc = "general toggle relative number" })
map("n", "<leader>ch", "<cmd>NvCheatsheet<CR>", { desc = "general toggle nvcheatsheet" })
map({ "n", "x" }, "<leader>fm", function() require("conform").format { lsp_fallback = true } end, { desc = "general format file" })

-- global lsp mappings
map("n", "<leader>ds", vim.diagnostic.setloclist, { desc = "LSP diagnostic loclist" })

-- tabufline
map("n", "<leader>b", "<cmd>enew<CR>", { desc = "buffer new" })
map("n", "<tab>", function() require("nvchad.tabufline").next() end, { desc = "buffer goto next" })
map("n", "<S-tab>", function() require("nvchad.tabufline").prev() end, { desc = "buffer goto prev" })
map("n", "<leader>x", function() require("nvchad.tabufline").close_buffer() end, { desc = "buffer close" })
-- map("n", "<leader>tf", ":enew<CR>", { desc = "New empty buffer" })

-- Comment
map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })

-- nvimtree
map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
map("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "nvimtree focus window" })

-- telescope
map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "telescope live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "telescope find buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "telescope help page" })
map("n", "<leader>fm", "<cmd>Telescope marks<CR>", { desc = "telescope find marks" })
map("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>", { desc = "telescope find oldfiles" })
map("n", "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "telescope find in current buffer" })
map("n", "<leader>fc", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })
map("n", "<leader>fs", "<cmd>Telescope git_status<CR>", { desc = "telescope git status" })
map("n", "<leader>ft", "<cmd>Telescope terms<CR>", { desc = "telescope pick hidden term" })
map("n", "<leader>th", function() require("nvchad.themes").open() end, { desc = "telescope nvchad themes" })
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "telescope find files" })
map("n", "<leader>fa", "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>", { desc = "telescope find all files" })

-- telescope projects
map("n", "<leader>pl", "<cmd>NeovimProjectLoadRecent<CR>", { desc = "Projects Open Last" })
map("n", "<leader>ph", "<cmd>NeovimProjectHistory<CR>", { desc = "Projects Recent" })
map("n", "<leader>pda", "<cmd>NeovimProjectDiscover alphabetical_name<CR>", { desc = "Projects (Alphabet)" })
map("n", "<leader>pdh", "<cmd>NeovimProjectDiscover history<CR>", { desc = "Projects (History)" })
map("n", "<leader>pdp", "<cmd>NeovimProjectDiscover alphabetical_path<CR>", { desc = "Projects (Path)" })

-- terminal
map("t", "<C-x>", "<C-\\><C-N>", { desc = "terminal escape terminal mode" })
map("n", "<leader>h", function() require("nvchad.term").new { pos = "sp" } end, { desc = "terminal new horizontal term" })
map("n", "<leader>v", function() require("nvchad.term").new { pos = "vsp" } end, { desc = "terminal new vertical term" })
map({ "n", "t" }, "<A-v>", function() require("nvchad.term").toggle { pos = "vsp", id = "vtoggleTerm" } end, { desc = "terminal toggleable vertical term" })
map({ "n", "t" }, "<A-h>", function() require("nvchad.term").toggle { pos = "sp", id = "htoggleTerm" } end, { desc = "terminal toggleable horizontal term" })
map({ "n", "t" }, "<A-i>", function() require("nvchad.term").toggle { pos = "float", id = "floatTerm" } end, { desc = "terminal toggle floating term" })

-- whichkey
map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "whichkey all keymaps" })
map("n", "<leader>wk", function() vim.cmd("WhichKey " .. vim.fn.input "WhichKey: ") end, { desc = "whichkey query lookup" })

-- LSP references
map("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", { desc = "LSP references" })
map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { desc = "LSP Go to definition" })
map("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", { desc = "LSP Go to implementation" })
map("n", "gy", "<cmd>lua vim.lsp.buf.type_definition()<CR>", { desc = "LSP Go to type definition" })
-- map("n", "K",  "<cmd>lua vim.lsp.buf.hover()<CR>", { desc = "LSP Hover info" })

-- LSP hover (blink.cmp handles signature help in insert mode)
map('n', 'K', vim.lsp.buf.hover, { desc = "LSP Hover", noremap = true, silent = true })

-- DAP (Debug Adapter Protocol) keybindings
map("n", "<F5>", function() require("dap").continue() end, { desc = "Debug Start/Continue" })
map("n", "<F10>", function() require("dap").step_over() end, { desc = "Debug Step Over" })
map("n", "<F11>", function() require("dap").step_into() end, { desc = "Debug Step Into" })
map("n", "<F12>", function() require("dap").step_out() end, { desc = "Debug Step Out" })
map("n", "<leader>db", function() dap.toggle_breakpoint() end, { desc = "Debug Toggle Breakpoint" })
map("n", "<leader>dc", function() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, { desc = "Debug Set Conditional Breakpoint" })
map("n", "<leader>dr", function() dap.repl.toggle() end, { desc = "Debug Toggle REPL" })
map("n", "<leader>dl", function() dap.run_last() end, { desc = "Debug Run Last Session" })

-- DAP UI (Debug UI)
map("n", "<leader>du", function() require("dapui").toggle() end, { desc = "DAPUI Toggle" })
map("n", "<leader>de", function() require("dapui").eval() end, { desc = "DAPUI Evaluate expression" })
map("v", "<leader>de", function() require("dapui").eval() end, { desc = "DAPUI Evaluate selection" })
map("n", "<leader>ds", function() require("dapui").float_element("scopes") end, { desc = "DAPUI Show Scopes" })
map("n", "<leader>df", function() require("dapui").float_element("stacks") end, { desc = "DAPUI Show Stack Frames" })
map("n", "<leader>dv", function() require("dapui").float_element("breakpoints") end, { desc = "DAPUI Show Breakpoints" })
map("n", "<leader>dt", function() require("dapui").float_element("threads") end, { desc = "DAPUI Show Threads" })
map("n", "<leader>dc", function() require("dapui").float_element("console") end, { desc = "DAPUI Show Console" })

--Trouble
map("n", "<leader>tx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Trouble Diagnostics" })
map("n", "<leader>tX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Trouble Buffer Diagnostics" })
map("n", "<leader>ts", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Trouble Symbols" })
map("n", "<leader>tl", "<cmd>Trouble lsp_bottom toggle<cr>", { desc = "Trouble LSP Definitions / references / ..." })
map("n", "<leader>tL", "<cmd>Trouble loclist toggle<cr>", { desc = "Trouble Location List" })
map("n", "<leader>tQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Trouble Quickfix List" })

--Outline
map("n", "<leader>oo", "<cmd>Outline!<cr>", {desc = "Outline Open"})
map("n", "<leader>of", "<cmd>OutlineOpen<cr>", {desc = "Outline Focus"})
map("n", "<leader>os", "<cmd>OutlineStatus<cr>", {desc = "Outline Status"})

--Lazygit
map("n", "<leader>gw", "<cmd>LazyGit<cr>", {desc = "Lazygit"})
map("n", "<leader>gc", "<cmd>LazyGitFilterCurrentFile<cr>", {desc = "Lazygit Current File"})

--Precognition
map("n", "<leader>pr", "<cmd>Precognition toggle<cr>", {desc = "Precognition toggle"})

--Opencode
map({ "n", "x" }, "<leader>qa", function() require("opencode").ask("@this: ", { submit = true }) end, { desc = "Ask opencode" })
map({ "n", "x" }, "<leader>qx", function() require("opencode").select() end, { desc = "Execute opencode action" })
map({ "n", "t" }, "<leader>qt", function() require("opencode").toggle() end, { desc = "Toggle opencode" })
map({ "n", "x" }, "qr",  function() return require("opencode").operator("@this ") end, { desc = "Add range to opencode", expr = true })
map("n",          "ql", function() return require("opencode").operator("@this ") .. "_" end, { desc = "Add line to opencode", expr = true })
map("n", "<leader>qu", function() require("opencode").command("session.half.page.up") end, { desc = "Scroll opencode up" })
map("n", "<leader>qd", function() require("opencode").command("session.half.page.down") end, { desc = "Scroll opencode down" })



