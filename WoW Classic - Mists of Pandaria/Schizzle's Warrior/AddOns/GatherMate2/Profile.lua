-- Schizzle's Warrior: GatherMate2 profile (v1) by Jon Shaw (Schizzle). MIT with attribution.
-- Applied by the SchizzlesWarriorSetup helper (/schizzle gather) as an AceDB profile named
-- "Schizzle's Warrior" in GatherMate2DB. Keys are GatherMate2's own profile keys
-- (GatherMate2.lua defaults); anything not listed keeps GatherMate2's default. Node data is
-- stored elsewhere and is never touched.
return {
	profile = {
		-- Smaller, slightly see-through icons so nodes don't crowd the square SexyMap minimap.
		scale = 0.85,          -- world map icons (default 1)
		miniscale = 0.7,       -- minimap icons (default 0.75)
		minimapAlpha = 0.9,    -- (default 1)
		-- Treasure always shows, other node types only when you have the profession, and the
		-- tracking circle shows within 100 yards: these are GatherMate2's defaults, kept as is.
	},
}
