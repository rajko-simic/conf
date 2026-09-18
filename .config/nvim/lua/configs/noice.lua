return {
  cmdline = {
    enabled = true,
    view = "cmdline_popup",
    opts = {},
    format = {
      cmdline     = { icon = ">" },
      search_down = { icon = "🔍⌄" },
      search_up   = { icon = "🔍⌃" },
      filter      = { icon = "$" },
      lua         = { icon = "☾" },
      help        = { icon = "?" },
    },
  },
  views = {
    cmdline_popup = {
      position = {
        row = "50%",
        col = "50%",
      },
      size = {
        width = 60,
        height = "auto",
      },
      border = {
        style = "rounded",
      },
      win_options = {
        winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
      },
    },
    mini = {
      timeout = 3000,
      format = { "{level_text}" },
    },
  },
  notify = { enabled = true, view = "mini" },
  messages = { enabled = true },
  lsp = {
    -- lspsaga owns hover, blink.cmp owns signature help, NvChad statusline lsp_msg owns progress
    hover = { enabled = false },
    signature = { enabled = false },
    progress = { enabled = false },
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
      ["cmp.entry.get_documentation"] = true,
    },
  },
  presets = {
    bottom_search = false,
    command_palette = false,
    long_message_to_split = true,
  },
  routes = {
    {
      filter = { event = "msg_show", kind = { "emsg", "wmsg" } },
      view = "mini",
    },
  },
}
