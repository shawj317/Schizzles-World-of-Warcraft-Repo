-- Schizzle's Warrior Setup: action-bar keybind map for Essentials Main labels.
-- Runs unsandboxed (real _G). Primary path is Bartender4 BT4Button frames (Jon uses BT4);
-- Blizzard ActionButton / MultiBar* are fallbacks only.
-- Exposes _G.SchizzlesWarriorSetup_Keys[spellName|spellID] = short key text (e.g. "s-Q", "2").
local _, ns = ...

local KEYS = {}
_G.SchizzlesWarriorSetup_Keys = KEYS

-- Spells Essentials Main / Utility care about (rank-1 IDs; names resolve every rank).
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

-- Bartender / Blizzard style shorten: SHIFT-Q -> s-Q, CTRL-BUTTON4 -> c-M4, ALT-E -> a-E.
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
	-- LAB hides range as RANGE_INDICATOR / ●; never treat those as binds.
	if RANGE_INDICATOR and t == RANGE_INDICATOR then return end
	if t == "●" or t == "*" or t == "•" or t == "--" then return end
	return t
end

local function bindingCmdsForButton(name, slot)
	local cmds = {}
	if name and name:find("^BT4Button") then
		cmds[#cmds + 1] = "CLICK " .. name .. ":Keybind"
		cmds[#cmds + 1] = "CLICK " .. name .. ":LeftButton"
	end
	if slot then
		if slot >= 1 and slot <= 12 then
			cmds[#cmds + 1] = "ACTIONBUTTON" .. slot
		elseif slot >= 13 and slot <= 24 then
			-- Bar 2: Setup binds CLICK BT4Button13-24:Keybind (no Blizzard mapping).
		elseif slot >= 25 and slot <= 36 then
			cmds[#cmds + 1] = "MULTIACTIONBAR3BUTTON" .. (slot - 24)
		elseif slot >= 37 and slot <= 48 then
			cmds[#cmds + 1] = "MULTIACTIONBAR4BUTTON" .. (slot - 36)
		elseif slot >= 49 and slot <= 60 then
			cmds[#cmds + 1] = "MULTIACTIONBAR2BUTTON" .. (slot - 48)
		elseif slot >= 61 and slot <= 72 then
			cmds[#cmds + 1] = "MULTIACTIONBAR1BUTTON" .. (slot - 60)
		end
		-- Always also try BT4 click binds by absolute button id (= default action id for bar N).
		cmds[#cmds + 1] = ("CLICK BT4Button%d:Keybind"):format(slot)
		cmds[#cmds + 1] = ("CLICK BT4Button%d:LeftButton"):format(slot)
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
	if btn.GetAttribute then
		a = btn:GetAttribute("action")
		if type(a) == "number" then return a end
	end
	a = btn.action
	if type(a) == "number" then return a end
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
			return sid, sid, actionType, id, false
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

-- Collect key text from one button frame. Prefer binding commands, then visible HotKey.
local function keyForButton(btn, slot)
	local name = btn.GetName and btn:GetName() or nil
	local cmds = bindingCmdsForButton(name, slot)
	local short, cmd, raw = firstBinding(cmds)
	if short then return short, "bind:" .. tostring(cmd), raw end
	local hot = hotkeyFromFontString(btn.HotKey)
	if hot then return hot, "HotKey", hot end
	return nil
end

local function noteButton(map, btn, seenSlots)
	local slot = buttonAction(btn)
	if not slot then return end
	seenSlots[slot] = true
	local spellId, name = resolveSlotSpell(slot)
	if not spellId and not name then return end
	local keyText, how = keyForButton(btn, slot)
	if keyText then remember(map, spellId, name, keyText) end
	return slot, spellId, name, keyText, how
end

-- Primary: Bartender4 BT4Button1..180 (bars 1-10 × 12; Setup uses bars 1-6).
-- Fallback: Blizzard ActionButton / MultiBar* if BT4 frames are missing.
local function rebuild()
	local map = {}
	local seenSlots = {}
	local bt4Count = 0
	for i = 1, 180 do
		local btn = _G["BT4Button" .. i]
		if btn then
			bt4Count = bt4Count + 1
			noteButton(map, btn, seenSlots)
		end
	end
	if bt4Count == 0 then
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
	end
	-- Also walk raw slots 1-180 for anything not attached to a visible button frame
	-- (stance pages / unused BT4 ids), using binding-only lookup.
	for slot = 1, 180 do
		if not seenSlots[slot] then
			local spellId, name = resolveSlotSpell(slot)
			if spellId or name then
				local short = firstBinding(bindingCmdsForButton(nil, slot))
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
	return map
end
ns.rebuildKeys = rebuild

local function diagnose()
	say("keybind diagnose v" .. (ns.VERSION or "?") .. " (Bartender4 primary)")
	local bt4 = _G.Bartender4
	local bt4Btn = 0
	for i = 1, 180 do if _G["BT4Button" .. i] then bt4Btn = bt4Btn + 1 end end
	say(("Bartender4 addon: %s; BT4Button frames: %d; LibActionButton: %s"):format(
		bt4 and "yes" or "no",
		bt4Btn,
		(LibStub and LibStub("LibActionButton-1.0", true)) and "yes" or "no"))

	rebuild()

	for _, entry in ipairs(WATCH) do
		local wantName = spellName(entry.id) or entry.name
		local lines = {}
		say(("— %s (%d → %s); map=%s"):format(entry.name, entry.id, tostring(wantName),
			tostring(KEYS[entry.id] or KEYS[wantName] or KEYS[entry.name] or "(none)")))

		for slot = 1, 180 do
			local spellId, name, actionType, id, wasSecret = resolveSlotSpell(slot)
			local match = false
			if spellId == entry.id or name == wantName or name == entry.name then match = true end
			if type(spellId) == "string" and (spellId == wantName or spellId == entry.name) then match = true end
			if match then
				local btn = _G["BT4Button" .. slot]
				local actionFromBtn = btn and buttonAction(btn)
				local cmds = bindingCmdsForButton(btn and btn.GetName and btn:GetName() or ("BT4Button" .. slot), slot)
				local bindBits = {}
				for _, cmd in ipairs(cmds) do
					local key = GetBindingKey(cmd)
					bindBits[#bindBits + 1] = ("%s=%s"):format(cmd, key and tostring(key) or "nil")
				end
				local hot = btn and hotkeyFromFontString(btn.HotKey)
				say(("  slot %d type=%s id=%s secret=%s btnAction=%s HotKey=%s"):format(
					slot, tostring(actionType), tostring(id), tostring(wasSecret),
					tostring(actionFromBtn), tostring(hot)))
				say("    binds: " .. table.concat(bindBits, " | "))
				lines[#lines + 1] = slot
			end
		end
		if #lines == 0 then
			say("  (not on any action slot 1-180)")
		end
	end
	say("done. If Main labels are still blank after /reload, paste this output.")
end
ns.diagnoseKeys = diagnose

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UPDATE_BINDINGS")
f:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
f:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("PLAYER_TALENT_UPDATE")
f:SetScript("OnEvent", function(_, event)
	if event == "ACTIONBAR_SLOT_CHANGED" or event == "UPDATE_BINDINGS" or event == "ACTIONBAR_PAGE_CHANGED" then
		if InCombatLockdown and InCombatLockdown() then
			f.dirty = true
			return
		end
	end
	if event == "PLAYER_REGEN_ENABLED" and not f.dirty then
		-- still refresh; binds can change as you leave combat
	end
	f.dirty = false
	rebuild()
end)

-- Export helpers for sim / harness.
ns.keysWatch = WATCH
ns.keysShorten = shorten
ns.keysForButton = keyForButton
ns.keysButtonAction = buttonAction
ns.keysResolveSlotSpell = resolveSlotSpell
ns.keysHotkeyFromFontString = hotkeyFromFontString
ns.keysBindingCmdsForButton = bindingCmdsForButton
