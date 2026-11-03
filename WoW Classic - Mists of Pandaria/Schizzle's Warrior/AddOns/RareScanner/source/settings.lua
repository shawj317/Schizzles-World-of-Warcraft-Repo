-- Schizzle's Warrior RareScanner settings: what the README tells you to change, with each
-- option's default in RareScanner's profile defaults and its English label (checked by verify.lua).
-- RareScanner has one download per game version. Check the MoP build (default) or the
-- WoW Forever build with:  RS_BUILD=16001 lua verify.lua /path/to/Interface/AddOns
local C = "Core/Libs/RSConstants.lua"
local L = "Locales/RareScanner-enUS.lua"
return {
  folder = "RareScanner",
  requireFiles = { C, L, "RareScanner.lua", "Options/RSOptions.lua", "Options/RSGeneralOptions.lua", "Options/RSSoundOptions.lua", "Options/RSDisplayOptions.lua" },
  tocs = { { file = "RareScanner.toc", interface = os.getenv("RS_BUILD") or "50504" } },
  options = {
    -- General
    { key = "enableTomtomSupport = false,", keyFile = C, label = "\"Enable Tomtom's support\"", readmeLabel = "**Enable Tomtom's support**", labelFile = L, set = true },
    { key = "autoTomtomWaypoints = false,", keyFile = C, label = '"Enable auto replacing waypoints"', readmeLabel = "**Enable auto replacing waypoints**", labelFile = L, set = true },
    { label = '"Tomtom waypoints"', readmeLabel = "**Tomtom waypoints**", labelFile = L },
    -- Sound
    { key = 'soundChannel = "Master",', keyFile = C, label = '"Sound channel"', readmeLabel = "**Sound channel**", labelFile = L, set = "Master" },
    { key = "soundVolume = 4,", keyFile = C, label = '"Volume"', readmeLabel = "**Volume**", labelFile = L, set = 2 },
    -- Display
    { key = "scale = 0.8,", keyFile = C, label = '"Scale of the button and miniature"', readmeLabel = "**Scale of the button and miniature**", labelFile = L, set = 0.8 },
    { key = "lockPosition = false,", keyFile = C, label = '"Lock buttons position"', readmeLabel = "**Lock buttons position**", labelFile = L, set = true },
    { label = '"Launch Test"', readmeLabel = "**Launch Test**", labelFile = L },
    { key = "displayRaidWarning = true,", keyFile = C, set = true },
    { key = "flashWindowsTaskBar = true,", keyFile = C, set = true },
  },
  extraChecks = {
    { file = "Options/RSSoundOptions.lua", text = "max	= 4,", why = "the sound Volume slider goes from 1 to 4" },
    { file = "RareScanner.lua", text = 'scanner_button:SetPoint("BOTTOM", UIParent, 0, 128)', why = "the alert button starts at the bottom centre of the screen, over the action bars" },
    { file = "RareScanner.lua", text = "if (not RSConfigDB.IsLockingPosition() and not InCombatLockdown()) then", why = "the button can be dragged while unlocked and out of combat" },
    { file = "RareScanner.lua", text = "RSGeneralDB.SetButtonPositionCoordinates(self:GetLeft(), self:GetBottom())", why = "a dragged button keeps its spot" },
    { file = "Options/RSOptions.lua", text = 'AddToBlizOptions("RareScanner Display", AL["DISPLAY"], "RareScanner")', why = "the options are under Options > AddOns > RareScanner" },
    { file = "Core/Service/RSCommandLine.lua", text = 'local RARESCANNERS_CMD = "rs"', why = "/rs is RareScanner's slash command" },
  },
}
