-- Checks Warrior Profile.txt (a Baganator "BGR!1!" profile export) with Baganator's own code.
-- Usage: lua verify.lua /path/to/Interface/AddOns   (folder holding Baganator; needs python3 for build.py)
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
local function run(cmd) local p = assert(io.popen(cmd)); local s = p:read("*a"); local ok = p:close(); return s, ok end
local function deepEqual(a, b)
  if type(a) ~= "table" or type(b) ~= "table" then return a == b end
  for k, v in pairs(a) do if not deepEqual(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end
local q = "'" .. dir:gsub("'", "'\\''") .. "/build.py'"

-- 0. the file is exactly what profile.json builds, and decodes the way Baganator's
--    import button does it (DecodeBase64, DecompressString, DeserializeCBOR)
local text = readFile(dir .. "/../Warrior Profile.txt")
local out = run("python3 " .. q .. " --check")
check(out:find("is current", 1, true) ~= nil, "Warrior Profile.txt rebuilds byte for byte from profile.json")
check(text:sub(1, 6) == "BGR!1!", "starts with BGR!1! (Baganator's compressed export)")
check(not text:find("|", 1, true) and not text:find("%s"), "one line, no | or spaces (the import box would mangle them)")
local decoded = run("python3 " .. q .. " --decode")
local ok, import = pcall(json.decode, decoded)
check(ok and type(import) == "table", "decodes to a table")
local want = json.decode(readFile(dir .. "/profile.json"))
check(deepEqual(import, want), "decoded string matches profile.json")

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

-- 3. the import button's checks and "Make new" (CustomiseDialog/Main.lua)
check(import.addon == "Baganator", "addon = Baganator (the import button refuses anything else)")
check(import.version == 3 and import.kind == "profile", "version 3 profile export (gets the Overwrite / Make New choice)")
local okImport, err = A.CustomiseDialog.ImportData(import, "Schizzle's Warrior", false)
check(okImport == true, "ImportData accepted it" .. (err and (" (error " .. err .. ")") or ""))
check(BAGANATOR_CURRENT_PROFILE == "Schizzle's Warrior", "switched to the Schizzle's Warrior profile")
local P = A.Config.CurrentProfile
check(P.addon == nil and P.version == nil and P.kind == nil, "header fields stripped from the stored profile")
local unknown = {}
for k, v in pairs(want) do
  if k ~= "addon" and k ~= "version" and k ~= "kind" then
    if not A.Config.IsValidOption(k) then unknown[#unknown + 1] = k end
    if not deepEqual(A.Config.Get(k), v) then check(false, k .. " landed with the exported value") end
  end
end
table.sort(unknown)
check(#unknown == 0, "every key is a Baganator setting" .. (#unknown > 0 and (" (unknown: " .. table.concat(unknown, ", ") .. ")") or ""))
local count = 0; for _ in pairs(want) do count = count + 1 end
check(true, (count - 3) .. " settings landed with the exported values")
for k in pairs(A.Config.IsCharacterSpecific) do
  check(want[k] == nil, k .. " (per character) isn't in the export")
end
local missing = {}
for k in pairs(A.Config.Defaults) do if not A.Config.IsCharacterSpecific[k] and P[k] == nil then missing[#missing + 1] = k end end
check(#missing == 0, "every setting is present or filled in from Baganator's defaults")
check(A.Config.Get("sort_method") == "type", "the profile's sort is used, not the old DEFAULT profile's")
check(BAGANATOR_CONFIG.Profiles.DEFAULT.sort_method == "quality", "the old DEFAULT profile is untouched")

-- 4. the values the README describes
local darkOpts = {}
for _, o in ipairs(A.Skins.availableSkins.dark.options) do darkOpts[o.option] = true end
check(want.current_skin == "dark" and A.Skins.availableSkins.dark ~= nil, "current_skin 'dark' is a registered skin")
for k, v in pairs(want.skins.dark) do
  check(darkOpts[k], "skins.dark." .. k .. " is a Dark skin option")
  check(A.Config.Get("skins.dark." .. k) == v, "skins.dark." .. k .. " = " .. tostring(v))
end
local main = readFile(BAG .. "CustomiseDialog/Main.lua")
local function range(opt)
  local block = main:match("{[^{}]-option = \"" .. opt .. "\"[^{}]-}")
  return tonumber(block:match("min = (%d+)")), tonumber(block:match("max = (%d+)"))
end
for _, k in ipairs({"bag_view_width", "bank_view_width", "bag_icon_size", "icon_text_font_size"}) do
  local lo, hi = range(k)
  check(lo and want[k] >= lo and want[k] <= hi, ("%s %d within the slider's %s-%s"):format(k, want[k], tostring(lo), tostring(hi)))
end
local points = {TOPLEFT=1, TOP=1, TOPRIGHT=1, LEFT=1, CENTER=1, RIGHT=1, BOTTOMLEFT=1, BOTTOM=1, BOTTOMRIGHT=1}
for _, k in ipairs({"bag_view_position", "bank_view_position"}) do
  local p = want[k]
  check(#p == 3 and points[p[1]] and p[2] % 1 == 0 and p[3] % 1 == 0, k .. " is {point, x, y} like the default")
end
for _, k in ipairs({"auto_open.bank", "auto_open.guild_bank", "auto_open.trade_partner", "auto_open.tradeskill",
    "auto_open.auction_house", "auto_open.mail", "auto_open.merchant", "auto_open.sockets", "auto_sort_on_open"}) do
  check(main:find('option = "' .. k .. '"', 1, true) ~= nil, k .. " is in the options panel")
end
local oc = readFile(BAG .. "ItemViewCommon/OpenClose.lua")
for opt, val in pairs({guild_bank = true, trade_partner = true, tradeskill = true, auction_house = true, mail = true, bank = true, merchant = true, sockets = false}) do
  check(want.auto_open[opt] == val, "auto_open." .. opt .. " = " .. tostring(val))
  check(oc:find('option = "' .. opt .. '"', 1, true) ~= nil, "auto_open." .. opt .. " is one OpenClose.lua reads")
end
check(want.auto_sort_on_open == true and want.sort_method == "type", "sort on open, by type")
check(want.junk_plugin == "RXPGuides" and want.upgrade_plugin == "pawn", "junk from RestedXP, upgrades from Pawn")
check(readFile(BAG .. "API/Pawn.lua"):find('RegisterUpgradePlugin("Pawn", "pawn"', 1, true) ~= nil, "'pawn' is Baganator's Pawn upgrade plugin id")
check(main:find("if addonTable.API.JunkPlugins[addonTable.Config.Get(\"junk_plugin\")] == nil then", 1, true) ~= nil,
  "without RestedXP Baganator resets junk detection to its default")
check(want.lock_frames == false, "windows unlocked (README: tick Lock windows after moving)")

-- 5. a broken string is refused
local bad = run("python3 -B -c \"import sys; sys.path.insert(0, sys.argv[1]); import build; build.decode(open(sys.argv[2]).read()[:-4])\" '" .. dir .. "' '" .. dir .. "/../Warrior Profile.txt' 2>/dev/null && echo DECODED")
check(not bad:find("DECODED", 1, true), "a cut-off string doesn't decode")
check(A.CustomiseDialog.ImportData({addon = "Other", version = 3, kind = "profile"}, "x", false) == false, "a non-Baganator table is refused")

print(fails == 0 and "ALL CHECKS PASSED" or (fails .. " CHECK(S) FAILED"))
os.exit(fails == 0 and 0 or 1)
