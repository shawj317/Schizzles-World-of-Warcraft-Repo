-- Schizzle's Warrior Setup by Jon Shaw (Schizzle). MIT with attribution.
-- Applies the Schizzle's Warrior settings from Data.lua. Nothing runs until you accept the
-- prompt or type /schizzle. Every addon gets a new profile called "Schizzle's Warrior", so your
-- old profiles stay where they are and you can switch back in each addon's profile options.
local ADDON, ns = ...
local D = ns.data
local PROFILE = "Schizzle's Warrior"
local VERSION = "3"

local IsLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded

local function say(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cffb87333Schizzle's Warrior|r: " .. msg)
end

local function copy(v)
	if type(v) ~= "table" then return v end
	local r = {}
	for k, x in pairs(v) do r[k] = copy(x) end
	return r
end
ns.copy = copy

-- Deep merge into existing tables, so AceDB's defaults (and its "**" templates, such as
-- Bartender4's per-bar defaults) stay behind every value that isn't set. Lists of plain values
-- (colours like { 0.78, 0.61, 0.43 }) are replaced whole.
local function merge(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" and type(v[1]) ~= "number" and type(v[1]) ~= "string" and type(dst[k]) == "table" then
			merge(dst[k], v)
		else
			dst[k] = copy(v)
		end
	end
end
ns.merge = merge

-- The keys AceDB and SexyMap use for this character. Both libraries switch to a region-wide
-- "Name - PvE" style key when the game runs regional unique names, so both forms are written.
local function charKeys()
	local plain = UnitName("player")
	local unmod, surname = (UnitNameUnmodified or UnitName)("player")
	local realm = GetRealmName()
	local ace, sm = { unmod .. " - " .. realm }, { plain .. "-" .. realm, unmod .. "-" .. realm }
	if RegionalUniqueNamesEnabled and RegionalUniqueNamesEnabled() and C_GameRules and Enum and Enum.GameRule then
		local rule = C_GameRules.IsGameRuleActive
		local rk = (rule(Enum.GameRule.HardcoreRuleset) and "Hardcore") or (rule(Enum.GameRule.RPRuleset) and "RP")
			or (rule(Enum.GameRule.PvPRuleset) and "PvP") or "PvE"
		ace[#ace + 1] = surname and (unmod .. " " .. tostring(surname)) or unmod
		if surname then sm[#sm + 1] = unmod .. " " .. surname .. "-" .. rk end
	end
	return ace, sm
end
ns.charKeys = charKeys

-- Writes an AceDB profile straight into an addon's saved variables and points this character at
-- it. The addon picks it up on the reload that follows.
local function aceProfile(svName, data)
	local sv = _G[svName]
	if type(sv) ~= "table" then return false, "saved variables not loaded" end
	sv.profiles = sv.profiles or {}
	sv.profiles[PROFILE] = copy(data.profile or {})
	if data.namespaces then
		sv.namespaces = sv.namespaces or {}
		for name, t in pairs(data.namespaces) do
			local n = sv.namespaces[name] or {}
			sv.namespaces[name] = n
			n.profiles = n.profiles or {}
			n.profiles[PROFILE] = copy(t)
		end
	end
	sv.profileKeys = sv.profileKeys or {}
	for _, key in ipairs((charKeys())) do sv.profileKeys[key] = PROFILE end
	return true
end
ns.aceProfile = aceProfile

local pieces = {}
local order = { "binds", "bars", "chat", "map", "quests", "gather", "tomtom" }

pieces.binds = {
	label = "Keybinds (account-wide)",
	run = function()
		local K = D.Keybinds
		local function clear(cmd)
			local keys = { GetBindingKey(cmd) }
			for _, key in ipairs(keys) do SetBinding(key) end
		end
		for i = 1, 12 do
			clear(K.bar3.command:format(i))
			clear(K.bar2.command:format(K.bar2.first + i - 1))
			-- Older Bartender4 click binds on the same buttons.
			clear(("CLICK BT4Button%d:LeftButton"):format(K.bar2.first + i - 1))
			clear(("CLICK BT4Button%d:Keybind"):format(24 + i))
			clear(("CLICK BT4Button%d:LeftButton"):format(24 + i))
		end
		for i, key in ipairs(K.bar3.keys) do SetBinding(key, K.bar3.command:format(i)) end
		for i, key in ipairs(K.bar2.keys) do SetBinding(key, K.bar2.command:format(K.bar2.first + i - 1)) end
		for _, m in ipairs(K.movement) do SetBinding(m.key, m.command) end
		local bad = 0
		for i, key in ipairs(K.bar3.keys) do if GetBindingAction(key) ~= K.bar3.command:format(i) then bad = bad + 1 end end
		for i, key in ipairs(K.bar2.keys) do if GetBindingAction(key) ~= K.bar2.command:format(K.bar2.first + i - 1) then bad = bad + 1 end end
		SaveBindings(ACCOUNT_BINDINGS or 1)
		if GetCurrentBindingSet and GetCurrentBindingSet() == (CHARACTER_BINDINGS or 2) then
			say("this character uses character-specific keybinds. Untick 'Character Specific Keybindings' in Key Bindings so the account-wide set is used.")
		end
		if bad > 0 then return false, bad .. " key(s) didn't take" end
		return true
	end,
}

pieces.bars = {
	label = "Bartender4", addon = "Bartender4",
	run = function()
		local BT4 = Bartender4
		if not (BT4 and BT4.db) then return false, "Bartender4 not ready" end
		BT4.db:SetProfile(PROFILE)
		-- Back to Bartender4's own defaults (no preset; this resets every module namespace too).
		-- The data holds only what differs from them, the way Bartender4 saves it.
		BT4.db:ResetProfile()
		merge(BT4.db.profile, D.Bartender4.profile)
		for name, t in pairs(D.Bartender4.namespaces) do
			local n = BT4.db:GetNamespace(name, true)
			if n then merge(n.profile, t) end
		end
		BT4:UpdateModuleConfigs()
		return true
	end,
}

pieces.chat = { label = "Prat 3.0", addon = "Prat-3.0", run = function() return aceProfile("Prat3DB", D["Prat 3.0"]) end }
pieces.quests = { label = "Questie", addon = "Questie", run = function() return aceProfile("QuestieConfig", D.Questie) end }
pieces.gather = { label = "GatherMate2", addon = "GatherMate2", run = function() return aceProfile("GatherMate2DB", D.GatherMate2) end }
pieces.tomtom = { label = "TomTom", addon = "TomTom", run = function() return aceProfile("TomTomDB", D.TomTom) end }

pieces.map = {
	label = "SexyMap", addon = "SexyMap",
	run = function()
		if type(SexyMap2DB) ~= "table" then return false, "saved variables not loaded" end
		local _, smKeys = charKeys()
		SexyMap2DB.global = copy(D.SexyMap)
		for _, key in ipairs(smKeys) do SexyMap2DB[key] = "global" end
		return true
	end,
}
ns.pieces = pieces

local function run(id)
	local p = pieces[id]
	if p.addon and not IsLoaded(p.addon) then
		say(p.label .. ": not installed or not enabled, skipped.")
		return false
	end
	local ok, res, why = pcall(p.run)
	if ok and res then
		say(p.label .. ": done.")
		return true
	end
	say(p.label .. ": |cffff7700failed|r (" .. tostring(ok and why or res) .. ").")
	return false
end

StaticPopupDialogs["SCHIZZLES_WARRIOR_RELOAD"] = {
	text = "Schizzle's Warrior settings applied. Reload the UI now to finish?",
	button1 = RELOADUI or "Reload", button2 = LATER or "Later",
	OnAccept = function() ReloadUI() end,
	timeout = 0, whileDead = true, hideOnEscape = true,
}

local function apply(ids)
	if InCombatLockdown() then
		say("leave combat first.")
		return
	end
	local any = false
	for _, id in ipairs(ids) do
		if run(id) then any = true end
	end
	SchizzlesWarriorSetupCharDB = SchizzlesWarriorSetupCharDB or {}
	SchizzlesWarriorSetupCharDB.applied = VERSION
	if any then StaticPopup_Show("SCHIZZLES_WARRIOR_RELOAD") end
end
ns.apply = apply

StaticPopupDialogs["SCHIZZLES_WARRIOR_FIRST"] = {
	text = "Set up Schizzle's Warrior on this character?\n\nKeybinds, Bartender4 bars, Prat chat, SexyMap minimap, Questie, GatherMate2 and TomTom. Each addon gets a new \"Schizzle's Warrior\" profile; your old profiles are kept.",
	button1 = YES or "Yes", button2 = NO or "No",
	OnAccept = function() apply(order) end,
	OnCancel = function()
		SchizzlesWarriorSetupCharDB = SchizzlesWarriorSetupCharDB or {}
		SchizzlesWarriorSetupCharDB.applied = "skipped"
		say("skipped. Type /schizzle any time.")
	end,
	timeout = 0, whileDead = true, hideOnEscape = true,
}

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	SchizzlesWarriorSetupCharDB = SchizzlesWarriorSetupCharDB or {}
	if SchizzlesWarriorSetupCharDB.applied == nil then
		StaticPopup_Show("SCHIZZLES_WARRIOR_FIRST")
	end
end)

local aliases = { all = "all", binds = "binds", keys = "binds", bars = "bars", bt4 = "bars", chat = "chat", prat = "chat",
	map = "map", minimap = "map", quests = "quests", questie = "quests", gather = "gather", gathermate = "gather", tomtom = "tomtom" }

SLASH_SCHIZZLE1 = "/schizzle"
SlashCmdList.SCHIZZLE = function(msg)
	local cmd = aliases[(msg or ""):lower():match("^%s*(%S*)")]
	if cmd == "all" then
		apply(order)
	elseif cmd then
		apply({ cmd })
	else
		say("v" .. VERSION .. ". Commands:")
		say("/schizzle all - everything below, then reload")
		for _, id in ipairs(order) do
			local p = pieces[id]
			local state = (not p.addon or IsLoaded(p.addon)) and "" or " |cff888888(not loaded)|r"
			say("/schizzle " .. id .. " - " .. p.label .. state)
		end
	end
end
