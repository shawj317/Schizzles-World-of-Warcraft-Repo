-- Schizzle's Warrior Setup: Main-lane Rend land tracker for Essentials.
-- Forever closes the combat log to addons (Musca ForeverTutorial §2/§5): CLEU never fires.
-- This module still listens for CLEU (harmless if closed) and uses UNIT_SPELLCAST_SUCCEEDED
-- + rank duration + UI_ERROR_MESSAGE miss cancel + OOC aura verify as the Forever path.
-- Exposes _G.SchizzlesWarriorSetup_Rend and fires WeakAuras.ScanEvents("SCHIZZLE_REND").
local _, ns = ...

-- Forever DB2 spell IDs (build 1.60.1.70755). Period 3s; ticks → duration:
-- R1 3 ticks / 9s, R2 4 / 12s, R3 5 / 15s, R4 6 / 18s, R5–R7 7 / 21s.
local REND_DURATION = {
	[772] = 9,
	[6546] = 12,
	[6547] = 15,
	[6548] = 18,
	[11572] = 21,
	[11573] = 21,
	[11574] = 21,
}

local REND = {}
_G.SchizzlesWarriorSetup_Rend = REND

local pending -- { spellId, duration, targetGUID, at }
local expireTimer
local cleuSeen = false -- true once COMBAT_LOG_EVENT_UNFILTERED delivers a payload

local function now()
	return GetTime and GetTime() or 0
end

local function publish()
	local WA = _G.WeakAuras or _G.ForeverAuras
	if WA and WA.ScanEvents then
		pcall(WA.ScanEvents, "SCHIZZLE_REND")
	end
end

local function cancelExpire()
	if expireTimer then
		if expireTimer.Cancel then expireTimer:Cancel() end
		expireTimer = nil
	end
end

local function clear(reason)
	pending = nil
	cancelExpire()
	REND.active = false
	REND.expires = nil
	REND.duration = nil
	REND.spellId = nil
	REND.targetGUID = nil
	REND.source = reason or "clear"
	REND.cleuAvailable = cleuSeen
	publish()
end

local function land(spellId, duration, guid, source)
	pending = nil
	cancelExpire()
	REND.active = true
	REND.spellId = spellId
	REND.duration = duration
	REND.expires = now() + duration
	REND.targetGUID = guid
	REND.source = source
	REND.cleuAvailable = cleuSeen
	if C_Timer and C_Timer.NewTimer then
		expireTimer = C_Timer.NewTimer(duration + 0.05, function()
			if REND.active and REND.expires and now() >= (REND.expires - 0.01) then
				clear("expire")
			end
		end)
	end
	publish()
end

local function targetGUID()
	if UnitGUID then
		local g = UnitGUID("target")
		if g and not (issecretvalue and issecretvalue(g)) then return g end
	end
end

local function playerGUID()
	if UnitGUID then
		local g = UnitGUID("player")
		if g and not (issecretvalue and issecretvalue(g)) then return g end
	end
end

local function durationFor(spellId)
	return REND_DURATION[spellId]
end

-- Confirm a pending cast after a short miss window (Forever: CLEU miss never arrives).
local function confirmPending(source)
	if not pending then return end
	local p = pending
	pending = nil
	land(p.spellId, p.duration, p.targetGUID, source)
end

local function beginPending(spellId)
	local duration = durationFor(spellId)
	if not duration then return end
	pending = {
		spellId = spellId,
		duration = duration,
		targetGUID = targetGUID(),
		at = now(),
	}
	-- Miss / CLEU APPLY usually arrives within a few frames; Forever has no CLEU miss.
	if C_Timer and C_Timer.After then
		C_Timer.After(0.2, function()
			if pending and pending.spellId == spellId then
				confirmPending(cleuSeen and "cast-timeout-cleu" or "cast-succeeded")
			end
		end)
	else
		confirmPending("cast-succeeded")
	end
end

local function missPending(source)
	if pending then
		pending = nil
		-- Do not grey; if already grey from a prior land keep it.
		REND.lastMiss = source
		publish()
	end
end

local MISS_WORDS = {
	dodge = true, dodged = true, parry = true, parried = true,
	miss = true, missed = true, immune = true, resist = true, resisted = true,
	evade = true, evaded = true, deflect = true, deflected = true,
}

local function messageLooksLikeMiss(msg)
	if type(msg) ~= "string" or msg == "" then return end
	if issecretvalue and issecretvalue(msg) then return end
	local lower = msg:lower()
	-- Prefer messages that mention Rend when present; still accept bare "Dodged"/"Miss" right after cast.
	local aboutRend = lower:find("rend", 1, true)
	for word in lower:gmatch("%a+") do
		if MISS_WORDS[word] then
			if aboutRend or pending then return true end
		end
	end
end

-- OOC: clear a false grey if the target has no Rend from the player (Forever can read auras OOC).
local function verifyAuraOOC()
	if not REND.active then return end
	if InCombatLockdown and InCombatLockdown() then return end
	if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return end
	local guid = targetGUID()
	if not guid or (REND.targetGUID and guid ~= REND.targetGUID) then
		clear("target-mismatch-ooc")
		return
	end
	local found
	for i = 1, 40 do
		local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, "target", i, "HARMFUL")
		if not ok or not data then break end
		if issecretvalue and issecretvalue(data) then break end
		local name = data.name
		local sid = data.spellId
		local sourceUnit = data.sourceUnit
		if (name == "Rend" or REND_DURATION[sid]) and (not sourceUnit or sourceUnit == "player") then
			found = true
			break
		end
	end
	if not found then clear("ooc-no-aura") end
end

local function onCLEU()
	if not CombatLogGetCurrentEventInfo then return end
	local ok, timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
		destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, auraTypeOrMiss =
		pcall(CombatLogGetCurrentEventInfo)
	if not ok or not subevent then return end
	-- Any successful CLEU payload means the pipe is open (not Forever's closed log).
	cleuSeen = true
	REND.cleuAvailable = true
	local me = playerGUID()
	if not me or sourceGUID ~= me then return end
	local isRend = REND_DURATION[spellId] or (spellName == "Rend")
	if not isRend then return end

	if subevent == "SPELL_MISSED" then
		missPending("cleu-miss:" .. tostring(auraTypeOrMiss))
		return
	end
	if subevent == "SPELL_AURA_APPLIED" or subevent == "SPELL_AURA_REFRESH" then
		local duration = durationFor(spellId) or REND.duration or 21
		land(spellId or (pending and pending.spellId), duration, destGUID, "cleu-" .. subevent)
		return
	end
	if subevent == "SPELL_AURA_REMOVED" then
		if REND.active and (not REND.targetGUID or REND.targetGUID == destGUID) then
			clear("cleu-removed")
		end
		return
	end
	-- First DoT tick also proves a land if APPLY was missed.
	if subevent == "SPELL_PERIODIC_DAMAGE" and pending then
		local duration = durationFor(spellId) or pending.duration
		land(spellId or pending.spellId, duration, destGUID, "cleu-tick")
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("UI_ERROR_MESSAGE")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
if f.RegisterUnitEvent then
	f:RegisterUnitEvent("UNIT_FLAGS", "target")
	f:RegisterUnitEvent("UNIT_HEALTH", "target")
end

f:SetScript("OnEvent", function(_, event, ...)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		onCLEU()
		return
	end
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spellId = ...
		if unit ~= "player" then return end
		if issecretvalue and issecretvalue(spellId) then return end
		if durationFor(spellId) then beginPending(spellId) end
		return
	end
	if event == "UI_ERROR_MESSAGE" then
		local message = select(2, ...)
		if type(message) ~= "string" then message = select(1, ...) end
		if pending and messageLooksLikeMiss(message) then
			missPending("ui-error")
		end
		return
	end
	if event == "PLAYER_TARGET_CHANGED" then
		if REND.active then clear("target-change") end
		pending = nil
		return
	end
	if event == "UNIT_FLAGS" or event == "UNIT_HEALTH" then
		if REND.active and UnitExists and UnitExists("target") and UnitIsDeadOrGhost and UnitIsDeadOrGhost("target") then
			clear("target-dead")
		end
		return
	end
	if event == "PLAYER_REGEN_ENABLED" then
		verifyAuraOOC()
		return
	end
	if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
		clear("login")
	end
end)

-- Test / sim hooks.
ns.rendDurations = REND_DURATION
ns.rendClear = clear
ns.rendLand = land
ns.rendBeginPending = beginPending
ns.rendMissPending = missPending
ns.rendConfirmPending = confirmPending
ns.rendOnCLEU = onCLEU
ns.rendVerifyAuraOOC = verifyAuraOOC
ns.rendMessageLooksLikeMiss = messageLooksLikeMiss
