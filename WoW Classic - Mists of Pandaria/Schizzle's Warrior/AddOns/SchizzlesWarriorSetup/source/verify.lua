-- Offline checks for Schizzle's Warrior Setup. Lua 5.1:
--   lua verify.lua <folder with the unpacked addons, e.g. a copy of Interface/AddOns>
-- 1. Data.lua matches the per-addon source files (build.lua --check does the same).
-- 2. Keybinds: runs the real binding code against a mocked binding API seeded with the stock
--    Blizzard binds plus stale ones, and checks the exact key map that comes out.
-- 3. Profiles: runs the real apply code, then loads the addons' own AceDB-3.0 on the written
--    saved variables (what happens on /reload) and checks the character lands on
--    "Schizzle's Warrior" with the values from the source files.
-- 4. Every setting key used appears somewhere in that addon's own Lua code (catches typos).
local ADDONS = assert(arg[1], "usage: lua verify.lua <AddOns folder>")
local PROFILE = "Schizzle's Warrior"
local fails = 0
local function check(cond, what)
	if cond then print("ok   " .. what) else fails = fails + 1; print("FAIL " .. what) end
end

-- 1. Data.lua is current ------------------------------------------------------------------
check(os.execute("lua build.lua --check > /dev/null 2>&1") == 0 or os.execute("\"" .. arg[-1] .. "\" build.lua --check > /dev/null") == 0, "Data.lua is up to date")

-- WoW API mocks ----------------------------------------------------------------------------
local frames = {}
function CreateFrame()
	local f = { events = {} }
	function f:RegisterEvent(e) self.events[e] = true end
	function f:UnregisterEvent(e) self.events[e] = nil end
	function f:SetScript(_, fn) self.script = fn end
	frames[#frames + 1] = f
	return f
end
function UnitName() return "Testwarrior" end
UnitNameUnmodified = UnitName
function GetRealmName() return "Test Realm" end
function UnitClass() return "Warrior", "WARRIOR" end
function UnitRace() return "Orc", "Orc" end
function UnitFactionGroup() return "Horde" end
function GetLocale() return "enUS" end
function GetCurrentRegion() return 1 end
function GetCurrentRegionName() return "US" end
function InCombatLockdown() return false end
function IsAddOnLoaded() return true end
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) print("     chat: " .. m:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end }
StaticPopupDialogs = {}
local shownPopups = {}
function StaticPopup_Show(n) shownPopups[#shownPopups + 1] = n end
SlashCmdList = {}
ACCOUNT_BINDINGS, CHARACTER_BINDINGS = 1, 2
function GetCurrentBindingSet() return 1 end
function hooksecurefunc() end
function geterrorhandler() return print end
securecallfunction = function(f, ...) return f(...) end
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
table.wipe = wipe
strlenutf8 = string.len

local binds = {
	Q = "STRAFELEFT", E = "STRAFERIGHT", A = "TURNLEFT", D = "TURNRIGHT", R = "REPLY", F = "ASSISTTARGET",
	Y = "TOGGLEACHIEVEMENT", ["1"] = "ACTIONBUTTON1", ["="] = "ACTIONBUTTON12", W = "MOVEFORWARD",
	NUMPAD1 = "MULTIACTIONBAR3BUTTON1", ["SHIFT-1"] = "CLICK BT4Button13:LeftButton", ["ALT-1"] = "CLICK BT4Button25:Keybind",
}
local saved
function GetBindingKey(cmd)
	local r = {}
	for k, v in pairs(binds) do if v == cmd then r[#r + 1] = k end end
	table.sort(r)
	return unpack(r)
end
function SetBinding(key, cmd) binds[key] = cmd; return true end
function GetBindingAction(key) return binds[key] or "" end
function SaveBindings(set) saved = set end

-- Load the addon the way the client does -------------------------------------------------
local ns = {}
assert(loadfile("../SchizzlesWarriorSetup/Data.lua"))("SchizzlesWarriorSetup", ns)
assert(loadfile("../SchizzlesWarriorSetup/Core.lua"))("SchizzlesWarriorSetup", ns)
check(type(SlashCmdList.SCHIZZLE) == "function", "/schizzle is registered")
frames[1].script(frames[1], "PLAYER_LOGIN")
check(shownPopups[1] == "SCHIZZLES_WARRIOR_FIRST", "first login shows the setup prompt")
local D = ns.data

-- 2. Keybinds -------------------------------------------------------------------------------
check(ns.pieces.binds.run() == true, "keybind piece reports success")
local expect = {
	Q = "MULTIACTIONBAR3BUTTON1", E = "MULTIACTIONBAR3BUTTON2", R = "MULTIACTIONBAR3BUTTON3", F = "MULTIACTIONBAR3BUTTON4",
	T = "MULTIACTIONBAR3BUTTON5", G = "MULTIACTIONBAR3BUTTON6", Y = "MULTIACTIONBAR3BUTTON7", BUTTON3 = "MULTIACTIONBAR3BUTTON8",
	BUTTON4 = "MULTIACTIONBAR3BUTTON9", ["CTRL-BUTTON3"] = "MULTIACTIONBAR3BUTTON10", ["CTRL-BUTTON4"] = "MULTIACTIONBAR3BUTTON11",
	["ALT-BUTTON3"] = "MULTIACTIONBAR3BUTTON12",
	["SHIFT-Q"] = "CLICK BT4Button13:Keybind", ["SHIFT-E"] = "CLICK BT4Button14:Keybind", ["SHIFT-R"] = "CLICK BT4Button15:Keybind",
	["SHIFT-F"] = "CLICK BT4Button16:Keybind", ["SHIFT-T"] = "CLICK BT4Button17:Keybind", ["SHIFT-G"] = "CLICK BT4Button18:Keybind",
	["SHIFT-Y"] = "CLICK BT4Button19:Keybind", ["SHIFT-BUTTON3"] = "CLICK BT4Button20:Keybind", ["SHIFT-BUTTON4"] = "CLICK BT4Button21:Keybind",
	["CTRL-Q"] = "CLICK BT4Button22:Keybind", ["CTRL-E"] = "CLICK BT4Button23:Keybind", ["ALT-BUTTON4"] = "CLICK BT4Button24:Keybind",
	A = "STRAFELEFT", D = "STRAFERIGHT",
	-- untouched
	["1"] = "ACTIONBUTTON1", ["="] = "ACTIONBUTTON12", W = "MOVEFORWARD",
}
local exact = true
for k, v in pairs(expect) do if binds[k] ~= v then exact = false; print("     " .. k .. " = " .. tostring(binds[k]) .. ", want " .. v) end end
for k, v in pairs(binds) do if v and not expect[k] then exact = false; print("     leftover " .. k .. " = " .. v) end end
check(exact, "binding map is exact (bar 3, bar 2, A/D strafe, bar 1 kept, stale binds cleared)")
check(saved == 1, "bindings saved to the account-wide set")

-- 3. Profiles -------------------------------------------------------------------------------
-- Existing saved variables, as an addon that has run before would leave them.
Prat3DB = { profileKeys = { ["Testwarrior - Test Realm"] = "Default" }, profiles = { Default = { modules = { Prat_Font = 2 } } } }
QuestieConfig = { profileKeys = { ["Testwarrior - Test Realm"] = "Default" }, profiles = { Default = { trackerEnabled = false } } }
GatherMate2DB = { profileKeys = {}, profiles = {} }
TomTomDB = {}
SexyMap2DB = { ["Testwarrior-Test Realm"] = { core = { lock = false } }, presets = {} }

for _, id in ipairs({ "chat", "quests", "gather", "tomtom", "map" }) do
	check(ns.pieces[id].run() == true, id .. " piece reports success")
end

local function loadLib(rel)
	local f = io.open(ADDONS .. "/" .. rel, "r")
	if not f then return false end
	f:close()
	assert(loadfile(ADDONS .. "/" .. rel))()
	return true
end
assert(loadLib("TomTom/libs/LibStub/LibStub.lua") or loadLib("Questie/Libs/LibStub/LibStub.lua"), "LibStub not found")
assert(loadLib("TomTom/libs/CallbackHandler-1.0/CallbackHandler-1.0.lua") or loadLib("Questie/Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua"))
assert(loadLib("TomTom/libs/AceDB-3.0/AceDB-3.0.lua") or loadLib("Questie/Libs/AceDB-3.0/AceDB-3.0.lua"), "AceDB-3.0 not found")
local AceDB = LibStub("AceDB-3.0")

local function deepEqual(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then return a == b end
	for k, v in pairs(a) do if not deepEqual(v, b[k]) then return false end end
	return true
end

local function aceCheck(label, svName, defaultProfile, data)
	local db = AceDB:New(svName, { profile = {} }, defaultProfile)
	check(db:GetCurrentProfile() == PROFILE, label .. ": character is on \"" .. PROFILE .. "\" after reload")
	check(deepEqual(data.profile or {}, db.profile), label .. ": profile values match the source file")
	for name, t in pairs(data.namespaces or {}) do
		local n = db:RegisterNamespace(name, { profile = {} })
		check(deepEqual(t, n.profile), label .. ": namespace " .. name .. " matches")
	end
end
aceCheck("Prat", "Prat3DB", "Default", D["Prat 3.0"])
check(Prat3DB.profiles.Default.modules.Prat_Font == 2, "Prat: old Default profile untouched")
aceCheck("Questie", "QuestieConfig", true, D.Questie)
aceCheck("GatherMate2", "GatherMate2DB", "Default", D.GatherMate2)
aceCheck("TomTom", "TomTomDB", "Default", D.TomTom)
check(SexyMap2DB["Testwarrior-Test Realm"] == "global" and deepEqual(D.SexyMap, SexyMap2DB.global), "SexyMap: character points at the new global profile")
-- SexyMap v2 values (Jon's in-game setup)
do
	local S = SexyMap2DB.global
	check(deepEqual(SexyMap2DB.global, D.SexyMap), "SexyMap: global profile is exactly the source file, both ways")
	check(S.core.scale == 1.5 and S.core.point == "TOPRIGHT" and S.core.relpoint == "TOPRIGHT"
		and math.abs(S.core.x + 4.38) < 0.01 and math.abs(S.core.y + 4.67) < 0.01, "SexyMap: 1.5x map in the top-right corner, about 4 px in")
	check(S.core.lock == false and S.core.autoZoom == 15 and S.core.shape == 130871 and S.core.northTag == false, "SexyMap: unlocked, square, auto zoom out after 15 s, no north tag")
	local bd = S.borders.backdrop
	check(bd.show and bd.settings.bgFile == nil and bd.settings.edgeFile == "Interface\\Tooltips\\UI-Tooltip-Border" and bd.settings.edgeSize == 6
		and bd.settings.tileSize == 0 and bd.scale == 1.03, "SexyMap: no fill, 6 px tooltip border, 3% larger than the map")
	check(math.floor(bd.borderColor.r * 255 + 0.5) == 184 and math.floor(bd.borderColor.g * 255 + 0.5) == 115 and math.floor(bd.borderColor.b * 255 + 0.5) == 51, "SexyMap: border is bronze (184, 115, 51)")
	local v = S.buttons.visibilitySettings
	check(v.GameTimeFrame == "never" and v.MiniMapTracking == "always" and v.MinimapZoomIn == "never" and v.MinimapZoomOut == "never"
		and v.MiniMapWorldMapButton == "never" and v.MiniMapMailFrame == "always", "SexyMap: calendar, zoom and world map hidden; tracking and mail shown")
	local ldb = 0
	for name, vis in pairs(v) do if name:find("^LibDBIcon10_") then ldb = ldb + 1; check(vis == "always", "SexyMap: " .. name .. " always shown") end end
	check(ldb == 11, "SexyMap: 11 add-on buttons listed")
	check(S.clock.fontsize == 9 and S.zonetext.fontsize == 9 and S.zonetext.yOffset == -18 and S.coordinates.fontSize == 8
		and S.coordinates.yOffset == 9 and S.coordinates.updateRate == 0.1, "SexyMap: clock 9, zone 9 (18 px down), coordinates 8 (9 px up, 10 updates a second)")
	check(S.clock.font == "Fira Sans Condensed Medium" and S.zonetext.font == S.clock.font and S.coordinates.font == S.clock.font, "SexyMap: font still Fira Sans Condensed Medium")
	check(S.movers.moveDurability == true and S.movers.lockDurability == true and S.movers.moveBuffs == false and S.movers.moveObjectives == false, "SexyMap: durability figure movable and locked, other movers off")
	local names = {}
	local function scan(t) for k, x in pairs(t) do if type(k) == "string" then names[#names + 1] = k end; if type(x) == "table" then scan(x) end end end
	scan(D.SexyMap)
	local personal = false
	for _, k in ipairs(names) do if k:find("%-") and not k:find("^LibDBIcon10_") then personal = true; print("     key with a dash: " .. k) end end
	check(not personal and D.SexyMap.presets == nil, "SexyMap: no 'Name-Realm' keys or presets in the source file")
end

-- Bartender4: the real bars piece against a real AceDB-3.0 object carrying the shape of
-- Bartender4's own defaults (Bartender4.lua, Bar.lua, ButtonBar.lua, ActionBars.lua, modules).
do
	local function with(base, extra)
		local r = ns.copy(base)
		ns.merge(r, extra)
		return r
	end
	local barDef = { alpha = 1, fadeout = false, fadeoutalpha = 0.1, fadeoutdelay = 0.2, clickthrough = false,
		visibility = { vehicleui = true, overridebar = true, stance = {} },
		position = { scale = 1, growVertical = "DOWN", growHorizontal = "RIGHT" } }
	local buttonBarDef = with(barDef, { padding = 2, rows = 1, hidemacrotext = false, hidehotkey = false, hideequipped = false, hideborder = false, skin = { Zoom = false } })
	local abDef = { ["**"] = with(buttonBarDef, { enabled = true, buttons = 12, buttonOffset = 0, showgrid = false, flyoutDirection = "UP",
		elements = { ["**"] = { font = "Arial Narrow", fontSize = 13, fontFlags = "OUTLINE", fontColor = { 1, 1, 1 }, textAnchor = "CENTER" },
			hotkey = { fontSize = 13, fontColor = { 0.9, 0.9, 0.9 }, textAnchor = "TOPRIGHT" }, count = { fontSize = 16 }, macro = { font = "Friz Quadrata TT", fontSize = 10 } } }),
		[7] = { enabled = false }, [8] = { enabled = false }, [9] = { enabled = false }, [10] = { enabled = false } }
	local nsDefaults = {
		ActionBars = { actionbars = abDef },
		StatusTrackingBar = with(barDef, { enabled = false, width = 1024, barPadding = 0 }),
		BlizzardArt = with(barDef, { enabled = false, artLayout = "CLASSIC" }),
		MicroMenu = with(buttonBarDef, { enabled = true, padding = -3, position = { scale = 0.8 } }),
		ExtraActionBar = with(barDef, { enabled = true, hideArtwork = false }),
		StanceBar = with(buttonBarDef, { enabled = true, position = { scale = 1.5 } }),
		PetBar = with(buttonBarDef, { enabled = true }),
		Vehicle = with(buttonBarDef, { enabled = true }),
		BagBar = with(buttonBarDef, { enabled = true, keyring = true }),
	}
	-- A character that already ran an older setup: stale values in the same profile.
	Bartender4DB = { profileKeys = { ["Testwarrior - Test Realm"] = PROFILE }, profiles = { [PROFILE] = { outofrange = "hotkey", focuscastmodifier = false } },
		namespaces = { ActionBars = { profiles = { [PROFILE] = { actionbars = { { position = { x = 999, y = 999, point = "TOP" } }, [5] = { rows = 1 } } } } },
			StatusTrackingBar = { profiles = { [PROFILE] = { enabled = true } } }, XPBar = { profiles = { [PROFILE] = { enabled = true } } } } }
	local db = AceDB:New("Bartender4DB", { profile = { tooltip = "enabled", buttonlock = true, outofrange = "button", selfcastmodifier = true,
		focuscastmodifier = true, snapping = true, blizzardVehicle = false, colors = { range = { r = 0.8, g = 0.1, b = 0.1 } } } }, true)
	for name, d in pairs(nsDefaults) do db:RegisterNamespace(name, { profile = d }) end
	local updates = 0
	Bartender4 = { db = db, UpdateModuleConfigs = function() updates = updates + 1 end }
	check(ns.pieces.bars.run() == true, "bars piece reports success")
	check(db:GetCurrentProfile() == PROFILE and updates >= 1, "Bartender4: on the \"" .. PROFILE .. "\" profile, modules refreshed")
	local P, AB = db.profile, db:GetNamespace("ActionBars").profile.actionbars
	check(P.outofrange == "button" and P.focuscastmodifier == true and P.blizzardVehicle == true, "Bartender4: stale profile values reset; Blizzard vehicle UI on")
	check(db:GetNamespace("StatusTrackingBar").profile.enabled == false and Bartender4DB.namespaces.XPBar.profiles[PROFILE] == nil,
		"Bartender4: status tracking bar off (Jon's file), old XP bar settings cleared")
	check(AB[1].position.x ~= 999 and AB[1].position.point == "BOTTOM" and AB[5].rows == 6, "Bartender4: stale bar values replaced")
	check(AB[1].buttons == 12 and AB[4].buttons == 8 and AB[1].elements.hotkey.fontFlags == "OUTLINE" and AB[1].position.growVertical == "DOWN",
		"Bartender4: bars keep Bartender4's defaults behind Jon's values")
	check(AB[1].elements.hotkey.font == "Fira Sans Condensed Medium" and AB[1].elements.hotkey.fontSize == 10 and AB[4].elements.hotkey.fontSize == 12,
		"Bartender4: Fira Sans hotkeys, 10 on bars 1-3 and 12 on bars 4-6")
	for i = 1, 6 do
		local mo = (i == 4 or i == 5)
		check(AB[i].enabled == true and (AB[i].fadeout == mo) and (not mo or AB[i].fadeoutalpha == 0),
			"Bartender4: bar " .. i .. (mo and " fades out until moused over" or " has no mouseover fade"))
	end
	check(AB[2].visibility.nocombat == true and AB[3].visibility.nocombat == true and AB[1].visibility.nocombat == nil,
		"Bartender4: bars 2 and 3 hidden out of combat (Jon's file), bar 1 always")
	check(db:GetNamespace("MicroMenu").profile.fadeout == true and db:GetNamespace("MicroMenu").profile.fadeoutalpha == 0, "Bartender4: micro menu still mouseover")
	check(db:GetNamespace("BagBar").profile.enabled == false and db:GetNamespace("PetBar").profile.enabled == false and db:GetNamespace("BlizzardArt").profile.enabled == false,
		"Bartender4: bag bar, pet bar and Blizzard art off")
	-- Log out: AceDB strips defaults, leaving exactly what Bartender4 would save. It must match
	-- the source file both ways (the same sparse shape as Jon's own saved variables).
	local logout
	for _, f in ipairs(frames) do if f.events.PLAYER_LOGOUT then logout = f end end
	if logout then logout.script(logout, "PLAYER_LOGOUT") end
	local function prune(t)
		if type(t) ~= "table" then return t end
		local r = {}
		for k, v in pairs(t) do local x = prune(v); if type(x) ~= "table" or next(x) then r[k] = x end end
		return r
	end
	local function same(a, b) return deepEqual(a, b) and deepEqual(b, a) end
	check(logout ~= nil and same(prune(Bartender4DB.profiles[PROFILE]), D.Bartender4.profile), "Bartender4: saved profile after logout is exactly the source file")
	local allNs = true
	for name, t in pairs(D.Bartender4.namespaces) do
		if not same(prune(Bartender4DB.namespaces[name].profiles[PROFILE]), t) then allNs = false; print("     namespace differs: " .. name) end
	end
	for name, n in pairs(Bartender4DB.namespaces) do
		local p = n.profiles and prune(n.profiles[PROFILE])
		if p and next(p) and not D.Bartender4.namespaces[name] then allNs = false; print("     extra namespace saved: " .. name) end
	end
	check(allNs, "Bartender4: every saved module namespace is exactly the source file")
	local personal = false
	local function scan(t) for k, x in pairs(t) do if type(k) == "string" and k:find(" %- ") then personal = true end; if type(x) == "table" then scan(x) end end end
	scan(D.Bartender4)
	check(not personal and D.Bartender4.profileKeys == nil, "Bartender4: no 'Name - Realm' keys in the source file")
end

-- 4. Setting keys exist in each addon's code ------------------------------------------------
local function sourceOf(folder)
	local p = io.popen('find "' .. ADDONS .. "/" .. folder .. '/" -name "*.lua" -not -path "*/[Ll]ibs/*" 2>/dev/null')
	local all = {}
	for file in p:lines() do local f = io.open(file); all[#all + 1] = f:read("*a"); f:close() end
	p:close()
	return table.concat(all, "\n")
end
local function keysOf(t, out)
	out = out or {}
	for k, v in pairs(t) do
		if type(k) == "string" then out[k] = true end
		if type(v) == "table" then keysOf(v, out) end
	end
	return out
end
-- LibDBIcon (in SexyMap's Libs) names each minimap button frame "LibDBIcon10_" .. icon name.
local function ldbiNames()
	local f = io.open(ADDONS .. "/SexyMap/Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua")
	if not f then return false end
	local s = f:read("*a"); f:close()
	return s:find('CreateFrame("Button", "LibDBIcon10_"..name', 1, true) ~= nil
end
local IGNORE = { profile = 1, namespaces = 1, r = 1, g = 1, b = 1, a = 1, x = 1, y = 1, point = 1, scale = 1 }
for _, spec in ipairs({ { "Bartender4", D.Bartender4 }, { "Prat-3.0", D["Prat 3.0"] }, { "SexyMap", D.SexyMap },
	{ "Questie", D.Questie }, { "GatherMate2", D.GatherMate2 }, { "TomTom", D.TomTom } }) do
	local src = sourceOf(spec[1])
	if #src == 0 then
		print("skip " .. spec[1] .. " key check (addon not found under " .. ADDONS .. ")")
	else
		local missing = {}
		for k in pairs(keysOf(spec[2])) do
			-- LibDBIcon minimap buttons are frames named "LibDBIcon10_" .. the add-on's icon name.
			local ldb = k:match("^LibDBIcon10_(.+)$")
			if ldb then
				check(spec[1] == "SexyMap" and src:find('n:find("LibDBIcon")', 1, true) and ldbiNames(),
					spec[1] .. ": " .. k .. " is a LibDBIcon button name SexyMap picks up")
			elseif not IGNORE[k] and not src:find(k, 1, true) then missing[#missing + 1] = k end
		end
		table.sort(missing)
		check(#missing == 0, spec[1] .. ": every setting key appears in the addon's code" .. (#missing > 0 and (" (missing: " .. table.concat(missing, ", ") .. ")") or ""))
	end
end

print(fails == 0 and "ALL CHECKS PASSED" or (fails .. " CHECK(S) FAILED"))
os.exit(fails == 0 and 0 or 1)
