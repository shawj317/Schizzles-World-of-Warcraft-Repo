-- Schizzle's Warrior: keybinds (v1) by Jon Shaw (Schizzle). MIT with attribution.
-- Applied by the SchizzlesWarriorSetup helper (/schizzle binds) and saved as account-wide
-- bindings, so every character gets them. Bar 1 (keys 1 to =) is not touched.
--
-- Bartender4 bar 3 uses Blizzard's MULTIACTIONBAR3BUTTON1-12 bindings (Bartender4's
-- BINDING_MAPPINGS), the same slots ElvUI's bar 3 used. Bar 2 has no Blizzard binding, so it
-- binds Bartender4's own buttons BT4Button13-24 with "CLICK BT4ButtonN:Keybind", which is what
-- Bartender4's keybind mode writes.
return {
	bar3 = {
		command = "MULTIACTIONBAR3BUTTON%d",
		keys = { "Q", "E", "R", "F", "T", "G", "Y", "BUTTON3", "BUTTON4", "CTRL-BUTTON3", "CTRL-BUTTON4", "ALT-BUTTON3" },
	},
	bar2 = {
		command = "CLICK BT4Button%d:Keybind",
		first = 13,
		keys = { "SHIFT-Q", "SHIFT-E", "SHIFT-R", "SHIFT-F", "SHIFT-T", "SHIFT-G", "SHIFT-Y", "SHIFT-BUTTON3", "SHIFT-BUTTON4", "CTRL-Q", "CTRL-E", "ALT-BUTTON4" },
	},
	movement = {
		{ key = "A", command = "STRAFELEFT" },
		{ key = "D", command = "STRAFERIGHT" },
	},
}
