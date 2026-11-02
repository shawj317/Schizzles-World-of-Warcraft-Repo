-- Schizzle's Warrior BetterBlizzFrames profile (v1): the settings, as a plain table.
-- Every key here is a real BetterBlizzFramesDB key on the Mists (classics/) code path;
-- verify.lua checks that against BBF's defaults and code. Anything not listed keeps
-- BBF's own default after the import.

local FONT = os.getenv("BBF_FONT") or "Fira Sans Condensed Medium" -- registered by WeakAuras

-- Aura whitelist, in BBF's current format (BBF.auraWhitelist / addOrUpdateEntry in
-- classics/gui.lua): keyed by lowercase spell name, so one entry covers every rank and
-- spell ID of that debuff, on MoP Classic and on WoW Forever.
--   important = coloured glow while the debuff is up, pandemic = red glow when it is
--   about to fall off (last 5 s), enlarged = bigger icon, onlyMine = hide other players'.
local GREEN, RED, GOLD = {0, 1, 0, 1}, {1, 0.2, 0.2, 1}, {1, 0.82, 0, 1}
local function entry(name, flags, comment)
  local e = { name = name, color = flags.color or GREEN, comment = comment }
  e.important, e.pandemic, e.enlarged, e.onlyMine = flags.important, flags.pandemic, flags.enlarged, flags.onlyMine
  return e
end
local list = {
  -- name                         flags                                                       comment (spell IDs, for reference)
  entry("Colossus Smash",        { important = true, enlarged = true, onlyMine = true, color = RED }, "MoP 86346"),
  entry("Demoralizing Shout",    { important = true, color = GOLD },                         "MoP 1160"),
  entry("Deep Wounds",           { pandemic = true, onlyMine = true },                       "MoP 115767"),
  entry("Weakened Armor",        { pandemic = true },                                        "MoP 113746, from Sunder Armor / Devastate"),
  entry("Sunder Armor",          { pandemic = true },                                        "Forever / pre-Mists name of the armor debuff"),
  entry("Weakened Blows",        { pandemic = true },                                        "MoP 115798, from Thunder Clap"),
  entry("Thunder Clap",          { pandemic = true },                                        "Forever / pre-Mists name of the Thunder Clap debuff"),
  entry("Hamstring",             { pandemic = true },                                        "MoP 1715"),
  entry("Rend",                  { pandemic = true, onlyMine = true },                       "Forever; Rend was removed from Warriors in Mists"),
  entry("Piercing Howl",         {},                                                         "MoP 12323"),
  entry("Mortal Wounds",         {},                                                         "MoP 115804, from Mortal Strike"),
  entry("Mortal Strike",         {},                                                         "Forever / pre-Mists name of the healing debuff"),
  entry("Physical Vulnerability",{},                                                         "MoP 81326, from Colossus Smash"),
}
local whitelist = {}
for _, e in ipairs(list) do whitelist[string.lower(e.name)] = e end

return {
  version = "1.00", -- BBF's DB version (addonVersion in classics/BetterBlizzFrames.lua); real exports always carry it

  -- Look: dark mode, class colours, realm names hidden
  darkModeUi = true,                  -- Dark Mode (unit frames, castbars, auras, action bars: BBF defaults on)
  darkModeMinimap = true,             -- dark minimap border too
  darkModeNameplateResource = false,  -- nameplates belong to Plater
  classColorFrames = true,            -- Class Color Health
  classColorTargetNames = true,       -- Class Color Names
  hideTargetReputationColor = true,   -- no coloured name background on target
  hideFocusReputationColor = true,    -- ... or focus
  removeRealmNames = true,            -- Hide Realm (BBF default, kept on)
  formatStatusBarText = true,         -- 245k instead of 245000

  -- Font: Fira Sans Condensed Medium, the same font as the WeakAuras, Plater and Details! pieces
  changeUnitFrameFont = true,     unitFrameFont = FONT,      unitFrameFontSize = 11,
  changeUnitFrameValueFont = true, unitFrameValueFont = FONT, unitFrameValueFontSize = 10,
  changePartyFrameFont = true,    partyFrameFont = FONT,     partyFrameFontSize = 10, partyFrameStatusFontSize = 10,

  -- Combat indicator (player, target, focus: BBF defaults)
  combatIndicator = true,

  -- Castbars: party castbars on, timers on, Pummel-ready icon on target/focus castbars
  showPartyCastbar = true,
  partyCastBarTimer = true,
  targetCastBarTimer = true,
  focusCastBarTimer = true,
  castBarInterruptIconEnabled = true,

  -- Clutter
  hidePlayerRestAnimation = true,
  hidePlayerRestGlow = true,
  hideCombatGlow = true,       -- the red pulsing player frame; the combat indicator covers it
  hidePvpIcon = true,
  hidePrestigeBadge = true,
  hidePlayerGuideIcon = true,
  hideLevelText = true,        -- level text only at max level
  hideTargetToTDebuffs = true,
  hideFocusToTDebuffs = true,
  hidePartyFrameTitle = true,

  -- Target and focus debuffs: yours plus the Warrior whitelist, with glows
  playerAuraFiltering = true,          -- "Enable Aura Settings" (master switch)
  enablePlayerBuffFiltering = false,   -- leave your own buff frame to Blizzard
  targetdeBuffFilterOnlyMe = true,
  targetdeBuffFilterWatchList = true,
  focusdeBuffFilterOnlyMe = true,
  focusdeBuffFilterWatchList = true,
  customPandemicAuraSorting = true,    -- debuffs about to fall off sort first
  auraWhitelist = whitelist,
}
