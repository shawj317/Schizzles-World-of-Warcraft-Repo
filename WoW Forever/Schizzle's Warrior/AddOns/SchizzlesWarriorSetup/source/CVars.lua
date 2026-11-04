-- Schizzle's Warrior: console variables for WoW Forever, by Jon Shaw (Schizzle). MIT with attribution.
-- Applied by /schizzle cvars. Each one is set only if the client has it (checked with C_CVar.GetCVar first), so a
-- name Forever doesn't know is listed as skipped rather than failing.
return {
	{ name = "autoLootDefault", value = "1", why = "auto loot on (Speedy AutoLoot speeds it up)" },
	{ name = "ActionButtonUseKeyDown", value = "1", why = "abilities fire on key press, not release" },
	{ name = "cameraDistanceMaxZoomFactor", value = "2.6", why = "furthest camera zoom" },
	{ name = "nameplateShowEnemies", value = "1", why = "enemy nameplates on (Platynator, RareScanner)" },
	{ name = "showTargetOfTarget", value = "1", why = "target of target frame" },
	{ name = "UberTooltips", value = "1", why = "full spell tooltips" },
	{ name = "cooldownViewerEnabled", value = "1", why = "Blizzard's Cooldown Manager on (WeakAuras has no Forever build)" },
}
