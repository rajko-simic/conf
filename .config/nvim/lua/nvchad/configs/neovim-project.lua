

return  {
  projects = { -- define project roots
    "~/.config/*",
    "~/Documents/Projects/*",
    "~/Documents/Projects/*/*",
    "~/Documents/Work/*/*",
    "/shared/Private/Rajko/Practice/*",
    "/shared/Private/Rajko/Practice/*/*"
  },
  last_session_on_startup = false,
  dashboard_mode = true,
  picker = {
    type = "telescope",

    preview = {
      enabled = true, -- show directory structure in Telescope preview
      git_status = true, -- show branch name, an ahead/behind counter, and the git status of each file/folder
      git_fetch = false, -- fetch from remote, used to display the number of commits ahead/behind, requires git authorization
      show_hidden = true, -- show hidden files/folders
    },
  }
}
