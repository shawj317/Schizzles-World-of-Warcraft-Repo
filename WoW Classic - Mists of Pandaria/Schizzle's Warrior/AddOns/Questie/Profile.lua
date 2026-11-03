-- Schizzle's Warrior: Questie profile (v1) by Jon Shaw (Schizzle). MIT with attribution.
-- Applied by the SchizzlesWarriorSetup helper (/schizzle quests) as an AceDB profile named
-- "Schizzle's Warrior" in QuestieConfig. Keys are Questie's own profile keys
-- (Modules/Options/QuestieOptionsDefaults.lua); anything not listed keeps Questie's default.
local FONT = "Fira Sans Condensed Medium"

return {
	profile = {
		-- Map and minimap icons a little smaller, so they don't bury the square minimap.
		globalScale = 0.6,
		globalMiniMapScale = 0.6,
		globalTownsfolkScale = 0.55,
		globalMiniMapTownsfolkScale = 0.6,
		alwaysGlowMap = true,
		alwaysGlowMinimap = false,
		-- Quest tracker: Fira, a charcoal backdrop with a border, quest levels shown,
		-- shrinks itself in dungeons and raids.
		trackerEnabled = true,
		trackerFontHeader = FONT,
		trackerFontZone = FONT,
		trackerFontQuest = FONT,
		trackerFontObjective = FONT,
		trackerFontSizeHeader = 13,
		trackerFontSizeZone = 12,
		trackerFontSizeQuest = 12,
		trackerFontSizeObjective = 11,
		trackerFontOutline = "",
		trackerBackdropEnabled = true,
		trackerBorderEnabled = true,
		trackerBackdropFader = true,
		trackerBackdropColor = { r = 0.06, g = 0.06, b = 0.06, a = 0.75 },
		trackerShowQuestLevel = true,
		trackerColorObjectives = "minimal",
		trackerSortObjectives = "byZone",
		minimizeTrackerInCombat = false,
		minimizeTrackerInInstances = true,
		trackerLocked = true,
		-- At most 30% of the screen tall, so it ends above the Details! windows.
		trackerHeightRatio = 0.3,
		-- Tooltips show the quest level; Shift turns in/accepts when the auto options are on.
		enableTooltipsQuestLevel = true,
		-- Party chat: announce quest items and objectives (Questie's defaults), not every accept.
		questAnnounceChannel = "party",
		questAnnounceObjectives = true,
		questAnnounceItems = true,
	},
}
