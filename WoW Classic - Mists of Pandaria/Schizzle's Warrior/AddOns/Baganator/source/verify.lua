-- Checks Warrior Profile.txt with Baganator's own code.
-- Usage: lua verify.lua /path/to/Interface/AddOns   (folder holding Baganator)
local dir = arg[0]:match("^(.*)/") or "."
package.path = dir .. "/?.lua;" .. package.path
local root = assert(arg[1], "usage: lua verify.lua /path/to/Interface/AddOns")
local BAG = root .. "/Baganator/"
local json = require("json")
local fails = 0
local function check(ok, msg)
  if ok then print("ok   " .. msg) else print("FAIL " .. msg); fails = fails + 1 end
end
local function readFile(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return s end

-- 0. build output is current
local built = json.encode(dofile(dir .. "/profile.lua"))
local text = readFile(dir .. "/../Warrior Profile.txt")
check(text == built, "Warrior Profile.txt matches profile.lua (run lua build.lua if not)")
check(not text:find("||", 1, true) and not text:find("\n"), "one line, no || (the import box turns || into |)")
check(text:sub(1, 1) == "{", "starts with { so Baganator reads it as JSON")

-- 1. game API stand-ins Baganator's config code uses
function strsplit(sep, s) local t = {}; for p in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do t[#t + 1] = p end; return unpack(t) end
function tIndexOf(t, v) for i, x in ipairs(t) do if x == v then return i end end end
function GetKeysArray(t) local r = {}; for k in pairs(t) do r[#r + 1] = k end; return r end
function CopyTable(t) if type(t) ~= "table" then return t end; local r = {}; for k, v in pairs(t) do r[k] = CopyTable(v) end; return r end
function Mixin(o, ...) for i = 1, select("#", ...) do for k, v in pairs((select(i, ...))) do o[k] = v end end; return o end
function tAppendAll(t, s) for _, v in ipairs(s) do t[#t + 1] = v end end
function GetBuildInfo() return "5.5.4", "1", "Nov 1 2026", tonumber(os.getenv("BUILD") or 50504) end
WOW_PROJECT_MAINLINE, WOW_PROJECT_CLASSIC, WOW_PROJECT_MISTS_CLASSIC = 1, 2, 19
WOW_PROJECT_ID = WOW_PROJECT_MISTS_CLASSIC
Baganator = {}
local events = {}
local A = {
  CallbackRegistry = { TriggerEvent = function(_, e, n) events[#events + 1] = {e, n} end },
  Locales = setmetatable({}, {__index = function(_, k) return k end}),
  Core = {}, CustomiseDialog = {}, Skins = {availableSkins = {}},
  Utilities = { Message = function(m) print("Baganator message: " .. tostring(m)) end },
}
local function load(rel)
  local chunk = assert(loadfile(BAG .. rel))
  chunk("Baganator", A)
end
load("Core/Constants.lua")
load("Core/Config.lua")
load("CustomiseDialog/ImportExport.lua")
-- Skins: register the real Dark skin's option list (Dark.lua) for InstallOptions
do
  local src = readFile(BAG .. "Skins/Dark.lua")
  A.Skins.availableSkins.dark = { options = {} }
  for opt, def in src:match('RegisterSkin%(addonTable.Locales.DARK.-%}, false%)'):gmatch('option = "([%w_]+)",%s*default = ([%w%.]+)') do
    A.Skins.availableSkins.dark.options[#A.Skins.availableSkins.dark.options + 1] = {option = opt, default = (def == "true") or (def ~= "false" and tonumber(def)) or false}
  end
  local iso = assert(readFile(BAG .. "Skins/Initialize.lua"):match("(function addonTable.Skins.InstallOptions%(%).-\nend)"))
  local env = setmetatable({addonTable = A}, {__index = _G}); local f = assert(loadstring(iso)); setfenv(f, env); f()
end
A.Core.MigrateSettings = function() A.Skins.InstallOptions() end -- the parts of the real one that touch settings

-- 2. a fresh install, then a DEFAULT profile with one change of its own
BAGANATOR_CONFIG, BAGANATOR_CURRENT_PROFILE = nil, "DEFAULT"
A.Config.InitializeData()
A.Skins.InstallOptions()
A.Config.Set("sort_method", "quality")

-- 3. the import button's path (CustomiseDialog/Main.lua): JSON decode, then "Make new"
local import = json.decode(text)
check(type(import) == "table" and import.addon == "Baganator", "decodes to a Baganator table")
check(import.version == 3 and import.kind == "profile", "version 3 profile export (gets the Overwrite / Make New choice)")
local ok, err = A.CustomiseDialog.ImportData(import, "Schizzle's Warrior", false)
check(ok == true, "ImportData accepted it" .. (err and (" (error " .. err .. ")") or ""))
check(BAGANATOR_CURRENT_PROFILE == "Schizzle's Warrior", "switched to the Schizzle's Warrior profile")
local P = A.Config.CurrentProfile
local want = dofile(dir .. "/profile.lua")
for k, v in pairs(want) do
  if k ~= "addon" and k ~= "version" and k ~= "kind" then
    check(A.Config.IsValidOption(k), "'" .. k .. "' is a Baganator setting")
    if type(v) == "table" and k ~= "skins" then
      local same = #v == #P[k]; for i = 1, #v do same = same and P[k][i] == v[i] end
      check(same, k .. " = {" .. table.concat(v, ", ") .. "}")
    elseif k ~= "skins" then
      check(A.Config.Get(k) == v, k .. " = " .. tostring(v) .. " (Get returns " .. tostring(A.Config.Get(k)) .. ")")
    end
  end
end
local darkOpts = {}
for _, o in ipairs(A.Skins.availableSkins.dark.options) do darkOpts[o.option] = true end
check(next(darkOpts) ~= nil, "read the Dark skin's options from Dark.lua")
for k, v in pairs(want.skins.dark) do
  check(darkOpts[k], "skins.dark." .. k .. " is a Dark skin option")
  check(A.Config.Get("skins.dark." .. k) == v, "skins.dark." .. k .. " = " .. tostring(v))
end
check(want.skins.dark.square_icons == true, "square icons (README says reload)")
for k in pairs(want.skins) do check(k == "dark", "only the dark skin's options are set") end
check(P.addon == nil and P.version == nil and P.kind == nil, "header fields stripped from the stored profile")
local missing = 0
for k in pairs(A.Config.Defaults) do if not A.Config.IsCharacterSpecific[k] and P[k] == nil then missing = missing + 1 end end
check(missing == 0, "every other setting filled in from Baganator's defaults")
check(A.Config.Get("sort_method") == "type", "the default sort is used, not the old profile's")
check(BAGANATOR_CONFIG.Profiles.DEFAULT.sort_method == "quality", "the old DEFAULT profile is untouched")
check(A.Skins.availableSkins.dark and want.current_skin == "dark", "current_skin 'dark' is a registered skin")

-- 4. ranges from the options panel (CustomiseDialog/Main.lua)
local main = readFile(BAG .. "CustomiseDialog/Main.lua")
local function range(opt)
  local block = main:match("{[^{}]-option = \"" .. opt .. "\"[^{}]-}")
  return tonumber(block:match("min = (%d+)")), tonumber(block:match("max = (%d+)"))
end
for _, k in ipairs({"bag_view_width", "bank_view_width", "bag_icon_size", "icon_text_font_size"}) do
  local lo, hi = range(k)
  check(lo and want[k] >= lo and want[k] <= hi, ("%s %d within the slider's %s-%s"):format(k, want[k], tostring(lo), tostring(hi)))
end
check(want.skins.dark.view_transparency >= 0 and want.skins.dark.view_transparency <= 1, "transparency 0-1")
local points = {TOPLEFT=1, TOP=1, TOPRIGHT=1, LEFT=1, CENTER=1, RIGHT=1, BOTTOMLEFT=1, BOTTOM=1, BOTTOMRIGHT=1}
for _, k in ipairs({"bag_view_position", "bank_view_position"}) do
  local p = want[k]
  check(#p == 3 and points[p[1]] and p[2] % 1 == 0 and p[3] % 1 == 0, k .. " is {point, x, y} like the default")
end
for _, v in pairs({"single"}) do
  check(main:find('"' .. want.bag_view_type .. '"', 1, true) ~= nil, "bag_view_type value '" .. v .. "' is one the options panel offers")
end

-- 5. a broken string is refused
check(not pcall(json.decode, text:sub(1, -2)), "a cut-off string doesn't decode")
check(A.CustomiseDialog.ImportData({addon = "Other", version = 3, kind = "profile"}, "x", false) == false, "a non-Baganator table is refused")

print(fails == 0 and "ALL CHECKS PASSED" or (fails .. " CHECK(S) FAILED"))
os.exit(fails == 0 and 0 or 1)
