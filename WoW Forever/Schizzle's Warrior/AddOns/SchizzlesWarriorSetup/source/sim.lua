-- Offline check for the Forever helper: loads Data.lua, Core.lua and Tray.lua against a small stand-in for the game
-- API, then runs the first-login prompt, every piece and the tray's three bars through a few situations.
-- Run from this folder: lua sim.lua   (Lua 5.1). Exits non-zero on the first failure.
local fails = 0
local function check(ok, what)
	print((ok and "ok   " or "FAIL ") .. what)
	if not ok then fails = fails + 1 end
end

-- Stand-in widgets: just enough frame, texture and font string behaviour for the tray.
local function widget()
	local w = { shown = true, points = {}, scripts = {}, events = {} }
	local mt = {}
	mt.__index = function(_, k)
		return function(self, ...)
			if k == "Show" then self.shown = true
			elseif k == "Hide" then self.shown = false
			elseif k == "IsShown" then return self.shown
			elseif k == "SetText" then self.text = ...
			elseif k == "SetValue" then self.value = ...
			elseif k == "SetMinMaxValues" then self.min, self.max = ...
			elseif k == "SetScript" then local n, fn = ...; self.scripts[n] = fn
			elseif k == "RegisterEvent" then self.events[(...)] = true
			elseif k == "SetPoint" then self.points[#self.points + 1] = { ... }
			elseif k == "ClearAllPoints" then self.points = {}
			elseif k == "SetFont" then return true
			elseif k == "CreateTexture" or k == "CreateFontString" then return widget()
			end
		end
	end
	return setmetatable(w, mt)
end

local cvars = { autoLootDefault = "0", ActionButtonUseKeyDown = "0", cameraDistanceMaxZoomFactor = "1.9",
	nameplateShowEnemies = "0", showTargetOfTarget = "0", UberTooltips = "0" }
local env = {
	level = 20, maxLevel = 60, xp = 4000, xpMax = 10000, rested = 3000, quests = {}, inGuild = false,
	watched = nil, guild = nil, guildRep = true,
}
local frames, popups, chat, binds = {}, {}, {}, {}
_G.UIParent = widget()
_G.CreateFrame = function() local w = widget(); frames[#frames + 1] = w; return w end
_G.DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) chat[#chat + 1] = m end }
_G.StaticPopupDialogs = {}
_G.StaticPopup_Show = function(n) popups[#popups + 1] = n end
_G.SlashCmdList = {}
local simTime = 0
_G.GetTime = function() return simTime end
_G.C_Timer = {
	After = function(delay, fn)
		-- run immediately in most tests; NewTimer path advances explicitly
		fn()
	end,
	NewTimer = function(delay, fn)
		local cancelled = false
		local t = { Cancel = function() cancelled = true end, _fire = function() if not cancelled then fn() end end, _at = simTime + delay }
		_G.__simTimers = _G.__simTimers or {}
		_G.__simTimers[#_G.__simTimers + 1] = t
		return t
	end,
}
_G.__simAdvance = function(dt)
	simTime = simTime + dt
	for _, t in ipairs(_G.__simTimers or {}) do
		if t._at and simTime >= t._at then t._at = nil; t._fire() end
	end
end
_G.GameTooltip = widget()
_G.InCombatLockdown = function() return false end
_G.ReloadUI = function() end
_G.C_AddOns = { IsAddOnLoaded = function(n) return n ~= "TomTom" end }
_G.UnitName = function() return "Tester" end
local playerClass = "WARRIOR"
_G.UnitClass = function() return playerClass, playerClass end
_G.UnitNameUnmodified = function() return "Tester", "Surname" end
_G.GetRealmName = function() return "Realm" end
_G.RegionalUniqueNamesEnabled = function() return false end
_G.C_CVar = { GetCVar = function(n) return cvars[n] end, SetCVar = function(n, v) cvars[n] = v end }
_G.GetBindingKey = function() end
_G.SetBinding = function(k, c) if k then binds[k] = c end end
_G.GetBindingAction = function(k) return binds[k] or "" end
_G.SaveBindings = function() end
_G.UnitLevel = function() return env.level end
_G.GetMaxLevelForPlayerExpansion = function() return env.maxLevel end
_G.IsXPUserDisabled = function() return false end
_G.UnitXP = function() return env.xp end
_G.UnitXPMax = function() return env.xpMax end
_G.GetXPExhaustion = function() return env.rested end
_G.GetQuestLogRewardXP = function(id) return env.quests[id] and env.quests[id].xp or 0 end
_G.C_QuestLog = {
	GetNumQuestLogEntries = function() return #env.quests end,
	GetInfo = function(i) return env.quests[i] and { questID = i, isHeader = false } end,
	ReadyForTurnIn = function(id) return env.quests[id] and env.quests[id].done end,
}
_G.C_Reputation = { GetWatchedFactionData = function() return env.watched end, GetGuildFactionData = function() return env.guild end }
_G.C_GuildInfo = { IsGuildReputationEnabled = function() return env.guildRep end }
_G.IsInGuild = function() return env.inGuild end
_G.GetGuildInfo = function() return env.inGuild and "Guild" or nil end
_G.issecretvalue = function(v) return v == "secret" end
_G.wipe = function(t) for k in pairs(t) do t[k] = nil end; return t end
_G.RANGE_INDICATOR = "●"
_G.GetActionInfo = function() return nil end
_G.GetMacroSpell = function() return nil end
_G.GetBindingText = function(k) return k end
_G.pcall = pcall
_G.LibStub = function() return nil end
_G.tostring = tostring
_G.type = type
_G.pairs = pairs
_G.ipairs = ipairs
_G.table = table

-- Addons the helper talks to.
local bt = { profile = {}, ns = {} }
_G.Bartender4 = { db = {
	SetProfile = function() end, ResetProfile = function() bt.profile = {} end,
	GetNamespace = function(_, n) bt.ns[n] = bt.ns[n] or { profile = {} }; return bt.ns[n] end,
}, UpdateModuleConfigs = function() end }
setmetatable(_G.Bartender4.db, { __index = function(_, k) if k == "profile" then return bt.profile end end })
local imported
_G.Details = { ImportProfile = function(_, s, name, autorun, prompt, over) imported = { s = s, name = name, autorun = autorun, over = over }; return true end }
_G.Prat3DB, _G.QuestieConfig, _G.GatherMate2DB, _G.SexyMap2DB = {}, {}, {}, {}

local ns = {}
for _, file in ipairs({ "Data.lua", "Core.lua", "Keys.lua", "Rend.lua", "Tray.lua" }) do
	assert(loadfile("../SchizzlesWarriorSetup/" .. file))("SchizzlesWarriorSetup", ns)
end

-- First login: tray switched on, prompt shown once.
frames[1].scripts.OnEvent(frames[1], "PLAYER_LOGIN")
check(popups[1] == "SCHIZZLES_WARRIOR_FIRST", "first login asks before changing anything")
check(_G.SchizzlesWarriorSetupDB.tray == true, "tray defaults to on")

-- Accept: every piece runs, TomTom (not loaded here) is skipped.
_G.StaticPopupDialogs.SCHIZZLES_WARRIOR_FIRST.OnAccept()
check(cvars.autoLootDefault == "1" and cvars.ActionButtonUseKeyDown == "1" and cvars.cameraDistanceMaxZoomFactor == "2.6", "console variables set")
local skippedMsg = false
for _, m in ipairs(chat) do if m:find("cooldownViewerEnabled") then skippedMsg = true end end
check(skippedMsg and cvars.cooldownViewerEnabled == nil, "a console variable the client lacks is skipped, not created")
check(imported and imported.name == "Schizzle's Warrior" and imported.autorun == false and imported.over == true and #imported.s > 1000, "Details! profile imported, no auto-run code")
check(_G.Prat3DB.profileKeys["Tester - Realm"] == "Schizzle's Warrior", "Prat profile assigned")
check(_G.SexyMap2DB["Tester-Realm"] == "global", "SexyMap profile assigned")
check(_G.SchizzlesWarriorSetupCharDB.applied == "F2.10", "version recorded")
check(popups[#popups] == "SCHIZZLES_WARRIOR_RELOAD", "reload offered")
local tomtomSkipped = false
for _, m in ipairs(chat) do if m:find("TomTom: not installed") then tomtomSkipped = true end end
check(tomtomSkipped, "missing addon skipped with a message")

-- Tray.
local function bars()
	local list = {}
	for i = 1, #frames do if frames[i].SetStatusBarTexture and frames[i].scripts.OnEnter then list[#list + 1] = frames[i] end end
	return list
end
local b = bars()
check(#b == 3, "tray has three bars")
ns.trayUpdate()
check(b[1].shown and b[1].value == 4000 and b[1].max == 10000, "XP bar shows 4,000 / 10,000")
check(b[1].left.text == "Level 20   Rested 30%", "XP left text: " .. tostring(b[1].left.text))
check(b[2].shown and b[2].left.text == "No faction watched" and not b[3].shown,
	"rep placeholder when nothing watched; guild hidden")

env.quests = { { xp = 500, done = true }, { xp = 900, done = false }, { xp = 700, done = true } }
ns.trayUpdate()
check(b[1].right.text:find("+1200 quest", 1, true) ~= nil, "completed-quest XP counted (only finished ones): " .. b[1].right.text)
check(b[1].quest.shown and b[1].rest.shown, "green and purple overlays drawn")

env.watched = { factionID = 72, name = "Stormwind", reaction = 6, currentReactionThreshold = 9000, nextReactionThreshold = 21000, currentStanding = 15000 }
env.inGuild, env.guild = true, { factionID = 1168, name = "Guild", reaction = 5, currentReactionThreshold = 3000, nextReactionThreshold = 9000, currentStanding = 4000 }
ns.trayUpdate()
check(b[2].shown and b[2].value == 6000 and b[2].max == 12000 and b[2].left.text == "Stormwind   Honored", "watched reputation bar")
check(b[3].shown and b[3].left.text == "Guild   Friendly", "guild reputation bar")
env.guildRep = false
ns.trayUpdate()
check(not b[3].shown, "guild bar hidden when the client has guild reputation off")
env.guildRep = true
env.watched = env.guild
ns.trayUpdate()
check(b[2].shown and b[2].left.text == "Guild   Friendly" and not b[3].shown, "guild not drawn twice when it is the watched faction")

env.xp = "secret"
ns.trayUpdate()
check(not b[1].shown, "a hidden (secret) value hides the XP bar instead of erroring")
env.xp, env.level = 4000, 20

-- Forever / Classic without C_Reputation.GetWatchedFactionData: GetWatchedFactionInfo fallback.
env.watched = nil
local keepCR = _G.C_Reputation
_G.C_Reputation = { GetGuildFactionData = keepCR.GetGuildFactionData }
_G.GetWatchedFactionInfo = function()
	return "Darkspear Trolls", 5, 3000, 9000, 4500, 530
end
ns.trayUpdate()
check(b[2].shown and b[2].left.text == "Darkspear Trolls   Friendly" and b[2].value == 1500,
	"GetWatchedFactionInfo fallback fills the rep bar")
_G.GetWatchedFactionInfo = nil
_G.C_Reputation = keepCR

-- Auto-watch / last-gained: with nothing watched, rememberFaction stores and SetWatchedFactionByID runs.
env.watched = nil
local setCalls = {}
_G.C_Reputation.SetWatchedFactionByID = function(fid) setCalls[#setCalls + 1] = fid; env.watched = {
	factionID = fid, name = "Orgrimmar", reaction = 5,
	currentReactionThreshold = 3000, nextReactionThreshold = 9000, currentStanding = 5000,
} end
_G.C_Reputation.GetFactionDataByID = function(fid)
	if fid == 76 then
		return { factionID = 76, name = "Orgrimmar", reaction = 5,
			currentReactionThreshold = 3000, nextReactionThreshold = 9000, currentStanding = 5000 }
	end
end
ns.trayRememberFaction(76, "Orgrimmar")
ns.trayUpdate()
check(setCalls[1] == 76, "auto-watch calls SetWatchedFactionByID for last-gained faction")
check(b[2].shown and b[2].left.text:find("Orgrimmar", 1, true), "auto-watched Orgrimmar shows on rep bar")
-- Chat faction-gain path: message containing a known faction name.
env.watched = nil
setCalls = {}
_G.C_Reputation.GetNumFactions = function() return 1 end
_G.C_Reputation.GetFactionDataByIndex = function()
	return { factionID = 76, name = "Orgrimmar", reaction = 5,
		currentReactionThreshold = 3000, nextReactionThreshold = 9000, currentStanding = 5000 }
end
ns.trayNoteFactionGain("Reputation with Orgrimmar increased by 25.")
check(setCalls[1] == 76, "CHAT faction-gain note auto-watches Orgrimmar")
_G.C_Reputation.SetWatchedFactionByID = nil
_G.C_Reputation.GetFactionDataByID = nil
_G.C_Reputation.GetNumFactions = nil
_G.C_Reputation.GetFactionDataByIndex = nil

-- Cap: XP hides, watched rep (or last-gained) moves to the top of the tray.
env.watched = { factionID = 72, name = "Stormwind", reaction = 6, currentReactionThreshold = 9000, nextReactionThreshold = 21000, currentStanding = 15000 }
env.level, env.xp = 60, 4000
ns.trayUpdate()
check(not b[1].shown and b[2].shown and b[2].points[1][5] == 0, "XP bar hidden at the cap, reputation moves up to the top")

_G.SlashCmdList.SCHIZZLE("tray")
check(_G.SchizzlesWarriorSetupDB.tray == false, "/schizzle tray toggles it off")

-- /schizzle auras: imports the Musca pack, only into Musca Auras, never in combat, never from "all".
local function said(text)
	for _, m in ipairs(chat) do if m:find(text, 1, true) then return true end end
	return false
end
local f = assert(io.open("../../Musca Auras/Schizzle's Warrior Essentials.txt", "rb"))
local pack = f:read("*a"):gsub("%s+$", "")
f:close()
local importedAuras
_G.SlashCmdList.SCHIZZLE("auras")
check(said("Musca Auras isn't loaded"), "/schizzle auras without Musca Auras: says so")
_G.WeakAuras = { Import = function(s) importedAuras = s; return true end }
_G.C_AddOns.GetAddOnMetadata = function(name, field) if name == "WeakAuras" and field == "Title" then return "WeakAuras" end end
_G.SlashCmdList.SCHIZZLE("auras")
check(importedAuras == nil, "/schizzle auras ignores a WeakAuras that isn't Musca Auras")
_G.C_AddOns.GetAddOnMetadata = function(name, field) if name == "WeakAuras" and field == "Title" then return "Musca Auras" end end
_G.InCombatLockdown = function() return true end
_G.SlashCmdList.SCHIZZLE("auras")
check(importedAuras == nil, "/schizzle auras waits for the end of combat")
_G.InCombatLockdown = function() return false end
_G.SlashCmdList.SCHIZZLE("auras")
check(importedAuras == pack and pack:sub(1, 6) == "!WA:2!", "/schizzle auras hands Musca the pack's import string, unchanged")
importedAuras = nil
_G.SlashCmdList.SCHIZZLE("all")
check(importedAuras == nil, "/schizzle all leaves the pack out")

-- /schizzle cdm: Blizzard's Cooldown Manager on and off.
chat = {}
_G.SlashCmdList.SCHIZZLE("cdm")
check(said("no Cooldown Manager") and cvars.cooldownViewerEnabled == nil, "/schizzle cdm on a client without it: says so, creates nothing")
cvars.cooldownViewerEnabled = "1"
_G.SlashCmdList.SCHIZZLE("cdm")
check(cvars.cooldownViewerEnabled == "0" and said("Cooldown Manager off"), "/schizzle cdm turns it off")
_G.SlashCmdList.SCHIZZLE("cdm")
check(cvars.cooldownViewerEnabled == "1" and said("Cooldown Manager on"), "/schizzle cdm turns it back on")

-- A local config naming another character keeps the prompt away.
popups, _G.SchizzlesWarriorSetupCharDB = {}, nil
_G.SchizzlesWarriorSetupLocal = { character = "SomeoneElse" }
frames[1].scripts.OnEvent(frames[1], "PLAYER_LOGIN")
check(#popups == 0, "local config for another character: no prompt")

-- Another class: general UI only, no account keybinds, no Warrior bars, no aura pack.
playerClass = "WARLOCK"
_G.SchizzlesWarriorSetupLocal = nil
popups, binds, chat, importedAuras = {}, {}, {}, nil
_G.SlashCmdList.SCHIZZLE("binds")
check(next(binds) == nil and said("Warrior only"), "binds skipped on a non-Warrior")
_G.SlashCmdList.SCHIZZLE("auras")
check(importedAuras == nil and said("Warrior pack"), "/schizzle auras refused on a non-Warrior")
_G.SchizzlesWarriorSetupCharDB = nil
frames[1].scripts.OnEvent(frames[1], "PLAYER_LOGIN")
check(popups[#popups] == "SCHIZZLES_WARRIOR_FIRST", "a non-Warrior is still asked once for the general UI")
playerClass = "WARRIOR"


-- SexyMap 12.1.5 regional unique names: plain "First Last" key, plus the older "First Last-PvE" form.
_G.SexyMap2DB = {}
_G.RegionalUniqueNamesEnabled = function() return true end
_G.C_GameRules = { IsGameRuleActive = function() return false end }
_G.Enum = { GameRule = { HardcoreRuleset = 1, RPRuleset = 2, PvPRuleset = 3 } }
_G.UnitNameUnmodified = function() return "First", "Last" end
_G.UnitName = function() return "First" end
ns.pieces.map.run()
check(_G.SexyMap2DB["First Last"] == "global", "SexyMap regional: plain First Last key points at global")
check(_G.SexyMap2DB["First Last-PvE"] == "global", "SexyMap regional: First Last-PvE key kept for older SexyMap")
_G.RegionalUniqueNamesEnabled = function() return false end

-- Key map: Bartender4 bars 1-6 Blizzard-binding mode + CLICK binds + Warrior stance pages 73-108.
do
	local actions, bindings = {}, {}
	_G.GetActionInfo = function(slot)
		local a = actions[slot]
		if a then return a[1], a[2] end
	end
	_G.GetBindingKey = function(cmd) return bindings[cmd] end
	_G.GetMacroSpell = function() end
	_G.C_Spell = {
		GetSpellName = function(id)
			local names = {
				[78] = "Heroic Strike", [772] = "Rend", [6343] = "Thunder Clap", [100] = "Charge",
				[6673] = "Battle Shout", [2687] = "Bloodrage", [5308] = "Execute", [7384] = "Overpower",
				[6572] = "Revenge", [845] = "Cleave", [20572] = "Blood Fury",
			}
			return names[id]
		end,
		GetSpellInfo = function(id)
			local n = _G.C_Spell.GetSpellName(id)
			if n then return { name = n, spellID = id } end
		end,
	}
	local function mkbtn(i, action, hot)
		local b = widget()
		b._state_action = action
		b.action = action
		b.GetName = function() return "BT4Button" .. i end
		b.GetAttribute = function(_, k) if k == "action" then return action end end
		b.HotKey = { GetText = function() return hot end }
		_G["BT4Button" .. i] = b
		return b
	end
	-- Bars 1-6 frames (BT4 only creates enabled bars).
	for i = 1, 72 do mkbtn(i, i, nil) end
	-- Bar 1 ACTIONBUTTON / HotKey
	mkbtn(2, 2, "2"); actions[2] = { "spell", 78 }; bindings["ACTIONBUTTON2"] = "2"
	-- Bar 2 CLICK Keybind (no Blizzard mapping)
	mkbtn(13, 13, "s-Q"); actions[13] = { "spell", 6673 }; bindings["CLICK BT4Button13:Keybind"] = "SHIFT-Q"
	-- Bar 3 MULTIACTIONBAR3 + CLICK
	mkbtn(25, 25, "Q"); actions[25] = { "spell", 772 }; bindings["CLICK BT4Button25:Keybind"] = "Q"
	mkbtn(26, 26, "●"); actions[26] = { "spell", 6343 }; bindings["MULTIACTIONBAR3BUTTON2"] = "E"
	-- Bar 4 MULTIACTIONBAR4
	mkbtn(37, 37, nil); actions[37] = { "spell", 2687 }; bindings["MULTIACTIONBAR4BUTTON1"] = "F"
	-- Bar 5 MULTIACTIONBAR2 (BT4 mapping)
	mkbtn(49, 49, nil); actions[49] = { "spell", 5308 }; bindings["MULTIACTIONBAR2BUTTON1"] = "T"
	-- Bar 6 MULTIACTIONBAR1
	mkbtn(61, 61, nil); actions[61] = { "spell", 845 }; bindings["MULTIACTIONBAR1BUTTON1"] = "C"
	-- HotKey-only on bar 3
	mkbtn(27, 27, "R"); actions[27] = { "spell", 100 }
	mkbtn(28, 28, "G"); actions[28] = { "spell", 20572 }
	-- Warrior Battle stance page: BT4Button1 shows action 73 (Charge page), bind still ACTIONBUTTON1
	mkbtn(1, 73, "1"); actions[73] = { "spell", 7384 }; bindings["ACTIONBUTTON1"] = "1"
	-- Raw stance slot without button still maps ACTIONBUTTON
	actions[85] = { "spell", 6572 } -- Defensive page slot → ACTIONBUTTON1 remap ((85-1)%12+1=1) — wait idx for 85: ((85-1)%12)+1 = 1
	-- Use slot 86 → idx 2 so it does not collide with Overpower on ACTIONBUTTON1
	actions[86] = { "spell", 6572 }; bindings["ACTIONBUTTON2"] = "2"

	local map = ns.rebuildKeys()
	check(_G.SchizzlesWarriorSetup_Keys[78] == "2", "keys: Heroic Strike bar1 ACTIONBUTTON2")
	check(_G.SchizzlesWarriorSetup_Keys["Battle Shout"] == "s-Q" or _G.SchizzlesWarriorSetup_Keys[6673] == "s-Q",
		"keys: Battle Shout bar2 CLICK Keybind")
	check(_G.SchizzlesWarriorSetup_Keys[772] == "Q" or _G.SchizzlesWarriorSetup_Keys["Rend"] == "Q",
		"keys: Rend bar3 CLICK Keybind")
	check(_G.SchizzlesWarriorSetup_Keys[6343] == "E" or _G.SchizzlesWarriorSetup_Keys["Thunder Clap"] == "E",
		"keys: Thunder Clap MULTIACTIONBAR3 (ignore HotKey ●)")
	check(_G.SchizzlesWarriorSetup_Keys[2687] == "F" or _G.SchizzlesWarriorSetup_Keys["Bloodrage"] == "F",
		"keys: Bloodrage bar4 MULTIACTIONBAR4")
	check(_G.SchizzlesWarriorSetup_Keys[5308] == "T" or _G.SchizzlesWarriorSetup_Keys["Execute"] == "T",
		"keys: Execute bar5 MULTIACTIONBAR2")
	check(_G.SchizzlesWarriorSetup_Keys[845] == "C" or _G.SchizzlesWarriorSetup_Keys["Cleave"] == "C",
		"keys: Cleave bar6 MULTIACTIONBAR1")
	check(_G.SchizzlesWarriorSetup_Keys[100] == "R" or _G.SchizzlesWarriorSetup_Keys["Charge"] == "R",
		"keys: Charge HotKey-only")
	check(_G.SchizzlesWarriorSetup_Keys[20572] == "G" or _G.SchizzlesWarriorSetup_Keys["Blood Fury"] == "G",
		"keys: Blood Fury on tray")
	check(_G.SchizzlesWarriorSetup_Keys[7384] == "1" or _G.SchizzlesWarriorSetup_Keys["Overpower"] == "1",
		"keys: stance-paged bar1 action 73 → ACTIONBUTTON1")
	check(_G.SchizzlesWarriorSetup_Keys[6572] == "2" or _G.SchizzlesWarriorSetup_Keys["Revenge"] == "2",
		"keys: raw stance slot 86 → ACTIONBUTTON2")
	check(ns.keysShorten("SHIFT-Q") == "s-Q", "keys: shorten SHIFT-Q")
	check(ns.keysShorten("CTRL-BUTTON4") == "c-M4", "keys: shorten CTRL-BUTTON4")
	check(ns.keysBindingByBar[3] == "MULTIACTIONBAR3BUTTON%d", "keys: BT4 BINDING_MAPPINGS bar3")
	check(ns.keysBindingByBar[6] == "MULTIACTIONBAR1BUTTON%d", "keys: BT4 BINDING_MAPPINGS bar6")
	chat = {}
	ns.diagnoseKeys()
	local keyed, listed = false, false
	for _, m in ipairs(chat) do
		if m:find("keybind diagnose", 1, true) then keyed = true end
		if m:find("BT4Button25", 1, true) and m:find("Rend", 1, true) then listed = true end
	end
	check(keyed, "/schizzle keys prints diagnose header")
	check(listed, "/schizzle keys lists BT4Button25 Rend with spell/bind")
	local trayLine = false
	for _, m in ipairs(chat) do if m:find("Essentials Utility tray", 1, true) then trayLine = true end end
	check(trayLine, "/schizzle keys lists Essentials Utility tray section")
	-- Slash command routes to the same diagnose.
	chat = {}
	_G.SlashCmdList.SCHIZZLE("keys")
	local viaSlash = false
	for _, m in ipairs(chat) do if m:find("keybind diagnose", 1, true) then viaSlash = true end end
	check(viaSlash, "/schizzle keys routes to diagnose")
end

-- Rend land tracker: rank duration, recast reset, miss does not grey, target clear, CLEU remove.
do
	_G.UnitGUID = function(u)
		if u == "player" then return "player-guid" end
		if u == "target" then return "target-guid-a" end
	end
	_G.UnitExists = function() return true end
	_G.UnitIsDeadOrGhost = function() return false end
	local scan = {}
	_G.WeakAuras = { ScanEvents = function(ev) scan[#scan + 1] = ev end }
	-- Prefer CLEU path when available.
	local cleu
	_G.CombatLogGetCurrentEventInfo = function()
		if not cleu then return end
		return unpack(cleu)
	end
	local function fireCLEU(sub, spellId, dest)
		cleu = { 0, sub, false, "player-guid", "Me", 0, 0, dest or "target-guid-a", "Mob", 0, 0, spellId, "Rend", 1, "DEBUFF" }
		-- Find Rend frame and fire
		for _, fr in ipairs(frames) do
			if fr.events["COMBAT_LOG_EVENT_UNFILTERED"] and fr.scripts.OnEvent then
				fr.scripts.OnEvent(fr, "COMBAT_LOG_EVENT_UNFILTERED")
			end
		end
		cleu = nil
	end
	local function fireCast(spellId)
		for _, fr in ipairs(frames) do
			if fr.events["UNIT_SPELLCAST_SUCCEEDED"] and fr.scripts.OnEvent then
				fr.scripts.OnEvent(fr, "UNIT_SPELLCAST_SUCCEEDED", "player", "cg", spellId)
			end
		end
	end
	local function fireTargetChanged()
		for _, fr in ipairs(frames) do
			if fr.events["PLAYER_TARGET_CHANGED"] and fr.scripts.OnEvent then
				fr.scripts.OnEvent(fr, "PLAYER_TARGET_CHANGED")
			end
		end
	end
	local function fireError(msg)
		for _, fr in ipairs(frames) do
			if fr.events["UI_ERROR_MESSAGE"] and fr.scripts.OnEvent then
				fr.scripts.OnEvent(fr, "UI_ERROR_MESSAGE", 0, msg)
			end
		end
	end

	ns.rendClear("test-start")
	-- R3 lands via CLEU → grey 15s
	fireCLEU("SPELL_AURA_APPLIED", 6547)
	check(_G.SchizzlesWarriorSetup_Rend.active == true, "rend: CLEU APPLIED activates")
	check(_G.SchizzlesWarriorSetup_Rend.duration == 15, "rend: R3 duration 15s")
	check(_G.SchizzlesWarriorSetup_Rend.source:find("cleu", 1, true) ~= nil, "rend: source is CLEU")
	check(_G.SchizzlesWarriorSetup_Rend.cleuAvailable == true, "rend: CLEU marked available")
	local exp1 = _G.SchizzlesWarriorSetup_Rend.expires
	-- Recast/refresh at ~10s remaining resets timer
	_G.__simAdvance(5)
	fireCLEU("SPELL_AURA_REFRESH", 6547)
	check(_G.SchizzlesWarriorSetup_Rend.expires > exp1, "rend: refresh resets expires")
	check((_G.SchizzlesWarriorSetup_Rend.expires - GetTime()) >= 14.9, "rend: refresh restores ~15s")
	-- Aura removed early → clear
	fireCLEU("SPELL_AURA_REMOVED", 6547)
	check(_G.SchizzlesWarriorSetup_Rend.active ~= true, "rend: CLEU REMOVED clears")

	-- Miss path: cast succeeded then SPELL_MISSED → stays colour (inactive)
	ns.rendClear("pre-miss")
	-- Override C_Timer.After to NOT auto-confirm so CLEU miss can win the race
	local afterFns = {}
	_G.C_Timer.After = function(delay, fn) afterFns[#afterFns + 1] = fn end
	fireCast(6547)
	check(_G.SchizzlesWarriorSetup_Rend.active ~= true, "rend: pending cast does not grey yet")
	fireCLEU("SPELL_MISSED", 6547)
	for _, fn in ipairs(afterFns) do fn() end -- timeout must not land after miss
	check(_G.SchizzlesWarriorSetup_Rend.active ~= true, "rend: SPELL_MISSED does not grey")

	-- Forever fallback: cast succeeded + no CLEU miss → land with rank duration
	afterFns = {}
	_G.C_Timer.After = function(delay, fn) afterFns[#afterFns + 1] = fn end
	-- Reset cleuAvailable by clearing without CLEU; module keeps cleuSeen sticky — ok for Forever report
	fireCast(772) -- R1 = 9s
	for _, fn in ipairs(afterFns) do fn() end
	check(_G.SchizzlesWarriorSetup_Rend.active == true, "rend: cast-succeeded fallback lands")
	check(_G.SchizzlesWarriorSetup_Rend.duration == 9, "rend: R1 duration 9s")

	-- UI_ERROR miss cancels pending
	afterFns = {}
	_G.C_Timer.After = function(delay, fn) afterFns[#afterFns + 1] = fn end
	ns.rendClear("pre-ui-miss")
	fireCast(6548) -- R4 18s
	fireError("Your Rend was dodged by Mob")
	for _, fn in ipairs(afterFns) do fn() end
	check(_G.SchizzlesWarriorSetup_Rend.active ~= true, "rend: UI_ERROR dodge cancels pending")

	-- Target swap clears
	afterFns = {}
	_G.C_Timer.After = function(_, fn) fn() end -- immediate confirm again
	fireCast(11572) -- R5 21s
	check(_G.SchizzlesWarriorSetup_Rend.active == true and _G.SchizzlesWarriorSetup_Rend.duration == 21, "rend: R5 duration 21s")
	fireTargetChanged()
	check(_G.SchizzlesWarriorSetup_Rend.active ~= true, "rend: target change clears")

	check(ns.rendDurations[6547] == 15 and ns.rendDurations[772] == 9, "rend: duration table Forever ranks")
end

print(fails == 0 and "all checks passed" or (fails .. " check(s) failed"))
os.exit(fails == 0 and 0 or 1)
