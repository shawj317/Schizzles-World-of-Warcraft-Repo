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
			{ key = "autoRecalc", kind = "check", label = "Auto recalculate", tip = "Rebuild the route on a timer. It waits out combat, skips when the window is hidden and TomTom is not loaded, and skips when the log, zone, and position have not changed." },
			{ key = "autoInterval", kind = "slider", label = "Recalc seconds", tip = "How often the automatic rebuild runs, from 15 to 120 seconds.", min = 15, max = 120, step = 5 },
			{ key = "recalc", kind = "button", label = "Recalculate", tip = "Plan again from where you are standing, and point the arrow at step 1." },
		},
	},
	{
		section = "Map",
		items = {
			{ key = "includeLowLevel", kind = "check", label = "Low-level quests", tip = "Gray quests. Off, they are listed under Avoid and left out of the route." },
			{ key = "omitDungeons", kind = "check", label = "Skip dungeons", tip = "Leave dungeon quests out of the route. They are listed under Avoid." },
			{ key = "omitPvp", kind = "check", label = "Omit PvP quests", tip = "Leave battleground quests out of the route in this zone and in all quests. They are listed under Avoid as PvP." },
			{ key = "showOnMap", kind = "check", label = "Numbered pins", tip = "Numbered round pins on the world map. The minimap uses the TomTom arrow for the current step." },
			{ key = "useTomTom", kind = "check", needs = "TomTom", label = "Every step", tip = "Off: one TomTom arrow for the current step. On: a waypoint for every step. Wayfarer removes its own previous waypoints first, and leaves yours alone." },
			{ key = "useFlights", kind = "check", label = "Flight paths", tip = "Compare a long leg with flight masters you know, and with boats and zeppelins." },
			{ key = "scope", kind = "menu", label = "Route scope", tip = "This zone, or every non-dungeon quest in the log.", choices = { { "zone", "This zone" }, { "all", "All quests" } } },
			{ key = "maxLevelsAbove", kind = "slider", label = "Levels above", tip = "Quests higher than you by more than this wait.", min = 0, max = 10, step = 1 },
			{ key = "stepsShown", kind = "slider", label = "Steps listed", tip = "How many steps the window lists. The rest stay in the plan.", min = 1, max = 20, step = 1 },
			{ key = "pinSize", kind = "slider", label = "Pin size", tip = "Diameter of the round pins, in pixels.", min = 14, max = 32, step = 1 },
		},
	},
	{
		section = "Appearance",
		items = {
			{ key = "theme", kind = "menu", label = "Theme", tip = "Wayfarer, Classic dialog, or your class color.", choices = { { "wayfarer", "Wayfarer" }, { "blizzard", "Classic" }, { "class", "Class" } } },
			{ key = "backdropAlpha", kind = "slider", label = "Background", tip = "Opacity of the window background only. Text stays solid.", min = 0, max = 1, step = 0.05 },
			{ key = "showBorder", kind = "check", label = "Show border", tip = "Off removes the edge on every theme. The header, cog, and close button stay flush." },
			{ key = "windowScale", kind = "slider", label = "Window scale", tip = "Scale of the route window.", min = 0.8, max = 1.4, step = 0.05 },
			{ key = "font", kind = "menu", label = "Font", tip = "Typeface for the route window.", choices = { { 1, "Game font" }, { 2, "Friz Quadrata" }, { 3, "Arial Narrow" }, { 4, "Morpheus" }, { 5, "Skurri" }, { 6, "PT Sans Narrow" } } },
			{ key = "fontSize", kind = "slider", label = "Text size", tip = "Size of the route text.", min = 9, max = 22, step = 1 },
		},
	},
}

function ns.LogHash(ids, zone, x, y)
	local list = {}
	for i = 1, #(ids or {}) do
		list[#list + 1] = tostring(ids[i])
	end
	table.sort(list)
	local rx = math.floor((tonumber(x) or 0) + 0.5)
	local ry = math.floor((tonumber(y) or 0) + 0.5)
	return table.concat(list, ",") .. "|" .. tostring(zone or "") .. "|" .. rx .. "|" .. ry
end

function ns.ClampInterval(seconds)
	local n = math.floor((tonumber(seconds) or 30) + 0.5)
	if n < 15 then
		n = 15
	elseif n > 120 then
		n = 120
	end
	return n
end

function ns.ShouldTickRoute(opts)
	opts = opts or {}
	if opts.enabled == false then
		return false
	end
	if opts.inCombat then
		return false
	end
	if not opts.windowShown and not opts.useArrow then
		return false
	end
	if opts.hash ~= nil and opts.hash == opts.lastHash then
		return false
	end
	return true
end

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
