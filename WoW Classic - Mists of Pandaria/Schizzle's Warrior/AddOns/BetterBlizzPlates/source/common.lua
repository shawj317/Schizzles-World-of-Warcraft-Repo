-- Shared setup for build.lua and verify.lua: a minimal WoW environment that loads
-- BetterBlizzPlates' own libraries (LibStub, LibDeflate, LibSerialize-BB, AceSerializer-3.0)
-- and its own shared/ImportExport.lua from a BBP checkout, plus BBP's default settings
-- tables for the Mists (classics/) and WoW Forever (forever/) code paths.
-- Plain Lua 5.1. Set BBP_SRC to a BetterBlizzPlates checkout (tested on v2.2.3c).

local M = {}
M.src = os.getenv("BBP_SRC") or "/tmp/bbp"
M.bbpVersion = os.getenv("BBP_VERSION") or "v2.2.3c"
M.wowVersion = "5.5.4"

local function readfile(p)
  local f = assert(io.open(p, "rb"), "cannot open " .. p)
  local s = f:read("*a"); f:close(); return s
end
M.readfile = readfile

-- WoW API stubs used by the libs and ImportExport.lua
strmatch, strsub, strbyte, strchar = string.match, string.sub, string.byte, string.char
strfind, strlen, strrep, strformat, format = string.find, string.len, string.rep, string.format, string.format
tinsert, tremove, tconcat = table.insert, table.remove, table.concat
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
function CopyTable(t)
  local r = {}
  for k, v in pairs(t) do r[k] = type(v) == "table" and CopyTable(v) or v end
  return r
end
function GetBuildInfo() return M.wowVersion, "0", "", 50504 end
-- Friendly nameplates are off for the export (Jon plays with enemy plates only).
C_CVar = { GetCVarBool = function() return false end }

dofile(M.src .. "/libs/LibStub/LibStub.lua")
dofile(M.src .. "/libs/LibDeflate/LibDeflate.lua")
dofile(M.src .. "/libs/AceSerializer-3.0/AceSerializer-3.0.lua")
dofile(M.src .. "/libs/LibSerialize/LibSerialize.lua")

-- The Mists client: BBP sets isMoP from the build, which makes classicExport true and
-- leaves retailExport nil (a retail export would trigger BBP's retail-to-classic fix-up).
BBP = { L = setmetatable({}, { __index = function(_, k) return k end }),
        VersionNumber = M.bbpVersion, isMoP = true }
assert(loadfile(M.src .. "/shared/ImportExport.lua"))("BetterBlizzPlates", BBP)

-- Pull `local defaultSettings = { ... }` out of a BetterBlizzPlates.lua and evaluate it.
function M.loadDefaults(path, flags)
  local text = readfile(path)
  local s = text:find("local defaultSettings = {", 1, true)
  assert(s, "no defaultSettings in " .. path)
  local e = text:find("\n}\n", s, true)
  local chunk = "return " .. text:sub(s + #"local defaultSettings = ", e + 1)
  local fakeBBP = setmetatable(flags or {}, { __index = BBP })
  -- GetSpellInfo returns nil here, so the CC list falls back to the English names BBP ships.
  local env = setmetatable({ addonVersion = "1.00", BBP = fakeBBP, L = BBP.L,
                             GetSpellInfo = function() return nil end }, { __index = _G })
  local f = assert(loadstring(chunk, "=" .. path .. ":defaultSettings"))
  setfenv(f, env)
  return f()
end

M.classicsDefaults = M.loadDefaults(M.src .. "/classics/BetterBlizzPlates.lua", { isMoP = true })
M.foreverDefaults = M.loadDefaults(M.src .. "/forever/BetterBlizzPlates.lua", { isMoP = false })

-- Every setting key the given code paths read or write, as `BetterBlizzPlatesDB.key`,
-- `db.key`, `BetterBlizzPlatesDB["key"]`, `db["key"]` or as the first argument of a
-- GUI widget (CreateCheckbox / dropdowns take the key as a string; CreateSlider takes
-- it as the element string after the label and range).
function M.codeKeys(files)
  local keys = {}
  for _, p in ipairs(files) do
    local t = readfile(p)
    for k in t:gmatch("BetterBlizzPlatesDB%.([%a_][%w_]*)") do keys[k] = true end
    for k in t:gmatch("%f[%w_]db%.([%a_][%w_]*)") do keys[k] = true end
    for k in t:gmatch("BetterBlizzPlatesDB%[\"([%w_]+)\"%]") do keys[k] = true end
    for k in t:gmatch("%f[%w_]db%[\"([%w_]+)\"%]") do keys[k] = true end
    for k in t:gmatch("Create%a*%(\"([%w_]+)\"") do keys[k] = true end
    for k in t:gmatch("CreateSlider%([^\n]-\"([%w_]+)\"%s*[,%)]") do keys[k] = true end
  end
  return keys
end

function M.listLua(dir)
  local out = {}
  local p = io.popen('find "' .. dir .. '" -name "*.lua" | sort')
  for line in p:lines() do out[#out + 1] = line end
  p:close()
  return out
end

-- Mists loads shared/ + classics/; Forever loads shared/ + forever/ (see the TOCs).
function M.mistsFiles()
  local t = M.listLua(M.src .. "/shared")
  for _, f in ipairs(M.listLua(M.src .. "/classics")) do t[#t + 1] = f end
  return t
end
function M.foreverFiles()
  local t = M.listLua(M.src .. "/shared")
  for _, f in ipairs(M.listLua(M.src .. "/forever")) do t[#t + 1] = f end
  return t
end

return M
