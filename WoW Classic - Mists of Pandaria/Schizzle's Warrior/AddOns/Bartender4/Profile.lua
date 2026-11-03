-- Schizzle's Warrior: Bartender4 profile (v2) by Jon Shaw (Schizzle). MIT with attribution.
-- Applied by the SchizzlesWarriorSetup helper (/schizzle bars) into a profile named
-- "Schizzle's Warrior". The helper first resets that profile to Bartender4's own defaults (no
-- preset), then writes these values on top, so the result is exactly Jon's in-game setup.
--
-- The values are Jon's Bartender4 saved variables for this profile, as Bartender4 stores them:
-- only the settings that differ from its defaults. One change on top: bars 4 and 5 fade out
-- until moused over (fadeout, fadeoutalpha 0), like the micro menu.
--
-- Positions are Bartender4's LibWindow storage: a point on UIParent and the offset of the bar's
-- top-left corner from it, in the bar's own scale. version = 3 is Bartender4's config version;
-- it stops Bartender4 from re-running its old position migration on these bars.
-- A module with no "enabled" key keeps Bartender4's default: the status tracking (XP and
-- reputation) bar and the Blizzard art default to off; the micro menu, stance bar, extra action
-- button and vehicle bar default to on. The bag bar and pet bar are switched off here.
return {
	namespaces = {
		ActionBars = {
			actionbars = {
				[1] = {
					elements = {
						count = {
							font = "Fira Sans Condensed Medium",
							fontSize = 12,
						},
						hotkey = {
							font = "Fira Sans Condensed Medium",
							fontColor = { 0.78, 0.61, 0.43 },
							fontSize = 10,
						},
						macro = {
							font = "Fira Sans Condensed Medium",
						},
					},
					hidemacrotext = true,
					padding = 3,
					position = {
						point = "BOTTOM",
						scale = 0.8999999761581421,
						x = -212.3997505891784,
						y = 40,
					},
					showgrid = true,
					version = 3,
				},
				[2] = {
					elements = {
						count = {
							font = "Fira Sans Condensed Medium",
							fontSize = 13,
						},
						hotkey = {
							font = "Fira Sans Condensed Medium",
							fontColor = { 0.78, 0.61, 0.43 },
							fontSize = 10,
						},
						macro = {
							font = "Fira Sans Condensed Medium",
						},
					},
					hidemacrotext = true,
					padding = 3,
					position = {
						point = "BOTTOM",
						scale = 0.8999999761581421,
						x = -212.3997505891784,
						y = 81.7732362065517,
					},
					showgrid = true,
					version = 3,
					visibility = {
						nocombat = true,
					},
				},
				[3] = {
					elements = {
						count = {
							font = "Fira Sans Condensed Medium",
							fontSize = 13,
						},
						hotkey = {
							font = "Fira Sans Condensed Medium",
							fontColor = { 0.78, 0.61, 0.43 },
							fontSize = 10,
						},
						macro = {
							font = "Fira Sans Condensed Medium",
						},
					},
					hidemacrotext = true,
					padding = 3,
					position = {
						point = "BOTTOM",
						scale = 0.8999999761581421,
						x = -212.3999703157351,
						y = 116.7253249717996,
					},
					showgrid = true,
					version = 3,
					visibility = {
						nocombat = true,
					},
				},
				[4] = {
					-- Mouseover: faded out until the cursor is over the bar (the one change from Jon's file).
					fadeout = true,
					fadeoutalpha = 0,
					buttons = 8,
					elements = {
						count = {
							font = "Fira Sans Condensed Medium",
							fontSize = 13,
						},
						hotkey = {
							font = "Fira Sans Condensed Medium",
							fontColor = { 0.78, 0.61, 0.43 },
							fontSize = 12,
						},
						macro = {
							font = "Fira Sans Condensed Medium",
						},
					},
					hidemacrotext = true,
					padding = 3,
					position = {
						point = "BOTTOM",
						scale = 0.8999999761581421,
						x = -71.9998916376062,
						y = 189.6378337214301,
					},
					rows = 2,
					showgrid = true,
					version = 3,
				},
				[5] = {
					-- Mouseover: faded out until the cursor is over the bar (the one change from Jon's file).
					fadeout = true,
					fadeoutalpha = 0,
					elements = {
						count = {
							font = "Fira Sans Condensed Medium",
							fontSize = 13,
						},
						hotkey = {
							font = "Fira Sans Condensed Medium",
							fontColor = { 0.78, 0.61, 0.43 },
							fontSize = 12,
						},
						macro = {
							font = "Fira Sans Condensed Medium",
						},
					},
					hidemacrotext = true,
					padding = 3,
					position = {
						point = "RIGHT",
						scale = 0.8999999761581421,
						x = -73,
						y = 107.1000883242996,
					},
					rows = 6,
					showgrid = true,
					version = 3,
				},
				[6] = {
					elements = {
						count = {
							font = "Fira Sans Condensed Medium",
							fontSize = 13,
						},
						hotkey = {
							font = "Fira Sans Condensed Medium",
							fontColor = { 0.78, 0.61, 0.43 },
							fontSize = 12,
						},
						macro = {
							font = "Fira Sans Condensed Medium",
						},
					},
					hidemacrotext = true,
					padding = 3,
					position = {
						point = "CENTER",
						scale = 0.8999999761581421,
						x = 476.8875938218407,
						y = 36.89995285486657,
					},
					rows = 2,
					version = 3,
				},
			},
		},
		BagBar = {
			enabled = false,
			keyring = false,
			position = {
				point = "BOTTOM",
				x = 346,
				y = 38,
			},
			scale = 0.9,
			version = 3,
		},
		BlizzardArt = {
			position = {
				point = "BOTTOM",
				x = -512,
				y = 47,
			},
			version = 3,
		},
		ExtraActionBar = {
			hideArtwork = true,
			position = {
				point = "BOTTOM",
				scale = 0.9,
				x = 236,
				y = 176,
			},
			version = 3,
		},
		MicroMenu = {
			fadeout = true,
			fadeoutalpha = 0,
			padding = -4,
			position = {
				point = "BOTTOMRIGHT",
				x = -300,
				y = 30,
			},
			version = 3,
		},
		PetBar = {
			enabled = false,
			position = {
				point = "BOTTOM",
				x = -120,
				y = 143,
			},
			version = 3,
		},
		StanceBar = {
			padding = 3,
			position = {
				point = "BOTTOM",
				scale = 0.8999999761581421,
				x = -180,
				y = 171,
			},
			version = 3,
		},
		StatusTrackingBar = {
			position = {
				point = "BOTTOM",
				x = -519,
				y = 72,
			},
			version = 3,
		},
		Vehicle = {
			position = {
				point = "CENTER",
				x = 104.5,
				y = 42.50006103515625,
			},
			version = 3,
		},
	},
	profile = {
		blizzardVehicle = true,
	},
}
