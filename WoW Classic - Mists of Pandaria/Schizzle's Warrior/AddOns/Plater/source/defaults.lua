-- loads PLATER_DEFAULT_SETTINGS in plain Lua 5.1 with a permissive WoW shim (MoP Classic, Warrior)
local function any() local t; t = setmetatable({}, {__index = function() return t end, __call = function() return t end}); return t end
local AnyObj = any()
DetailsFramework = setmetatable({}, {__index = function() return function() return AnyObj end end})
local savedLibStub = LibStub
LibStub = setmetatable({GetLibrary = function() return AnyObj end}, {__call = function() return AnyObj end})
debugprofilestop = function() return 0 end
GetBuildInfo = function() return "5.5.4", "70631", "Oct 1 2026", 50504 end
WOW_PROJECT_ID = 19; WOW_PROJECT_MAINLINE = 1; WOW_PROJECT_CLASSIC = 2; WOW_PROJECT_MISTS_CLASSIC = 19
UnitClass = function() return "Warrior", "WARRIOR", 1 end
GetLocale = function() return "enUS" end
setmetatable(_G, {__index = function() return AnyObj end})
local chunk = assert(loadfile(PLATER_DIR .. "/Plater_DefaultSettings.lua"))
chunk("Plater", {})
setmetatable(_G, nil)
LibStub = savedLibStub
return PLATER_DEFAULT_SETTINGS
