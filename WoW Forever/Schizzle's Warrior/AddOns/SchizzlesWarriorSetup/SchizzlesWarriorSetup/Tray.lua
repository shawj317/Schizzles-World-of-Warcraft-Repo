-- Schizzle's XP & Rep Tray for WoW Forever, by Jon Shaw (Schizzle). MIT with attribution.
-- WeakAuras has no Forever build, so the v1.3 tray is drawn here instead: three 500 x 10 bars, 2 px apart, whose
-- top-right corner sits 4 px in from the right edge and 38 px up, right under the side-by-side Details! windows.
-- Top to bottom: experience (blue, with completed-quest XP in green and rested XP in purple in front of it), the
-- reputation picked with "Show as Experience Bar", and guild reputation. A bar with nothing to show is hidden and
-- the ones below it move up, so the top edge never moves. Hover a bar for the details.
-- Only out-of-combat friendly data is read (XP, quests, reputation), none of the combat values Forever keeps secret.
local _, ns = ...

local BAR_W, BAR_H, GAP, MARGIN, BARS = 500, 10, 2, 4, 3
local TOP_Y = MARGIN + BAR_H * BARS + GAP * (BARS - 1)
local XP_BLUE, QUEST_GREEN, RESTED_PURPLE = { 0.25, 0.5, 1, 1 }, { 0.25, 0.8, 0.3, 0.6 }, { 0.6, 0.35, 0.9, 0.6 }
local CHARCOAL, BRONZE = { 0.06, 0.06, 0.06, 0.85 }, { 0.72, 0.45, 0.2, 0.9 }
local STANDING = {
	{ 0.8, 0.13, 0.13 }, { 0.8, 0.13, 0.13 }, { 1, 0.47, 0 }, { 1, 0.82, 0 },
	{ 0.25, 0.7, 0.25 }, { 0.1, 0.65, 0.5 }, { 0.15, 0.6, 0.8 }, { 0.65, 0.4, 0.95 },
}
local LABELS = { "Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted" }
local FIRA = "Interface\\AddOns\\SchizzlesWarriorSetup\\Media\\FiraSansCondensed-Medium.ttf"
local WHITE = "Interface\\Buttons\\WHITE8X8"

local function fmt(n)
	if type(BreakUpLargeNumbers) == "function" then return BreakUpLargeNumbers(n) end
	return tostring(n)
end
local function pctOf(v, total) return string.format("%.1f%%", v / total * 100) end

-- A value Forever hides from addons can't be compared or formatted, so any such read just skips the update.
local function readable(...)
	if type(issecretvalue) ~= "function" then return true end
	for i = 1, select("#", ...) do
		if issecretvalue((select(i, ...))) then return false end
	end
	return true
end

local function standingLabel(reaction)
	return _G["FACTION_STANDING_LABEL" .. reaction] or LABELS[reaction] or ""
end

-- Experience --------------------------------------------------------------------------------------------------
local function questXP()
	local quest, nq = 0, 0
	if not (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo and type(GetQuestLogRewardXP) == "function") then
		return 0, 0
	end
	for i = 1, C_QuestLog.GetNumQuestLogEntries() or 0 do
		local info = C_QuestLog.GetInfo(i)
		if info and not info.isHeader and info.questID and info.questID > 0 then
			local ready = C_QuestLog.ReadyForTurnIn and C_QuestLog.ReadyForTurnIn(info.questID)
			if ready then
				local x = GetQuestLogRewardXP(info.questID)
				if type(x) == "number" and x > 0 then quest, nq = quest + x, nq + 1 end
			end
		end
	end
	return quest, nq
end

local function xpState()
	local lvl = UnitLevel("player") or 0
	local cap = 60
	if type(GetMaxLevelForPlayerExpansion) == "function" then
		local m = GetMaxLevelForPlayerExpansion()
		if type(m) == "number" and m > 0 then cap = m end
	end
	if lvl >= cap or (type(IsXPUserDisabled) == "function" and IsXPUserDisabled()) then return nil end
	local total, cur, rested = UnitXPMax("player") or 0, UnitXP("player") or 0, GetXPExhaustion() or 0
	if not readable(total, cur, rested) or total <= 0 then return nil end
	local quest, nq = questXP()
	local left = "Level " .. lvl
	if rested > 0 then left = left .. string.format("   Rested %d%%", math.floor(rested / total * 100 + 0.5)) end
	local right = string.format("%s / %s   %.1f%%", fmt(cur), fmt(total), cur / total * 100)
	if quest > 0 then right = right .. "   +" .. fmt(quest) .. " quest" end
	local tip = { { "Experience", fmt(cur) .. " / " .. fmt(total) .. "  (" .. pctOf(cur, total) .. ")" },
		{ "To level " .. (lvl + 1), fmt(total - cur) .. "  (" .. pctOf(total - cur, total) .. ")" },
		{ "Rested", rested > 0 and (fmt(rested) .. "  (" .. pctOf(rested, total) .. " of the level)") or "none" } }
	if quest > 0 then
		tip[#tip + 1] = { "Completed quests", "+" .. fmt(quest) .. "  (" .. nq .. (nq == 1 and " quest)" or " quests)") }
		local after = cur + quest
		if after >= total then tip[#tip + 1] = { "After turn-ins", "level " .. (lvl + 1) .. " +" .. fmt(after - total) }
		else tip[#tip + 1] = { "After turn-ins", fmt(after) .. " / " .. fmt(total) .. "  (" .. pctOf(after, total) .. ")" } end
	end
	return { value = cur, total = total, quest = quest, rested = rested, left = left, right = right,
		title = "Level " .. lvl, tip = tip, color = XP_BLUE }
end

-- Reputation ----------------------------------------------------------------------------------------------------
local function repFrom(d, nameOverride, tipLabel)
	local name, reaction, lo, hi, val, fid = d.name, d.reaction, d.currentReactionThreshold, d.nextReactionThreshold, d.currentStanding, d.factionID
	if not name or name == "" or type(reaction) ~= "number" then return nil end
	if not readable(lo, hi, val) then return nil end
	name = nameOverride or name
	local label, tier, maxed, friend = standingLabel(reaction), reaction, false, false
	if fid and C_GossipInfo and C_GossipInfo.GetFriendshipReputation then
		local f = C_GossipInfo.GetFriendshipReputation(fid)
		if type(f) == "table" and (f.friendshipFactionID or 0) > 0 then
			label, tier, friend = f.reaction or label, 5, true
			if f.nextThreshold then lo, hi, val = f.reactionThreshold, f.nextThreshold, f.standing
			else lo, hi, val, maxed = 0, 1, 1, true end
		end
	end
	lo, hi, val = lo or 0, hi or 0, val or 0
	local total, cur = hi - lo, val - lo
	if total <= 0 then total, cur, maxed = 1, 1, true end
	cur = math.max(0, math.min(cur, total))
	local right = maxed and label or string.format("%s / %s   %.1f%%", fmt(cur), fmt(total), cur / total * 100)
	local tip = { { friend and "Friendship rank" or tipLabel, label } }
	if maxed then
		tip[#tip + 1] = { "Progress", friend and "highest rank" or "maxed" }
	else
		local nextLabel = friend and "next rank" or (_G["FACTION_STANDING_LABEL" .. (reaction + 1)] or LABELS[reaction + 1] or "next standing")
		tip[#tip + 1] = { "Progress", fmt(cur) .. " / " .. fmt(total) .. "  (" .. pctOf(cur, total) .. ")" }
		tip[#tip + 1] = { "To " .. nextLabel, fmt(total - cur) .. "  (" .. pctOf(total - cur, total) .. ")" }
	end
	return { value = cur, total = total, left = name .. "   " .. label, right = right, title = name, tip = tip,
		color = STANDING[tier] or STANDING[4], factionID = fid }
end

-- Last faction that gave reputation (chat / UPDATE_FACTION). Used when nothing is watched yet so the
-- bar still has something to show at low levels, and to auto-watch that faction when the API allows.
local lastRep = { factionID = nil, name = nil }

local function factionDataByID(fid)
	if not fid or fid == 0 or not readable(fid) then return nil end
	if C_Reputation and type(C_Reputation.GetFactionDataByID) == "function" then
		local d = C_Reputation.GetFactionDataByID(fid)
		if type(d) == "table" and d.factionID and d.factionID ~= 0 then return d end
	end
	if type(GetFactionInfoByID) == "function" then
		local name, _desc, standingID, barMin, barMax, barValue, _aw, _ct, _ih, _ic, _hr, _iw, _ich, factionID = GetFactionInfoByID(fid)
		if name and name ~= "" and type(standingID) == "number" and readable(barMin, barMax, barValue) then
			return {
				factionID = factionID or fid, name = name, reaction = standingID,
				currentReactionThreshold = barMin, nextReactionThreshold = barMax, currentStanding = barValue,
			}
		end
	end
end

-- Classic Era 1.15+ / Forever may expose either API. Prefer the table form; fall back to the multi-return one.
local function watched()
	if C_Reputation and type(C_Reputation.GetWatchedFactionData) == "function" then
		local d = C_Reputation.GetWatchedFactionData()
		if type(d) == "table" and d.factionID and d.factionID ~= 0 and readable(d.factionID) then return d end
	end
	if type(GetWatchedFactionInfo) == "function" then
		local name, reaction, lo, hi, val, fid = GetWatchedFactionInfo()
		if name and name ~= "" and type(reaction) == "number" and fid and fid ~= 0 and readable(lo, hi, val, fid) then
			return {
				factionID = fid, name = name, reaction = reaction,
				currentReactionThreshold = lo, nextReactionThreshold = hi, currentStanding = val,
			}
		end
	end
end

local function setWatchedFaction(fid)
	if not fid or fid == 0 or not readable(fid) then return false end
	if C_Reputation and type(C_Reputation.SetWatchedFactionByID) == "function" then
		local ok = pcall(C_Reputation.SetWatchedFactionByID, fid)
		return ok and true or false
	end
	-- Older clients: find the faction index and SetWatchedFactionIndex.
	if type(SetWatchedFactionIndex) ~= "function" then return false end
	local getNum = (C_Reputation and C_Reputation.GetNumFactions) or GetNumFactions
	local getByIndex = C_Reputation and C_Reputation.GetFactionDataByIndex
	if type(getNum) ~= "function" then return false end
	local n = getNum()
	if type(n) ~= "number" or not readable(n) then return false end
	for i = 1, n do
		local id
		if type(getByIndex) == "function" then
			local d = getByIndex(i)
			id = type(d) == "table" and d.factionID or nil
		elseif type(GetFactionInfo) == "function" then
			id = select(14, GetFactionInfo(i))
		end
		if id == fid and readable(id) then
			local ok = pcall(SetWatchedFactionIndex, i)
			return ok and true or false
		end
	end
	return false
end

local function rememberFaction(fid, name)
	if not fid or fid == 0 or not readable(fid) then return end
	lastRep.factionID = fid
	if name and name ~= "" and readable(name) then lastRep.name = name end
	-- Auto-watch when the player has nothing selected (common at level 10).
	if not watched() then setWatchedFaction(fid) end
end

local function noteFactionGain(msg)
	-- "Reputation with Stormwind increased by 25." / similar locales: pull a known faction name from the message.
	if type(msg) ~= "string" or msg == "" then return end
	local getNum = (C_Reputation and C_Reputation.GetNumFactions) or GetNumFactions
	local getByIndex = C_Reputation and C_Reputation.GetFactionDataByIndex
	if type(getNum) ~= "function" then return end
	local n = getNum()
	if type(n) ~= "number" or not readable(n) then return end
	for i = 1, n do
		local name, fid
		if type(getByIndex) == "function" then
			local d = getByIndex(i)
			if type(d) == "table" then name, fid = d.name, d.factionID end
		elseif type(GetFactionInfo) == "function" then
			local a, _, _, _, _, _, _, _, isHeader, _, _, _, _, id = GetFactionInfo(i)
			if not isHeader then name, fid = a, id end
		end
		if name and fid and readable(name, fid) and msg:find(name, 1, true) then
			rememberFaction(fid, name)
			return
		end
	end
end

local function guildName()
	local g = type(GetGuildInfo) == "function" and GetGuildInfo("player") or nil
	if g and g ~= "" then return g end
end

local function repState()
	local d = watched()
	if not d and lastRep.factionID then
		d = factionDataByID(lastRep.factionID)
		if d and (not d.name or d.name == "") and lastRep.name then d.name = lastRep.name end
	end
	if not d then
		-- Placeholder so the tray still shows a reputation slot until the player watches one
		-- (or gains rep, which auto-watches). Collapses away once a real faction is available.
		return {
			value = 0, total = 1, left = "No faction watched", right = "pick in Reputation",
			title = "Reputation", tip = {
				{ "Watched faction", "none" },
				{ "Tip", "Open Reputation and 'Show as Experience Bar', or gain rep to auto-watch" },
			},
			color = STANDING[4], placeholder = true,
		}
	end
	return repFrom(d, d.factionID == 1168 and guildName() or nil, "Standing")
end

-- Guild reputation: hidden outside a guild, when the client has guild reputation off (Forever may not have it at
-- all), and when the watched faction already is the guild, so it isn't drawn twice.
local function guildState()
	if type(IsInGuild) == "function" and not IsInGuild() then return nil end
	if C_GuildInfo and C_GuildInfo.IsGuildReputationEnabled and not C_GuildInfo.IsGuildReputationEnabled() then return nil end
	local d
	if C_Reputation and type(C_Reputation.GetGuildFactionData) == "function" then
		d = C_Reputation.GetGuildFactionData()
	elseif type(GetGuildFactionInfo) == "function" then
		local name, _desc, reaction, lo, hi, val = GetGuildFactionInfo()
		if name and type(reaction) == "number" and readable(lo, hi, val) then
			d = {
				factionID = 1168, name = name, reaction = reaction,
				currentReactionThreshold = lo, nextReactionThreshold = hi, currentStanding = val,
			}
		end
	end
	if type(d) ~= "table" or not d.factionID or d.factionID == 0 then return nil end
	local w = watched()
	if w and (w.factionID == d.factionID or w.factionID == 1168) then return nil end
	return repFrom(d, guildName(), "Guild standing")
end

-- Drawing -------------------------------------------------------------------------------------------------------
local tray, bars

local function border(f)
	for _, side in ipairs({ { "TOPLEFT", "TOPRIGHT", nil, 1 }, { "BOTTOMLEFT", "BOTTOMRIGHT", nil, 1 },
		{ "TOPLEFT", "BOTTOMLEFT", 1, nil }, { "TOPRIGHT", "BOTTOMRIGHT", 1, nil } }) do
		local t = f:CreateTexture(nil, "OVERLAY")
		t:SetColorTexture(BRONZE[1], BRONZE[2], BRONZE[3], BRONZE[4])
		t:SetPoint(side[1]); t:SetPoint(side[2])
		if side[3] then t:SetWidth(side[3]) else t:SetHeight(side[4]) end
	end
end

local function text(f, point, x)
	local s = f:CreateFontString(nil, "OVERLAY")
	if not s:SetFont(FIRA, 9, "") then s:SetFontObject(GameFontHighlightSmall) end
	s:SetTextColor(1, 1, 1, 1)
	s:SetShadowColor(0, 0, 0, 1); s:SetShadowOffset(1, -1)
	s:SetPoint(point, f, point, x, 0)
	return s
end

local function overlay(bar, color)
	local t = bar:CreateTexture(nil, "ARTWORK", nil, 2)
	t:SetTexture(WHITE); t:SetVertexColor(color[1], color[2], color[3], color[4]); t:Hide()
	return t
end

local function newBar()
	local b = CreateFrame("StatusBar", nil, tray)
	b:SetSize(BAR_W, BAR_H)
	b:SetStatusBarTexture(WHITE)
	local bg = b:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(); bg:SetColorTexture(CHARCOAL[1], CHARCOAL[2], CHARCOAL[3], CHARCOAL[4])
	border(b)
	b.left, b.right = text(b, "LEFT", 4), text(b, "RIGHT", -4)
	b.quest, b.rest = overlay(b, QUEST_GREEN), overlay(b, RESTED_PURPLE)
	b:EnableMouse(true)
	b:SetScript("OnEnter", function(self)
		local s = self.state
		if not s then return end
		GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
		GameTooltip:AddLine(s.title, 1, 0.82, 0)
		for _, row in ipairs(s.tip) do GameTooltip:AddDoubleLine(row[1], row[2], 0.78, 0.61, 0.43, 1, 1, 1) end
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	b:Hide()
	return b
end

-- Green then purple in front of the blue fill, each clipped to the bar's end.
local function place(b, tex, from, width, total)
	local x0 = math.min(from, total) / total * BAR_W
	local x1 = math.min(from + width, total) / total * BAR_W
	if width <= 0 or x1 - x0 < 0.5 then tex:Hide() return end
	tex:ClearAllPoints()
	tex:SetPoint("TOPLEFT", b, "TOPLEFT", x0, 0)
	tex:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", x0, 0)
	tex:SetWidth(x1 - x0)
	tex:Show()
end

local function draw(b, s)
	b.state = s
	if not s then b:Hide() return end
	b:SetMinMaxValues(0, s.total)
	b:SetValue(s.value)
	b:SetStatusBarColor(s.color[1], s.color[2], s.color[3], 1)
	b.left:SetText(s.left)
	b.right:SetText(s.right)
	if s.quest then
		place(b, b.quest, s.value, s.quest, s.total)
		place(b, b.rest, s.value + s.quest, s.rested, s.total)
	end
	b:Show()
end

local function layout()
	local y = 0
	for _, b in ipairs(bars) do
		b:ClearAllPoints()
		if b:IsShown() then
			b:SetPoint("TOPRIGHT", tray, "TOPRIGHT", 0, -y)
			y = y + BAR_H + GAP
		end
	end
end

local function update()
	if not tray or not tray:IsShown() then return end
	local states = { xpState, repState, guildState }
	for i, fn in ipairs(states) do
		local ok, s = pcall(fn)
		draw(bars[i], ok and s or nil)
	end
	layout()
end
ns.trayUpdate = update
ns.trayRememberFaction = rememberFaction
ns.trayNoteFactionGain = noteFactionGain
ns.trayLastRep = lastRep

-- Coalesce bursts of events (QUEST_LOG_UPDATE fires a lot) into one redraw on the next frame.
local pending = false
local function queue()
	if pending then return end
	pending = true
	C_Timer.After(0, function() pending = false; update() end)
end

local EVENTS = { "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "UPDATE_EXHAUSTION", "PLAYER_UPDATE_RESTING", "PLAYER_ENTERING_WORLD",
	"QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "UPDATE_FACTION", "PLAYER_GUILD_UPDATE", "CHAT_MSG_COMBAT_FACTION_CHANGE" }

function ns.trayEnable(on)
	if on then
		if not tray then
			tray = CreateFrame("Frame", "SchizzlesXPRepTray", UIParent)
			tray:SetSize(BAR_W, TOP_Y - MARGIN)
			tray:SetPoint("TOPRIGHT", UIParent, "BOTTOMRIGHT", -MARGIN, TOP_Y)
			tray:SetFrameStrata("LOW")
			bars = { newBar(), newBar(), newBar() }
			for _, e in ipairs(EVENTS) do pcall(tray.RegisterEvent, tray, e) end
			tray:SetScript("OnEvent", function(_, event, ...)
				if event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
					noteFactionGain(...)
				elseif event == "UPDATE_FACTION" then
					-- If something is newly watched, clear the placeholder path; otherwise keep lastRep.
					local w = watched()
					if w and w.factionID then lastRep.factionID, lastRep.name = w.factionID, w.name end
				end
				queue()
			end)
		end
		tray:Show()
		queue()
	elseif tray then
		tray:Hide()
	end
end
