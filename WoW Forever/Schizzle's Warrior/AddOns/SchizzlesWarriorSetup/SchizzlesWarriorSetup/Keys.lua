-- Schizzle's Warrior Setup: action-bar keybind map for Essentials labels.
-- Unsandboxed (real _G). Bartender4 BT4Button frames are primary; Blizzard bars fallback.
-- Exposes _G.SchizzlesWarriorSetup_Keys[spellName|spellID] = short key (e.g. "s-Q", "2").
--
-- BT4 button id N = bars 1-10 × 12 (BT4Button1..120). Action slot can differ under stance/paging
-- (Warrior bar 1 pages 73-108). Bindings follow the BUTTON, not the current action:
--   bar 1 → ACTIONBUTTON1-12
--   bar 2 → CLICK BT4Button13-24:Keybind (Setup; no Blizzard mapping)
--   bar 3 → MULTIACTIONBAR3BUTTON1-12 (BT4 Blizzard-binding mode)
--   bar 4 → MULTIACTIONBAR4BUTTON*
--   bar 5 → MULTIACTIONBAR2BUTTON*
--   bar 6 → MULTIACTIONBAR1BUTTON*
local _, ns = ...

local KEYS = {}
_G.SchizzlesWarriorSetup_Keys = KEYS

-- BT4 ActionBars.lua BINDING_MAPPINGS (button bar id → Blizzard binding template).
local BINDING_BY_BAR = {
	[1] = "ACTIONBUTTON%d",
	[3] = "MULTIACTIONBAR3BUTTON%d",
	[4] = "MULTIACTIONBAR4BUTTON%d",
	[5] = "MULTIACTIONBAR2BUTTON%d",
	[6] = "MULTIACTIONBAR1BUTTON%d",
	[13] = "MULTIACTIONBAR5BUTTON%d",
	[14] = "MULTIACTIONBAR6BUTTON%d",
	[15] = "MULTIACTIONBAR7BUTTON%d",
}

local WATCH = {
	{ name = "Rend", id = 772 },
	{ name = "Heroic Strike", id = 78 },
	{ name = "Thunder Clap", id = 6343 },
	{ name = "Battle Shout", id = 6673 },
	{ name = "Bloodrage", id = 2687 },
	{ name = "Charge", id = 100 },
	{ name = "Victory Rush", id = 402927 },
	{ name = "Overpower", id = 7384 },
	{ name = "Mortal Strike", id = 12294 },
	{ name = "Slam", id = 1240193 },
	{ name = "Execute", id = 5308 },
	{ name = "Sweeping Strikes", id = 12292 },
	{ name = "Whirlwind", id = 1680 },
	{ name = "Bloodthirst", id = 23881 },
	{ name = "Shield Slam", id = 23922 },
	{ name = "Revenge", id = 6572 },
	{ name = "Sunder Armor", id = 7386 },
	{ name = "Shield Block", id = 2565 },
	{ name = "Demoralizing Shout", id = 1160 },
	{ name = "Cleave", id = 845 },
	{ name = "Intercept", id = 20252 },
	{ name = "Pummel", id = 6552 },
	{ name = "Shield Bash", id = 72 },
	{ name = "Hamstring", id = 1715 },
	{ name = "Recklessness", id = 1719 },
	{ name = "Death Wish", id = 12328 },
	{ name = "Shield Wall", id = 871 },
	{ name = "Last Stand", id = 12975 },
	{ name = "Retaliation", id = 20230 },
	{ name = "Berserker Rage", id = 18499 },
	{ name = "Intimidating Shout", id = 5246 },
	{ name = "Taunt", id = 355 },
	{ name = "Mocking Blow", id = 694 },
	{ name = "Disarm", id = 676 },
}

local function say(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cffb87333Schizzle's Warrior|r: " .. msg)
end

local function secret(v)
	return issecretvalue and issecretvalue(v) or false
end

local function spellName(id)
	if not id or id == 0 or secret(id) then return end
	if C_Spell and C_Spell.GetSpellName then
		local n = C_Spell.GetSpellName(id)
		if n and n ~= "" and not secret(n) then return n end
	end
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(id)
		if type(info) == "table" and info.name and not secret(info.name) then return info.name end
		if type(info) == "string" and not secret(info) then return info end
	end
end

local function shorten(key)
	if not key or key == "" or secret(key) then return end
	local text = key
	if GetBindingText then
		local pretty = GetBindingText(key, "KEY_", true)
		if pretty and pretty ~= "" and not secret(pretty) then text = pretty end
	end
	text = tostring(text)
	text = text:gsub("^SHIFT%-", "s-"):gsub("^CTRL%-", "c-"):gsub("^ALT%-", "a-")
	text = text:gsub("^s%-CTRL%-", "sc-"):gsub("^s%-ALT%-", "sa-"):gsub("^c%-ALT%-", "ca-")
	text = text:gsub("BUTTON", "M"):gsub("MOUSEWHEELUP", "WU"):gsub("MOUSEWHEELDOWN", "WD")
	text = text:gsub("NUMPAD", "N"):gsub("INSERT", "Ins"):gsub("DELETE", "Del")
	text = text:gsub("PAGEUP", "Pu"):gsub("PAGEDOWN", "Pd"):gsub("HOME", "Hm"):gsub("END", "End")
	return text
end

local function hotkeyFromFontString(fs)
	if not fs or not fs.GetText then return end
	local t = fs:GetText()
	if not t or t == "" or secret(t) then return end
	if RANGE_INDICATOR and t == RANGE_INDICATOR then return end
	if t == "●" or t == "*" or t == "•" or t == "--" then return end
	return t
end

local function buttonIdFromName(name)
	if not name then return end
	local n = name:match("^BT4Button(%d+)$")
	return n and tonumber(n) or nil
end

-- Bindings for a BT4 button id (1-120). Independent of current _state_action / stance page.
local function bindingCmdsForButtonId(buttonId)
	local cmds = {}
	if not buttonId or buttonId < 1 then return cmds end
	local bar = math.floor((buttonId - 1) / 12) + 1
	local idx = ((buttonId - 1) % 12) + 1
	local mapping = BINDING_BY_BAR[bar]
	if mapping then
		cmds[#cmds + 1] = mapping:format(idx)
	end
	cmds[#cmds + 1] = ("CLICK BT4Button%d:Keybind"):format(buttonId)
	cmds[#cmds + 1] = ("CLICK BT4Button%d:LeftButton"):format(buttonId)
	return cmds
end

-- Raw action-slot fallback (no button frame): stance pages 73-108 share ACTIONBUTTON1-12.
local function bindingCmdsForActionSlot(slot)
	local cmds = {}
	if not slot then return cmds end
	if slot >= 1 and slot <= 12 then
		cmds[#cmds + 1] = "ACTIONBUTTON" .. slot
		cmds[#cmds + 1] = ("CLICK BT4Button%d:Keybind"):format(slot)
		cmds[#cmds + 1] = ("CLICK BT4Button%d:LeftButton"):format(slot)
	elseif slot >= 13 and slot <= 24 then
		cmds[#cmds + 1] = ("CLICK BT4Button%d:Keybind"):format(slot)
		cmds[#cmds + 1] = ("CLICK BT4Button%d:LeftButton"):format(slot)
	elseif slot >= 25 and slot <= 36 then
		cmds[#cmds + 1] = "MULTIACTIONBAR3BUTTON" .. (slot - 24)
		cmds[#cmds + 1] = ("CLICK BT4Button%d:Keybind"):format(slot)
		cmds[#cmds + 1] = ("CLICK BT4Button%d:LeftButton"):format(slot)
	elseif slot >= 37 and slot <= 48 then
		cmds[#cmds + 1] = "MULTIACTIONBAR4BUTTON" .. (slot - 36)
		cmds[#cmds + 1] = ("CLICK BT4Button%d:Keybind"):format(slot)
		cmds[#cmds + 1] = ("CLICK BT4Button%d:LeftButton"):format(slot)
	elseif slot >= 49 and slot <= 60 then
		cmds[#cmds + 1] = "MULTIACTIONBAR2BUTTON" .. (slot - 48)
		cmds[#cmds + 1] = ("CLICK BT4Button%d:Keybind"):format(slot)
		cmds[#cmds + 1] = ("CLICK BT4Button%d:LeftButton"):format(slot)
	elseif slot >= 61 and slot <= 72 then
		cmds[#cmds + 1] = "MULTIACTIONBAR1BUTTON" .. (slot - 60)
		cmds[#cmds + 1] = ("CLICK BT4Button%d:Keybind"):format(slot)
		cmds[#cmds + 1] = ("CLICK BT4Button%d:LeftButton"):format(slot)
	elseif slot >= 73 and slot <= 120 then
		-- Stance / bonus pages shown on bar 1: binds are still ACTIONBUTTON1-12 / BT4Button1-12.
		local idx = ((slot - 1) % 12) + 1
		cmds[#cmds + 1] = "ACTIONBUTTON" .. idx
		cmds[#cmds + 1] = ("CLICK BT4Button%d:Keybind"):format(idx)
		cmds[#cmds + 1] = ("CLICK BT4Button%d:LeftButton"):format(idx)
	end
	return cmds
end

local function firstBinding(cmds)
	for _, cmd in ipairs(cmds) do
		local key = GetBindingKey(cmd)
		if key and key ~= "" and not secret(key) then
			return shorten(key), cmd, key
		end
	end
end

local function buttonAction(btn)
	if not btn then return end
	local a = btn._state_action
	if type(a) == "number" then return a end
	if type(a) == "string" then
		local n = tonumber(a)
		if n then return n end
	end
	if btn.GetAttribute then
		a = btn:GetAttribute("action")
		if type(a) == "number" then return a end
		if type(a) == "string" then
			local n = tonumber(a)
			if n then return n end
		end
	end
	a = btn.action
	if type(a) == "number" then return a end
	-- LibActionButton-1.0: some builds expose GetAction().
	if btn.GetAction then
		local ok, actionType, action = pcall(btn.GetAction, btn)
		if ok and actionType == "action" and type(action) == "number" then return action end
	end
end

local function resolveSlotSpell(slot)
	if not slot or slot < 1 then return end
	local actionType, id = GetActionInfo(slot)
	if secret(actionType) or secret(id) then
		return nil, nil, actionType, id, true
	end
	if actionType == "spell" and id then
		return id, spellName(id) or (type(id) == "string" and id or nil), actionType, id, false
	end
	if actionType == "macro" and id then
		local sid = GetMacroSpell(id)
		if secret(sid) then return nil, nil, actionType, id, true end
		if type(sid) == "number" then
			return sid, spellName(sid), actionType, id, false
		end
		if type(sid) == "string" and sid ~= "" then
			local resolved
			if C_Spell and C_Spell.GetSpellInfo then
				local info = C_Spell.GetSpellInfo(sid)
				resolved = type(info) == "table" and info.spellID or nil
			end
			return resolved or sid, sid, actionType, id, false
		end
	end
	return nil, nil, actionType, id, false
end

local function remember(map, spellId, name, keyText)
	if not keyText or keyText == "" then return end
	if type(spellId) == "number" then map[spellId] = keyText end
	if type(spellId) == "string" then map[spellId] = keyText end
	if name and name ~= "" then map[name] = keyText end
end

-- Prefer visible HotKey (BT4 already resolved Blizzard vs CLICK), then binding commands.
local function keyForButton(btn, buttonId, actionSlot)
	local hot = hotkeyFromFontString(btn and btn.HotKey)
	if hot then return hot, "HotKey", hot end
	local cmds = bindingCmdsForButtonId(buttonId)
	if #cmds == 0 and actionSlot then
		cmds = bindingCmdsForActionSlot(actionSlot)
	end
	local short, cmd, raw = firstBinding(cmds)
	if short then return short, "bind:" .. tostring(cmd), raw end
	return nil
end

local function noteButton(map, btn, seenSlots)
	local name = btn.GetName and btn:GetName() or nil
	local buttonId = buttonIdFromName(name)
	local slot = buttonAction(btn)
	if slot then seenSlots[slot] = true end
	local spellId, spellLabel
	if slot then
		spellId, spellLabel = resolveSlotSpell(slot)
	end
	if not spellId and not spellLabel then return end
	local keyText, how = keyForButton(btn, buttonId, slot)
	if keyText then remember(map, spellId, spellLabel, keyText) end
	return buttonId, slot, spellId, spellLabel, keyText, how
end

local function rebuild()
	local map = {}
	local seenSlots = {}
	local bt4Count = 0
	-- Bars 1-10 → BT4Button1..120 (Forever Classic layout; ignore pet/stance BT4 frames).
	for i = 1, 120 do
		local btn = _G["BT4Button" .. i]
		if btn then
			bt4Count = bt4Count + 1
			noteButton(map, btn, seenSlots)
		end
	end
	-- Always also walk Blizzard bar frames (covers early login before BT4 paints every bar).
	local blizzard = {
		"ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
		"MultiBarRightButton", "MultiBarLeftButton",
		"MultiBar5Button", "MultiBar6Button", "MultiBar7Button",
	}
	for _, prefix in ipairs(blizzard) do
		for i = 1, 12 do
			local btn = _G[prefix .. i]
			if btn then noteButton(map, btn, seenSlots) end
		end
	end
	-- Raw slots: stance pages 73-108 and anything without a live button frame.
	for slot = 1, 120 do
		if not seenSlots[slot] then
			local spellId, name = resolveSlotSpell(slot)
			if spellId or name then
				local short = firstBinding(bindingCmdsForActionSlot(slot))
				if short then remember(map, spellId, name, short) end
			end
		end
	end
	wipe(KEYS)
	for k, v in pairs(map) do KEYS[k] = v end
	local WA = _G.WeakAuras or _G.ForeverAuras
	if WA and WA.ScanEvents then
		pcall(WA.ScanEvents, "SCHIZZLE_KEYS")
	end
	return map, bt4Count
end
ns.rebuildKeys = rebuild

local function diagnose()
	say("keybind diagnose v" .. (ns.VERSION or "?") .. " (BT4 bars 1-10 primary)")
	local bt4 = _G.Bartender4
	local bt4Btn = 0
	for i = 1, 120 do if _G["BT4Button" .. i] then bt4Btn = bt4Btn + 1 end end
	say(("Bartender4 addon: %s; BT4Button1-120 present: %d; LibActionButton: %s"):format(
		bt4 and "yes" or "no",
		bt4Btn,
		(LibStub and LibStub("LibActionButton-1.0", true)) and "yes" or "no"))

	rebuild()

	say("--- every BT4Button with a spell ---")
	for i = 1, 120 do
		local btn = _G["BT4Button" .. i]
		if btn then
			local slot = buttonAction(btn)
			local spellId, name, actionType, id, wasSecret = resolveSlotSpell(slot)
			if spellId or name or (actionType and actionType ~= "") then
				local keyText, how = keyForButton(btn, i, slot)
				local cmds = bindingCmdsForButtonId(i)
				local bindBits = {}
				for _, cmd in ipairs(cmds) do
					local key = GetBindingKey(cmd)
					if key then bindBits[#bindBits + 1] = cmd .. "=" .. tostring(key) end
				end
				say(("BT4Button%d bar=%d idx=%d action=%s type=%s id=%s spell=%s secret=%s key=%s via=%s"):format(
					i, math.floor((i - 1) / 12) + 1, ((i - 1) % 12) + 1,
					tostring(slot), tostring(actionType), tostring(id),
					tostring(name or spellId or "?"), tostring(wasSecret),
					tostring(keyText or "(none)"), tostring(how or "-")))
				if #bindBits > 0 then
					say("  binds: " .. table.concat(bindBits, " | "))
				end
			end
		end
	end

	say("--- watched Essentials spells ---")
	for _, entry in ipairs(WATCH) do
		local wantName = spellName(entry.id) or entry.name
		say(("— %s (%d → %s); map=%s"):format(entry.name, entry.id, tostring(wantName),
			tostring(KEYS[entry.id] or KEYS[wantName] or KEYS[entry.name] or "(none)")))
	end
	say("done. Paste this if Main/Utility labels stay blank after /reload.")
end
ns.diagnoseKeys = diagnose

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("UPDATE_BINDINGS")
f:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
f:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
f:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
f:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("PLAYER_TALENT_UPDATE")
f:RegisterEvent("SPELLS_CHANGED")

local function schedule(delay)
	if C_Timer and C_Timer.After then
		C_Timer.After(delay, function()
			if InCombatLockdown and InCombatLockdown() then
				f.dirty = true
				return
			end
			rebuild()
		end)
	end
end

f:SetScript("OnEvent", function(_, event)
	if InCombatLockdown and InCombatLockdown()
		and (event == "ACTIONBAR_SLOT_CHANGED" or event == "UPDATE_BINDINGS"
			or event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_SHAPESHIFT_FORM") then
		f.dirty = true
		return
	end
	f.dirty = false
	rebuild()
	-- BT4 creates bars after PEW; refresh a few times so bars 2-6 are included.
	if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
		schedule(0.5)
		schedule(1.5)
		schedule(3)
	end
end)

-- Export helpers for sim / harness.
ns.keysWatch = WATCH
ns.keysShorten = shorten
ns.keysForButton = keyForButton
ns.keysButtonAction = buttonAction
ns.keysResolveSlotSpell = resolveSlotSpell
ns.keysHotkeyFromFontString = hotkeyFromFontString
ns.keysBindingCmdsForButtonId = bindingCmdsForButtonId
ns.keysBindingCmdsForActionSlot = bindingCmdsForActionSlot
ns.keysBindingByBar = BINDING_BY_BAR
