-- Schizzle's Warrior BetterFishing settings: what the README tells you to tick, with each
-- option's key and label in BetterFishing's Settings.lua (checked by verify.lua).
-- BetterFishing starts with every box unticked (its saved table starts empty).
local S = "Settings.lua"
local B = "BetterFishing.lua"
return {
  folder = "BetterFishing",
  requireFiles = { S, B, "Bindings.xml" },
  tocs = {
    { file = "BetterFishing.toc", interface = "50504" },  -- MoP Classic 5.5.x
    { file = "BetterFishing.toc", interface = "16001" },  -- WoW Forever, same download
  },
  options = {
    { key = 'option = "enhanceSounds"', keyFile = S, label = '"Enhance Sounds"', readmeLabel = "**Enhance Sounds**", labelFile = S, set = true },
    { key = 'option = "doubleClickEnabled"', keyFile = S, label = '"Double-click to cast"', readmeLabel = "**Double-click to cast**", labelFile = S, set = true },
    { key = 'option = "doubleClickForce"', keyFile = S, label = '"Allow double-clicking to cast while mounted"', readmeLabel = "**Allow double-clicking to cast while mounted**", labelFile = S, set = false },
  },
  extraChecks = {
    { file = B, text = "BetterFishingDB = BetterFishingDB or {};", why = "settings start empty, so every box starts unticked" },
    { file = B, text = 'if ... == "RightButton" and not IsMouseButtonDown("LeftButton") and not InCombatLockdown() then', why = "double-click casting uses the right mouse button and never works in combat" },
    { file = S, text = "BetterFishingDB.doubleClickSpeed = BetterFishingDB.doubleClickSpeed or 0.2", why = "the double-click speed starts at 0.2 s" },
    { file = S, text = "slider:Init(BetterFishingDB.enhanceSoundsScale or 1, 0, 1, 20, formatters)", why = "the Enhance Sounds slider goes from 0 to 100%" },
    { file = B, text = 'SetCVar("Sound_MasterVolume", BetterFishingDB.enhanceSoundsScale)', why = "Enhance Sounds sets the master volume to the slider while you fish" },
    { file = B, text = 'SetCVar("Sound_MusicVolume", 0)', why = "Enhance Sounds turns music off while you fish" },
    { file = "Bindings.xml", text = '<Binding name="BETTERFISHINGKEY" category="Better Fishing">', why = "a Better Fishing key binding exists in Key Bindings" },
    { file = S, text = "SLASH_BETTERFISHING1, SLASH_BETTERFISHING2 = '/bf', '/betterfishing'", why = "/bf opens the settings" },
  },
}
