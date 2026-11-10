local _, ns = ...

-- Pure settings catalog and visibility rules. The Blizzard panel is built from this.

ns.MAIN_FRAME = "WayfarerFrame"
ns.SETTINGS = {
	{
		section = "General",
		items = {
			{ key = "rememberWindow", kind = "check", label = "Remember window", tip = "Save the route window's size and position. Off, it opens at the default spot each login." },
			{ key = "showOnLogin", kind = "check", label = "Show on login", tip = "Open the route window when you log in. A battleground or instance hide still wins." },
			{ key = "hideInBattleground", kind = "check", label = "Hide in battlegrounds", tip = "Hide the window in battlegrounds and arenas. It comes back when you leave, if it was open." },
			{ key = "hideInInstance", kind = "check", label = "Hide in instances", tip = "Hide the window in dungeons and raids. It comes back when you leave, if it was open." },
			{ key = "recalc", kind = "button", label = "Recalculate", tip = "Plan again from where you are standing, and point the arrow at step 1." },
		},
	},
	{
		section = "Map",
		items = {
			{ key = "includeLowLevel", kind = "check", label = "Low-level quests", tip = "Gray quests. Off, they are listed under Avoid and left out of the route." },
			{ key = "omitDungeons", kind = "check", label = "Skip dungeons", tip = "Leave dungeon quests out of the route. They are listed under Avoid." },
			{ key = "showOnMap", kind = "check", label = "Numbered pins", tip = "Numbered round pins on the world map and the minimap." },
			{ key = "useTomTom", kind = "check", needs = "TomTom", label = "TomTom arrow", tip = "A TomTom waypoint for every step that has a pin. The arrow follows step 1 when the route changes." },
			{ key = "useFlights", kind = "check", label = "Flight paths", tip = "Compare a long leg with flight masters you know, and with boats and zeppelins." },
			{ key = "showTrail", kind = "check", label = "Ant trail", tip = "Dots along the route. The world map trail pauses while the map is closed. Minimap dots stay inside the minimap." },
			{ key = "trailAnimated", kind = "check", label = "Animate trail", tip = "March the dots toward the next step." },
			{ key = "scope", kind = "menu", label = "Route scope", tip = "This zone, or every non-dungeon quest in the log.", choices = { { "zone", "This zone" }, { "all", "All quests" } } },
			{ key = "maxLevelsAbove", kind = "slider", label = "Levels above", tip = "Quests higher than you by more than this wait.", min = 0, max = 10, step = 1 },
			{ key = "stepsShown", kind = "slider", label = "Steps listed", tip = "How many steps the window lists. The rest stay in the plan.", min = 1, max = 20, step = 1 },
			{ key = "pinSize", kind = "slider", label = "Pin size", tip = "Diameter of the round pins, in pixels.", min = 14, max = 32, step = 1 },
			{ key = "trailAlpha", kind = "slider", label = "Trail opacity", tip = "How solid the trail dots are.", min = 0.15, max = 1, step = 0.05 },
		},
	},
	{
		section = "Appearance",
		items = {
			{ key = "theme", kind = "menu", label = "Theme", tip = "Wayfarer, Classic dialog, or your class color.", choices = { { "wayfarer", "Wayfarer" }, { "blizzard", "Classic" }, { "class", "Class" } } },
			{ key = "backdropAlpha", kind = "slider", label = "Background", tip = "Opacity of the window background only. Text stays solid.", min = 0, max = 1, step = 0.05 },
			{ key = "showBorder", kind = "check", label = "Show border", tip = "Off removes the edge on every theme. The header, cog, and close button stay flush." },
			{ key = "windowScale", kind = "slider", label = "Window scale", tip = "Scale of the route window.", min = 0.8, max = 1.4, step = 0.05 },
			{ key = "font", kind = "menu", label = "Font", tip = "Typeface for the route window.", choices = { { "1", "Game font" }, { "2", "Friz Quadrata" }, { "3", "Arial Narrow" }, { "4", "Morpheus" }, { "5", "Skurri" }, { "6", "PT Sans Narrow" } } },
			{ key = "fontSize", kind = "slider", label = "Text size", tip = "Size of the route text.", min = 9, max = 22, step = 1 },
		},
	},
}

function ns.TomTomLoaded()
	return TomTom ~= nil
end

function ns.HideKind(instanceType, db)
	db = db or {}
	if db.hideInBattleground and (instanceType == "pvp" or instanceType == "arena") then
		return "battleground"
	end
	if db.hideInInstance and (instanceType == "party" or instanceType == "raid") then
		return "instance"
	end
	return nil
end

function ns.ForgetWindow(db)
	if type(db) ~= "table" then
		return
	end
	db.point = nil
	db.width = nil
	db.height = nil
	db.userSized = nil
end

function ns.ListedForEscape(frames)
	for i = 1, #(frames or {}) do
		local name = frames[i]
		if name == ns.MAIN_FRAME or name == "WayfarerConfigFrame" then
			return true
		end
	end
	return false
end

function ns.ClampRadius(x, y, radius)
	x = tonumber(x) or 0
	y = tonumber(y) or 0
	radius = tonumber(radius) or 0
	if radius < 0 then
		radius = 0
	end
	local dist = math.sqrt(x * x + y * y)
	if dist == 0 or dist <= radius then
		return x, y, true
	end
	if radius == 0 then
		return 0, 0, false
	end
	return x / dist * radius, y / dist * radius, false
end
