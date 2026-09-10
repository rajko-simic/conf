-- ~/.config/yazi/init.lua
require("bookmarks"):setup({
	last_directory = { enable = false, persist = true, mode="dir" },
	persist = "all",
	desc_format = "full",
	file_pick_mode = "hover",
	custom_desc_input = false,
	show_keys = true,
	notify = {
		enable = true,
		timeout = 1,
		message = {
			new = "New bookmark '<key>' -> '<folder>'",
			delete = "Deleted bookmark in '<key>'",
			delete_all = "Deleted all bookmarks",
		},
	},
})

require("git"):setup()

-- Tell the terminal our cwd (OSC 7) so a new Konsole tab/window opened from
-- this one starts where Yazi is. Empty host on purpose: Konsole only accepts
-- file:// URLs whose host is empty or equal to the machine hostname, so the
-- official term-cwd.yazi plugin's "file://localhost" would be rejected.
local function osc7_encode(path)
	return (path:gsub("[^A-Za-z0-9%-%._~/]", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

ps.sub("cd", function()
	local cwd = tostring(cx.active.current.cwd)
	if cwd:sub(1, 1) == "/" then -- skip virtual urls (search://, archives, ...)
		io.write("\x1b]7;file://" .. osc7_encode(cwd) .. "\x1b\\")
		io.flush()
	end
end)
