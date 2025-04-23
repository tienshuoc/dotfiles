-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
config.color_scheme = "Dark+"

-- wezterm.font("JetBrainsMono Nerd Font Propo", { weight = "Regular", stretch = "Normal", style = "Normal" })
config.font = wezterm.font("Maple Mono NF CN", { weight = "Regular", stretch = "Normal", style = "Normal" })

config.font_size = 12.0
config.window_background_opacity = 0.75
config.hide_tab_bar_if_only_one_tab = true
config.keys = {
	{
		key = "n",
		mods = "SHIFT|CTRL",
		action = wezterm.action.ToggleFullScreen,
	},
}

-- This setting controls the maximum frame rate used when rendering easing effects for blinking cursors, blinking text and visual bell.
config.animation_fps = 60
-- Limits the maximum number of frames per second that wezterm will attempt to draw.
config.max_fps = 60

-- and finally, return the configuration to wezterm
return config
