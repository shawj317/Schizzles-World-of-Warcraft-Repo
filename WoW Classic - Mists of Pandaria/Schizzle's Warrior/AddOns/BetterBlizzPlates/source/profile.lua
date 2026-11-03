-- Schizzle's Warrior BetterBlizzPlates profile (v2): the settings, as a plain table.
-- Every key here is a real BetterBlizzPlatesDB key on the Mists (classics/) code path;
-- verify.lua checks that against BBP's defaults and code. Anything not listed keeps
-- BBP's own default after the import.

local FONT = os.getenv("BBP_FONT") or "Fira Sans Condensed Medium" -- registered by WeakAuras
local TEXTURE = "Minimalist" -- flat bar texture that ships with BBP

-- Aura whitelist, in BBP's format (classics/gui.lua addOrUpdateEntry, modules/auras.lua
-- GetAuraDetails): an array of entries matched by name when there is no id, so one entry
-- covers every rank and spell ID of that debuff, on MoP Classic and on WoW Forever.
-- The same list and glows as the BetterBlizzFrames Warrior profile.
--   important = coloured glow while the debuff is up (colour = entryColors.text),
--   pandemic = red glow when it is about to fall off, enlarged = bigger icon,
--   onlyMine = hide other players' copies.
local GREEN = { r = 0, g = 1, b = 0, a = 1 }
local RED = { r = 1, g = 0.2, b = 0.2, a = 1 }
local GOLD = { r = 1, g = 0.82, b = 0, a = 1 }
local function entry(name, flags, comment)
  return {
    name = name, comment = comment,
    flags = { important = flags.important or false, pandemic = flags.pandemic or false,
              enlarged = flags.enlarged or false, onlyMine = flags.onlyMine or false },
    entryColors = { text = flags.color or GREEN },
  }
end
local whitelist = {
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

return {
  version = "1.00",   -- BBP's DB version (addonVersion in classics/BetterBlizzPlates.lua); real exports carry it
  mopUpdated = true,  -- skips BBP's one-time "MoP update" totem-list popup

  -- Font and bar texture
  useCustomFont = true, customFont = FONT,
  useCustomTextureForBars = true, customTexture = TEXTURE, customTextureFriendly = TEXTURE,

  -- Dark look: near-black solid bar background, black borders, white border on your target
  changeNpHpBgColor = true, changeNpHpBgColorSolid = true, npBgColorRGB = { 0.06, 0.06, 0.06, 0.9 },
  changeNameplateBorderColor = true, npBorderTargetColor = true, -- target white, the rest black (BBP defaults)

  -- Class colours on enemy players; NPCs keep Blizzard's red/yellow reaction colours
  enemyHealthBarColor = true, enemyHealthBarColorClass = true,
  enemyHealthBarColorHostile = false, enemyHealthBarColorNeutral = false,
  nameplateShowClassColor = "1", -- the CVar BBP keeps in sync with the class row
  classColorRowsMigrated = true, -- already in BBP's current colour-row format

  -- Size: 136 wide, 14 tall health bars
  nameplateEnemyWidth = 136,
  nameplateGeneralHpHeight = 14,

  -- Enemy name sits on its own row above the health text (v2). Blizzard draws the
  -- "240 100%" health text itself: with the Legacy, Thin, Health Focus and Cast Focus
  -- nameplate styles it sits just above the bar on the right, 2 px up and one 15 px
  -- line tall at the Large size (12 px font x 1.25). BBP centres the name at the bar
  -- top + 5, so the two collided. Lifting the name 16 px puts its bottom at +21, clear
  -- of the health text, and the debuff row goes up by the same 16 so it keeps its gap
  -- above the name. With the Classic, Modern or Block styles the health text is inside
  -- the bar, so the only difference there is a slightly taller plate.
  fakeNameYPos = 16,
  nameplateAurasYPos = 16,

  -- Threat colours, role-aware (tank = Protection spec): in dungeons/raids and the open
  -- world (not BGs/arenas), only on mobs that are in combat. Tank: green = you have it, orange = losing it,
  -- red = not on you, blue = another tank has it. DPS: red = it is hitting you,
  -- orange = it is targeting you, green = safe.
  enemyColorThreat = true, threatColorAlwaysOn = true, enemyColorThreatCombatOnly = true,
  tankOffTankAggroColorRGB = { 0.25, 0.55, 1, 1 },
  dpsOrHealTargetAggroColorRGB = { 1, 0.47, 0, 1 },
  threatPercent = true,           -- threat % to the right of the bar

  -- Castbars: gold = interruptible, cyan = channel, grey = can't be interrupted (BBP default),
  -- bronze = Pummel won't be ready in time, orange + green spark = Pummel comes back mid-cast
  enableCastbarCustomization = true,
  castBarHeight = 12,
  showNameplateCastbarTimer = true,
  interruptedByIndicator = true,  -- shows who interrupted the cast
  castBarRecolor = true,
  castBarCastColor = { 1, 0.82, 0 },
  castBarChanneledColor = { 0, 0.8, 1 },
  castBarRecolorInterrupt = true,
  castBarNoInterruptColor = { 0.72, 0.45, 0.2 },
  castBarDelayedInterruptColor = { 1, 0.55, 0.1 },

  -- Execute: health % on the bar below 20%
  executeIndicator = true, executeIndicatorThreshold = 20,
  executeIndicatorShowDecimal = false, executeIndicatorPercentSymbol = true,

  -- Enemy debuffs: yours plus the Warrior whitelist, with glows
  otherNpdeBuffEnable = true,
  otherNpdeBuffFilterWatchList = true,
  otherNpdeBuffFilterOnlyMe = true,
  otherNpdeBuffFilterBlizzard = false,
  auraWhitelist = whitelist,

  -- Clutter
  hideLevelFrame = true,
  hideEliteDragon = true,
  removeRealmNames = true,
}
