-- Shared setup for build.lua and verify.lua: a minimal WoW environment that loads
-- BetterBlizzFrames' own libraries (LibStub, LibDeflate, LibSerialize-BB) and its
-- own shared/ImportExport.lua from a BBF checkout, plus BBF's default settings
-- tables for the Mists (classics/) and WoW Forever (forever/) code paths.
-- Plain Lua 5.1. Set BBF_SRC to a BetterBlizzFrames checkout (tested on v2.2.0d).

local M = {}
M.src = os.getenv("BBF_SRC") or "/tmp/bbf"
M.bbfVersion = os.getenv("BBF_VERSION") or "v2.2.0d"
M.wowVersion = "5.5.4"

local function readfile(p)
  local f = assert(io.open(p, "rb"), "cannot open " .. p)
  local s = f:read("*a"); f:close(); return s
end
M.readfile = readfile

-- WoW API stubs used by the libs and ImportExport.lua
strmatch, strsub, strbyte, strchar = string.match, string.sub, string.byte, string.char
tinsert = table.insert
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
function CopyTable(t)
  local r = {}
  for k, v in pairs(t) do r[k] = type(v) == "table" and CopyTable(v) or v end
  return r
end
function GetBuildInfo() return M.wowVersion, "0", "", 50504 end

dofile(M.src .. "/libs/LibStub/LibStub.lua")
dofile(M.src .. "/libs/LibDeflate/LibDeflate.lua")
dofile(M.src .. "/libs/LibSerialize/LibSerialize.lua")

BBF = { L = setmetatable({}, { __index = function(_, k) return k end }), VersionNumber = M.bbfVersion }
assert(loadfile(M.src .. "/shared/ImportExport.lua"))("BetterBlizzFrames", BBF)

-- Pull `local defaultSettings = { ... }` out of a BetterBlizzFrames.lua and evaluate it.
function M.loadDefaults(path)
  local text = readfile(path)
  local s = text:find("local defaultSettings = {", 1, true)
  assert(s, "no defaultSettings in " .. path)
  local e = text:find("\n}\n", s, true)
  local chunk = "return " .. text:sub(s + #"local defaultSettings = ", e + 1)
  local env = setmetatable({ addonVersion = "1.00", BBF = BBF, L = BBF.L }, { __index = _G })
  local f = assert(loadstring(chunk, "=" .. path .. ":defaultSettings"))
  setfenv(f, env)
  return f()
end

M.classicsDefaults = M.loadDefaults(M.src .. "/classics/BetterBlizzFrames.lua")
M.foreverDefaults = M.loadDefaults(M.src .. "/forever/BetterBlizzFrames.lua")

-- Every setting key the given code paths read or write, as `BetterBlizzFramesDB.key`,
-- `db.key`, `BetterBlizzFramesDB["key"]`, `db["key"]` or as the first argument of a
-- GUI widget (CreateCheckbox / CreateSlider / dropdowns take the key as a string).
function M.codeKeys(files)
  local keys = {}
  for _, p in ipairs(files) do
    local t = readfile(p)
    for k in t:gmatch("BetterBlizzFramesDB%.([%a_][%w_]*)") do keys[k] = true end
    for k in t:gmatch("%f[%w_]db%.([%a_][%w_]*)") do keys[k] = true end
    for k in t:gmatch("BetterBlizzFramesDB%[\"([%w_]+)\"%]") do keys[k] = true end
    for k in t:gmatch("%f[%w_]db%[\"([%w_]+)\"%]") do keys[k] = true end
    for k in t:gmatch("Create%a*%(\"([%w_]+)\"") do keys[k] = true end
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
