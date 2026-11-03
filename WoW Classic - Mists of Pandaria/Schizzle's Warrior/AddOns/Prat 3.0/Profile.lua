-- Schizzle's Warrior: Prat 3.0 profile (v1) by Jon Shaw (Schizzle). MIT with attribution.
-- Applied by the SchizzlesWarriorSetup helper (/schizzle chat) as an AceDB profile named
-- "Schizzle's Warrior" in Prat3DB. Module settings live in Prat's AceDB namespaces, which are
-- named after the AceAddon module ("Prat_<Module>"); keys are the ones in each module's
-- Prat:SetModuleDefaults call. Anything not listed keeps Prat's default.
local FONT = "Fira Sans Condensed Medium"

return {
	profile = {
		-- Module on/off states (Prat: 3 = enabled, 2 = disabled).
		modules = {
			Font = 3, ChannelNames = 3, Timestamps = 3, UrlCopy = 3, Editbox = 3,
			Buttons = 3, History = 3, CopyChat = 3, Fading = 3,
			ChatTabs = 2,
		},
	},
	namespaces = {
		Prat_Font = {
			on = true,
			fontface = FONT,
			outlinemode = "",
			shadowcolor = { r = 0, g = 0, b = 0, a = 1 },
		},
		-- Short channel names: Prat's own short forms ([G], [P], [R], [I], [W From], [1], [2] ...).
		Prat_ChannelNames = {
			on = true,
			space = true,
			colon = true,
		},
		-- 24-hour [HH:MM] timestamps in a muted bronze.
		Prat_Timestamps = {
			on = true,
			formatcode = "%H:%M",
			formatpre = "[",
			formatpost = "]",
			colortimestamp = true,
			timestampcolor = { r = 0.72, g = 0.45, b = 0.2, a = 1 },
			localtime = true,
		},
		-- Clickable links, shown in gold; click one to get a copy box.
		Prat_UrlCopy = {
			on = true,
			bracket = true,
			popup = true,
			colorurl = true,
			color = { r = 1, g = 0.82, b = 0, a = 1 },
		},
		-- Charcoal edit box with a bronze border, on top of the chat window.
		Prat_Editbox = {
			on = true,
			background = "Solid",
			border = "Blizzard Tooltip",
			backgroundColor = { r = 0.06, g = 0.06, b = 0.06, a = 0.9 },
			borderColor = { r = 0.72, g = 0.45, b = 0.2, a = 1 },
			inset = 3,
			edgeSize = 12,
			height = 22,
			attach = "TOP",
			colorByChannel = true,
			font = FONT,
		},
		-- Hide the scroll arrows and minimise button; keep the menu and channel buttons.
		Prat_Buttons = {
			on = true,
			showButtons = false,
			showminimize = false,
			showvoice = false,
			showMenu = true,
			showchannel = true,
			showBnet = true,
			scrollReminder = true,
		},
		Prat_History = {
			on = true,
			chatlines = 1000,
			scrollback = true,
		},
	},
}
