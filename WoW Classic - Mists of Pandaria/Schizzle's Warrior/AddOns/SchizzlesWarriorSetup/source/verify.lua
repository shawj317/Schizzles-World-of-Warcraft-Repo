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

-- Bartender4: real code path against a recording mock of its AceDB object.
local calls = {}
local namespaces = {}
Bartender4 = {
	db = { profile = { outofrange = "none", keep = 1 }, SetProfile = function(_, p) calls[#calls + 1] = "SetProfile:" .. p end,
		GetNamespace = function(_, name) namespaces[name] = namespaces[name] or { profile = { stale = true } }; return namespaces[name] end },
	GetModule = function(_, name) if name == "Presets" then return { ResetProfile = function(_, t) calls[#calls + 1] = "Reset:" .. t end } end end,
	UpdateModuleConfigs = function() calls[#calls + 1] = "Update" end,
}
check(ns.pieces.bars.run() == true, "bars piece reports success")
check(table.concat(calls, ",") == "SetProfile:" .. PROFILE .. ",Reset:DEFAULT,Update", "Bartender4: new profile, Blizzard preset, overlay, refresh")
check(Bartender4.db.profile.outofrange == D.Bartender4.profile.outofrange and Bartender4.db.profile.keep == 1, "Bartender4: profile overlay merged")
local allNs = true
for name, t in pairs(D.Bartender4.namespaces) do if not deepEqual(t, namespaces[name].profile) then allNs = false end end
check(allNs, "Bartender4: every module namespace merged")

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
local IGNORE = { profile = 1, namespaces = 1, r = 1, g = 1, b = 1, a = 1, x = 1, y = 1, point = 1, scale = 1 }
for _, spec in ipairs({ { "Bartender4", D.Bartender4 }, { "Prat-3.0", D["Prat 3.0"] }, { "SexyMap", D.SexyMap },
	{ "Questie", D.Questie }, { "GatherMate2", D.GatherMate2 }, { "TomTom", D.TomTom } }) do
	local src = sourceOf(spec[1])
	if #src == 0 then
		print("skip " .. spec[1] .. " key check (addon not found under " .. ADDONS .. ")")
	else
		local missing = {}
		for k in pairs(keysOf(spec[2])) do
			if not IGNORE[k] and not src:find(k, 1, true) then missing[#missing + 1] = k end
		end
		table.sort(missing)
		check(#missing == 0, spec[1] .. ": every setting key appears in the addon's code" .. (#missing > 0 and (" (missing: " .. table.concat(missing, ", ") .. ")") or ""))
	end
end

print(fails == 0 and "ALL CHECKS PASSED" or (fails .. " CHECK(S) FAILED"))
os.exit(fails == 0 and 0 or 1)
