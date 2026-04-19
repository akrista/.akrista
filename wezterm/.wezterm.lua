local bgimghue = math.random()
local wezterm = require("wezterm")
local config = wezterm.config_builder()
if string.match(wezterm.target_triple, "windows") then
	config.default_prog = { "pwsh", "--NoLogo" }
else
	config.default_prog = { "zsh" }
end
config.front_end = "OpenGL"
config.max_fps = 144
config.default_cursor_style = "BlinkingBlock"
config.animation_fps = 1
config.cursor_blink_rate = 500
config.term = "xterm-256color"
config.font = wezterm.font("MesloLGS NF")
config.font_size = 16.0
config.color_scheme = "MonokaiProRistretto (Gogh)"
config.background = {
	{
		source = {
			Color = "Black",
		},
		attachment = "Fixed",
		repeat_x = "Mirror",
		repeat_x_size = "100%",
		repeat_y = "Mirror",
		repeat_y_size = "100%",
		vertical_align = "Middle",
		vertical_offset = 0,
		horizontal_align = "Center",
		horizontal_offset = 0,
		opacity = 0.80,
		hsb = {
			brightness = 1,
			hue = 1,
			saturation = 1,
		},
		height = "100%",
		width = "100%",
	},
	{
		source = {
			File = ".akrista/assets/introPsyWorry.png",
		},
		attachment = "Fixed",
		opacity = 0.50,
		hsb = {
			brightness = 1,
			hue = bgimghue,
			saturation = 1,
		},
	},
	{
		source = {
			File = ".akrista/assets/introPsyWorry2.png",
		},
		attachment = "Fixed",
		opacity = 0.50,
		hsb = {
			brightness = 1,
			hue = bgimghue,
			saturation = 1,
		},
	},
}
config.prefer_egl = true
config.window_padding = {
	bottom = 0,
	top = 0,
	left = 0,
	right = 0,
}
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "NONE | RESIZE"
config.use_fancy_tab_bar = false
config.enable_tab_bar = true
config.initial_cols = 80
config.keys = {
	{
		key = "h",
		mods = "CTRL|SHIFT|ALT",
		action = wezterm.action.SplitPane({
			direction = "Right",
			size = { Percent = 50 },
		}),
	},
	{
		key = "v",
		mods = "CTRL|SHIFT|ALT",
		action = wezterm.action.SplitPane({
			direction = "Down",
			size = { Percent = 50 },
		}),
	},
	{
		key = "U",
		mods = "CTRL|SHIFT",
		action = wezterm.action.AdjustPaneSize({ "Left", 5 }),
	},
	{
		key = "I",
		mods = "CTRL|SHIFT",
		action = wezterm.action.AdjustPaneSize({ "Down", 5 }),
	},
	{
		key = "O",
		mods = "CTRL|SHIFT",
		action = wezterm.action.AdjustPaneSize({ "Up", 5 }),
	},
	{
		key = "P",
		mods = "CTRL|SHIFT",
		action = wezterm.action.AdjustPaneSize({ "Right", 5 }),
	},
	{ key = "9", mods = "CTRL", action = wezterm.action.PaneSelect },
	{ key = "L", mods = "CTRL", action = wezterm.action.ShowDebugOverlay },
	{
		key = "O",
		mods = "CTRL|ALT",
		action = wezterm.action_callback(function(window, _)
			local overrides = window:get_config_overrides() or {}
			if overrides.window_background_opacity == 1.0 then
				overrides.window_background_opacity = 0.9
			else
				overrides.window_background_opacity = 1.0
			end
			window:set_config_overrides(overrides)
		end),
	},
}
return config
