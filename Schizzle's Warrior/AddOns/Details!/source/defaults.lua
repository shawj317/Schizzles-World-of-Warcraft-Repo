-- load Details! default tables (profile, player, global, instance) + Minimalistic skin in plain Lua 5.1
local SRC = DETAILS_SRC
local function any() local t; t = setmetatable({}, {__index=function(_,k) return t end, __call=function() return t end, __concat=function() return "" end}); return t end
local AnyObj = any()
local saved = {}
for k,v in pairs(_G) do saved[k]=v end
Details = {}
_detalhes = Details
local D222 = {}
local DFw = setmetatable({IsAddonApocalypseWow=function() return false end,
  IsTimewalkWoW=function() return false end, IsClassicWow=function() return false end, IsWotLKWow=function() return false end,
  IsPandaWow=function() return true end, IsCataWow=function() return false end, IsDragonflight=function() return false end,
  IsNonRetailWowWithRetailAPI=function() return true end, IsTWWWow=function() return false end, IsWarWow=function() return false end,
  table = {copy=function(a,b) return a end}}, {__index=function() return function() return false end end})
DetailsFramework = DFw
LibStub = setmetatable({GetLibrary=function() return setmetatable({Fetch=function(_, kind, name) return "FETCH:"..tostring(name) end}, {__index=function() return function() return AnyObj end end}) end},
  {__call=function(_, name) if name=="AceLocale-3.0" then return {GetLocale=function() return setmetatable({}, {__index=function(_,k) return k end}) end} end
     return setmetatable({Fetch=function(_, kind, name) return "FETCH:"..tostring(name) end}, {__index=function() return function() return AnyObj end end}) end})
GetBuildInfo = function() return "5.5.4", "70631", "Oct 1 2026", 50504 end
WOW_PROJECT_ID = 19; WOW_PROJECT_MAINLINE = 1
setmetatable(_G, {__index=function(_,k) return AnyObj end})
local function load(path) local chunk = assert(loadfile(SRC..path)); chunk("Details", D222) end
load("functions/rowtexts.lua")
Details.default_skin_to_use = "Minimalistic"
load("classes/include_instance.lua")
load("functions/profiles.lua")
Details.skins = {}
function Details:InstallSkin(name, t) Details.skins[name] = t end
local ok, err = pcall(load, "functions/skins.lua")
setmetatable(_G, nil)
-- sanity: AnyObj must not have leaked into the data tables
local function scan(t, path, seen)
  seen = seen or {}
  if seen[t] then return end seen[t] = true
  for k, v in pairs(t) do
    if v == AnyObj then error("shim value leaked at "..path.."."..tostring(k)) end
    if type(v) == "table" then scan(v, path.."."..tostring(k), seen) end
  end
end
local R = {profile = Details.default_profile, player = Details.default_player_data, global = Details.default_global_data,
  instance = Details.instance_defaults, skins = Details.skins, skinsOk = ok, skinsErr = err, ignored = Details.instance_skin_ignored_values,
  defaultTexts = D222.RowTexts.GetDefaultTexts, RowTexts = D222.RowTexts, Details = Details}
scan(R.profile, "profile"); scan(R.instance, "instance")
return R
