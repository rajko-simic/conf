local map = vim.keymap.set

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
map({ "n", "x" }, "<leader>fm", function() require("conform").format { lsp_fallback = true } end, { desc = "general format file" })

-- global lsp mappings
map("n", "<leader>ds", vim.diagnostic.setloclist, { desc = "LSP diagnostic loclist" })

-- tabufline
map("n", "<leader>n", "<cmd>enew<CR>", { desc = "buffer new" })
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
map("n", "<leader>bb", function() require("dap").toggle_breakpoint() end, { desc = "Debug Toggle Breakpoint" })
map("n", "<leader>bc", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, { desc = "Debug Set Conditional Breakpoint" })
-- map("n", "<leader>dR", function() require("dap").repl.toggle() end, { desc = "Debug Toggle REPL" })
map("n", "<leader>dl", function() require("dap").run_last() end, { desc = "Debug Run Last Session" })

-- DAP View
map("n", "<leader>do", function() require("dap-view").open() end, { desc = "DapView Open" })
map("n", "<leader>dx", function() require("dap-view").close() end, { desc = "DapView Close" })
map("n", "<leader>dt", function() require("dap-view").toggle() end, { desc = "DapView Toggle" })
map("n", "<leader>dw", function() require("dap-view").add_expr() end, { desc = "DapView Watch Expr" })
map("v", "<leader>dw", function() require("dap-view").add_expr() end, { desc = "DapView Watch Selection" })
map("n", "<leader>dj", function() require("dap-view").jump_to_view "scopes" end, { desc = "DapView Jump Scopes" })
map("n", "<leader>de", function() require("dap-view").jump_to_view "exceptions" end, { desc = "DapView Jump Exceptions" })
map("n", "<leader>dv", function() require("dap-view").jump_to_view "watches" end, { desc = "DapView Jump Watches" })
map("n", "<leader>df", function() require("dap-view").jump_to_view "threads" end, { desc = "DapView Jump Threads" })
map("n", "<leader>dq", function() require("dap-view").jump_to_view "breakpoints" end, { desc = "DapView Jump Breakpoints" })
map("n", "<leader>dk", function() require("dap-view").jump_to_view "console" end, { desc = "DapView Jump Console" })
map("n", "<leader>dr", function() require("dap-view").jump_to_view "repl" end, { desc = "DapView Jump REPL" })
map("n", "<leader>dm", function() require("dap-view").navigate { count = 1, wrap = true } end, { desc = "DapView Next View" })
map("n", "<leader>dn", function() require("dap-view").navigate { count = -1, wrap = true } end, { desc = "DapView Prev View" })
map("n", "<leader>di", function() require("dap-view").virtual_text_toggle() end, { desc = "DapView Toggle Virtual Text" })

-- Project command picker (detects toolchain from project root, not buffer)
map("n", "\\", function() require("configs.cmdpicker").open() end, { desc = "Project command picker" })
map("n", "<leader>cd", function() require("configs.cmdpicker").open() end, { desc = "Project command picker" })

--Trouble
map("n", "<leader>tx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Trouble Diagnostics" })
map("n", "<leader>tX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Trouble Buffer Diagnostics" })
map("n", "<leader>ts", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Trouble Symbols" })
map("n", "<leader>tl", "<cmd>Trouble lsp_bottom toggle<cr>", { desc = "Trouble LSP Definitions / references / ..." })
map("n", "<leader>tL", "<cmd>Trouble loclist toggle<cr>", { desc = "Trouble Location List" })
map("n", "<leader>tQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Trouble Quickfix List" })

--Git
map("n", "<leader>gw", "<cmd>LazyGit<cr>", {desc = "Git LazyGit"})
map("n", "<leader>gf", "<cmd>LazyGitFilterCurrentFile<cr>", {desc = "Git Current File"})
map("n", "<leader>gb", "<cmd>Gitsigns blame<cr>", {desc = "Git Toggle Blame"})
map("n", "<leader>gl", "<cmd>Gitsigns blame_line<cr>", {desc = "Git Blame Line"})
map("n", "<leader>gd", "<cmd>Gitsigns toggle_deleted<cr>", {desc = "Git Toggle Deleted"})
map("n", "<leader>ga", "<cmd>Gitsigns attach<cr>", {desc = "Gitlens Attach"})
map("n", "<leader>gc", "<cmd>Gitsigns show_commit<cr>", {desc = "Git Show Commit"})

-- Neotest (language-agnostic)
map("n", "<leader>Tt", function() require("neotest").run.run() end,                                        { desc = "Neotest run nearest" })
map("n", "<leader>Tf", function() require("neotest").run.run(vim.fn.expand("%")) end,                      { desc = "Neotest run file" })
map("n", "<leader>Ta", function() require("neotest").run.run(vim.uv.cwd()) end,                            { desc = "Neotest run all" })
map("n", "<leader>Td", function() require("neotest").run.run({ strategy = "dap" }) end,                    { desc = "Neotest debug nearest" })
map("n", "<leader>Tl", function() require("neotest").run.run_last() end,                                   { desc = "Neotest run last" })
map("n", "<leader>TL", function() require("neotest").run.run_last({ strategy = "dap" }) end,               { desc = "Neotest debug last" })
map("n", "<leader>Ts", function() require("neotest").summary.toggle() end,                                 { desc = "Neotest summary toggle" })
map("n", "<leader>To", function() require("neotest").output.open({ enter = true, auto_close = true }) end, { desc = "Neotest output" })
map("n", "<leader>TO", function() require("neotest").output_panel.toggle() end,                            { desc = "Neotest output panel" })
map("n", "<leader>Tx", function() require("neotest").run.stop() end,                                       { desc = "Neotest stop" })

--Precognition
map("n", "<leader>pr", "<cmd>Precognition toggle<cr>", {desc = "Precognition toggle"})

--Basic Settings
map("n", "<leader>sn", "<cmd>set nu!<CR>", { desc = "general toggle line number" })
map("n", "<leader>sr", "<cmd>set rnu!<CR>", { desc = "general toggle relative number" })
map("n", "<leader>sw", "<cmd>set wrap!<CR>", { desc = "general toggle word wrap" })
map("n", "<leader>sc", "<cmd>NvCheatsheet<CR>", { desc = "general toggle nvcheatsheet" })
map("n", "<leader>st", function() require("nvchad.themes").open() end, { desc = "telescope nvchad themes" })

-------------------------------------- user mappings -----------------------------------



map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

--Saga
map("n", "<leader>la", "<cmd>Lspsaga code_action<cr>", { desc = "LSP saga code action" })
map("n", "<leader>lp", "<cmd>Lspsaga peek_definition<cr>", { desc = "LSP saga peek definition" })
map("n", "<leader>le", "<cmd>Lspsaga show_line_diagnostics<cr>", { desc = "LSP saga line diagnostics" })
map("n", "]d", "<cmd>Lspsaga diagnostic_jump_next<cr>", { desc = "LSP saga next diagnostic" })
map("n", "[d", "<cmd>Lspsaga diagnostic_jump_prev<cr>", { desc = "LSP saga prev diagnostic" })

local function write_unnamed(buf)
  vim.ui.input({ prompt = "Save as: ", completion = "file" }, function(input)
    if not input or input == "" then
      return
    end
    local path = vim.fn.fnamemodify(input, ":p")
    local dir = vim.fn.fnamemodify(path, ":h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
    vim.api.nvim_buf_set_name(buf, path)
    vim.bo[buf].buflisted = true
    vim.api.nvim_buf_call(buf, function()
      vim.cmd "noautocmd write"
      vim.cmd "filetype detect"
    end)
  end)
end

local function smart_save()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= "" then
    pcall(vim.cmd, "write")
    return
  end
  if vim.api.nvim_buf_get_name(buf) == "" then
    write_unnamed(buf)
  else
    vim.cmd "write"
  end
end

map({ "n", "v" }, "<C-s>", function()
  smart_save()
end, { desc = "Save (prompt if unnamed)" })

map("i", "<C-s>", function()
  vim.cmd "stopinsert"
  smart_save()
end, { desc = "Save (prompt if unnamed)" })

local group = vim.api.nvim_create_augroup("user_smart_save", { clear = true })
vim.api.nvim_create_autocmd({ "BufNew", "VimEnter" }, {
  group = group,
  callback = function(args)
    local buf = args.buf
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    if vim.bo[buf].buftype ~= "" then
      return
    end
    if vim.api.nvim_buf_get_name(buf) ~= "" then
      return
    end
    vim.api.nvim_create_autocmd("BufWriteCmd", {
      group = group,
      buffer = buf,
      callback = function()
        if vim.api.nvim_buf_get_name(buf) == "" then
          write_unnamed(buf)
        else
          vim.api.nvim_buf_call(buf, function()
            vim.cmd "noautocmd write"
          end)
        end
      end,
    })
  end,
})
