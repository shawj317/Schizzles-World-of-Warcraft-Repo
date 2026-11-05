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
_G.C_Timer = { After = function(_, fn) fn() end }
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
for _, file in ipairs({ "Data.lua", "Core.lua", "Tray.lua" }) do
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
check(_G.SchizzlesWarriorSetupCharDB.applied == "F1.6", "version recorded")
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
check(not b[2].shown and not b[3].shown, "rep and guild bars hidden with nothing to show")

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
env.xp, env.level = 4000, 60
ns.trayUpdate()
check(not b[1].shown and b[2].points[1][5] == 0, "XP bar hidden at the cap, reputation moves up to the top")

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

print(fails == 0 and "all checks passed" or (fails .. " check(s) failed"))
os.exit(fails == 0 and 0 or 1)
