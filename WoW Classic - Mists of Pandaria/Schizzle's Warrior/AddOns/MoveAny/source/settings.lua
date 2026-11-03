-- Schizzle's Warrior MoveAny settings: what the README tells you to tick or untick,
-- with each element's key, its default in settings.lua and its English label
-- (checked by verify.lua against MoveAny's own source).
local L = "locale/enUS.lua"
local S = "settings.lua"
return {
  folder = "MoveAny",
  requireFiles = { S, L, "moveframes.lua" },
  tocs = {
    { file = "MoveAny_Mists.toc", interface = "50504" },   -- MoP Classic 5.5.x
    { file = "MoveAny_Camelot.toc", interface = "16001" }, -- WoW Forever
  },
  options = {
    -- untick: Bartender4 already owns the extra action button
    { key = 'AddCheckBox("ExtraActionBarFrame", true', keyFile = S, label = "Extra Actionbar (Clickable Button)", labelFile = L, set = false },
    -- tick: these are the frames MoveAny moves in this kit
    { key = 'AddCheckBox("LOSSOFCONTROLFRAME", false)', keyFile = S, label = "Loss of Control Frame", labelFile = L, set = true },
    { key = 'AddCheckBox("GAMETOOLTIP", false', keyFile = S, label = '"Tooltip"', labelFile = L, readmeLabel = "**Tooltip**", set = true },
    -- keep the defaults
    { key = 'AddCheckBox("MOVEFRAMES", true)', keyFile = S, label = "Move Windows", labelFile = L, set = true },
    { key = 'AddCheckBox("SAVEFRAMEPOSITION", true)', keyFile = S, label = "Save Frame Position", labelFile = L, set = true },
    { key = 'AddCheckBox("SAVEFRAMESCALE", true)', keyFile = S, label = "Save Frame Scale", labelFile = L, set = true },
    -- leave off: another addon owns each of these
    { key = 'AddCheckBox("ACTIONBARS", false)', keyFile = S, label = "Actionbars 1 + 5 + 6", labelFile = L, set = false },
    { key = 'AddCheckBox("PETBAR", false', keyFile = S, label = "Pet Bar", labelFile = L, set = false },
    { key = 'AddCheckBox("STANCEBARANCHOR", false', keyFile = S, label = "Stance Bar Anchor", labelFile = L, set = false },
    { key = 'AddCheckBox("MICROMENU", false)', keyFile = S, label = "Micro Menu", labelFile = L, set = false },
    { key = 'AddCheckBox("BAGS", false)', keyFile = S, label = '"Bags"', labelFile = L, readmeLabel = "**Bags**", set = false },
    { key = 'AddCheckBox("PLAYERFRAME", false)', keyFile = S, label = "Player Frame", labelFile = L, set = false },
    { key = 'AddCheckBox("TARGETFRAME", false', keyFile = S, label = "Target Frame", labelFile = L, set = false },
    { key = 'AddCheckBox("CASTINGBAR", false', keyFile = S, label = "Casting Bar", labelFile = L, set = false },
    { key = 'AddCheckBox("BUFFS", false', keyFile = S, label = '"Buffs"', labelFile = L, readmeLabel = "**Buffs**", set = false },
    { key = 'AddCheckBox("MINIMAP", false)', keyFile = S, label = "Mini Map", labelFile = L, set = false },
    { key = 'AddCheckBox("CHAT", false', keyFile = S, label = "Chatframe %d", labelFile = L, readmeLabel = "**Chatframe**", set = false },
  },
  extraChecks = {
    { file = S, text = 'Bartender4DB["namespaces"][element]["profiles"][name .. " - " .. realm]', why = "MoveAny only sees a Bartender4 bar in a per-character profile, so it can't tell the shared kit profile is using the extra action button" },
    { file = L, text = '"LID_RELOADANDREOPEN", "Reload & Reopen"', why = "the settings window has a Reload & Reopen button" },
  },
}
