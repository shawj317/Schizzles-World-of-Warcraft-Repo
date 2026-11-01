-- decode every shipped string, compare with the source, lint every hook, then run sim.lua
-- usage: lua verify.lua [dir with the .txt files]   (default ..)
dofile("common.lua")
local DIR = arg[1] or ".."
local fails = 0
local function check(c, msg) if not c then fails = fails + 1; print("FAIL: " .. msg) end end

local hookNames = {}
for _, n in ipairs{"Initialization","Deinitialization","Constructor","Destructor","Nameplate Created","Nameplate Added","Nameplate Removed","Nameplate Updated","Cast Start","Cast Update","Cast Stop","Target Changed","Raid Target","Enter Combat","Leave Combat","Player Power Update","Player Talent Update","Health Update","Zone Changed","Name Updated","Load Screen","Player Logon","Receive Comm Message","Send Comm Message","Option Changed","Mod Option Changed"} do hookNames[n] = true end
-- names Plater's mod sandbox hides (subset of privateFunctions in Plater.lua) plus things we never want
local blocked = {"pcall","xpcall","loadstring","getfenv","setfenv","setmetatable","getglobal","RunScript","securecall","SlashCmdList","PlaterDB","PlaterDBChr","ChatEdit_SendText","SendChatMessage","ReloadUI"}

local function lintHooks(label, hooks)
  local n = 0
  for hn, code in pairs(hooks) do
    n = n + 1
    check(hookNames[hn], label .. " unknown hook " .. hn)
    check(code:match("^function%s*%("), label .. " " .. hn .. " starts with function")
    local f, err = loadstring("return " .. code, hn)
    check(f ~= nil, label .. " compile " .. hn .. ": " .. tostring(err))
    local tmp = os.tmpname(); writef(tmp, "return " .. code)
    local rc = os.execute(LUAC .. " -p " .. tmp .. " 2>/dev/null")
    check(rc == 0, label .. " luac " .. hn); os.remove(tmp)
    for _, b in ipairs(blocked) do check(not code:find("%f[%w_]" .. b .. "%f[^%w_]"), label .. " " .. hn .. " uses blocked " .. b) end
    check(not code:find("Plater.SendComm"), label .. " SendComm")
  end
  return n
end
local function lintOptions(label, options)
  local keys = {}
  for _, o in ipairs(options) do
    check(type(o.Type) == "number" and o.Name and o.Key and o.Icon and o.Value ~= nil, label .. " option fields " .. tostring(o.Name))
    if o.Type ~= 5 and o.Type ~= 6 then check(not keys[o.Key], label .. " dup key " .. o.Key); keys[o.Key] = true end
    if o.Type == 2 then check(o.Min and o.Max and o.Value >= o.Min and o.Value <= o.Max, label .. " number range " .. o.Key) end
    if o.Type == 1 then check(type(o.Value) == "table" and #o.Value == 4, label .. " colour " .. o.Key) end
    if o.Type == 3 then check(type(o.Value) == "string", label .. " text " .. o.Key) end
  end
  return keys
end
local loadKeys = {"class","spec","race","talent","pvptalent","group","role","affix","encounter_ids","map_ids"}

-- 1. stand-alone mod strings
local srcMods, byName = {}, {}
for i, f in ipairs(MOD_FILES) do srcMods[i] = dofile("mods/" .. f .. ".lua") end
local MODS = {}
for _, M in ipairs(srcMods) do
  local s = readf(DIR .. "/Mods/" .. M.file .. ".txt")
  check(not s:find("[\r\n]"), M.file .. " single line")
  local t = decode(s)
  check(encode(t) and deepeq(decode(encode(t)), t), M.file .. " re-encode round trip")
  check(t.type == "hook" and t.addon == "Plater" and t.tocversion == 50504, M.file .. " header")
  for _, k in ipairs{"1","2","3","4","5","6","7","8","9"} do check(t[k] ~= nil, M.file .. " field " .. k) end
  for _, k in ipairs(loadKeys) do check(type(t["8"][k]) == "table", M.file .. " loadcond " .. k) end
  check(t["1"] == M.name, M.file .. " name")
  check(deepeq(t.options, M.options), M.file .. " options == source")
  for hn, code in pairs(M.hooks) do check(t["9"][hn] == (code:gsub("^%s+", ""):gsub("%s+$", "")), M.file .. " hook == source " .. hn) end
  lintOptions(M.file, t.options)
  local nh = lintHooks(M.file, t["9"])
  MODS[#MODS + 1] = {file = M.file, t = t}
  byName[t["1"]] = t
  print(("mod ok      %-24s hooks=%d options=%d"):format(M.file, nh, #t.options))
end

-- 2. profiles
local D = dofile("defaults.lua").profile
local function merge(t1, t2) for k, v in pairs(t2) do if type(v) == "table" then t1[k] = t1[k] or {} merge(t1[k], v) else t1[k] = v end end return t1 end
PROFILES = {}
for _, sp in ipairs(SPECS) do
  local s = readf(DIR .. "/" .. sp.file)
  check(not s:find("[\r\n]"), sp.file .. " single line")
  local P = decode(s)
  check(deepeq(decode(encode(P)), P), sp.file .. " re-encode round trip")
  check(type(P) == "table" and P.plate_config, sp.file .. " has plate_config (Plater treats it as a profile)")
  check(P.tocversion == 50504, sp.file .. " tocversion")
  check(P.profile_name == sp.name, sp.file .. " profile_name " .. tostring(P.profile_name))
  local O = assert(loadfile("profile.lua"))(sp.key)
  local Pc = deepcopy(P); Pc.hook_data = nil; Pc.tocversion = nil; Pc.profile_name = nil
  check(deepeq(Pc, O), sp.file .. " decode == source")
  -- what ImportAndSwitchProfile does: ResetProfile (defaults) then DF.table.copy(profile, imported)
  local merged = merge(deepcopy(D), P)
  check(merged.plate_config.enemynpc.health_incombat[2] == 18, sp.file .. " merged health height")
  check(merged.plate_config.enemynpc.actorname_text_font == "Fira Sans Condensed Medium", sp.file .. " font")
  check(merged.tank.colors.noaggro[1] == 0.95 and merged.tank.colors.anothertank[3] == 1 and merged.dps.colors.aggro[1] == 0.95, sp.file .. " threat colours merged")
  check(merged.aura_tracker.track_method == 1, sp.file .. " automatic aura tracking")
  for id, v in pairs(merged.aura_tracker.debuff_tracked) do check(type(id) == "number" and v == false, sp.file .. " debuff id " .. tostring(id)) end
  local dt = merged.aura_tracker.debuff_tracked
  check(dt[115767] == false and dt[113746] == false and dt[115798] == false and dt[1715] == false and dt[12323] == false, sp.file .. " common debuffs")
  if sp.key == "prot" then check(dt[1160] == false and dt[86346] == nil, sp.file .. " prot debuffs")
  else check(dt[86346] == false, sp.file .. " colossus smash") end
  if sp.key == "arms" then check(dt[115804] == false, sp.file .. " mortal wounds") end
  -- embedded mods: same code/options as the stand-alone strings, valid stored script objects
  check(#P.hook_data == #MODS, sp.file .. " embedded mod count")
  for i, h in ipairs(P.hook_data) do
    local t = MODS[i].t
    check(h.Enabled == true and h.Name == t["1"] and h.UID == t.UID, sp.file .. " mod " .. i .. " identity")
    check(deepeq(h.Hooks, t["9"]) and deepeq(h.Options, t.options) and deepeq(h.LoadConditions, t["8"]), sp.file .. " mod " .. i .. " == stand-alone")
    for _, k in ipairs(loadKeys) do check(type(h.LoadConditions[k]) == "table", sp.file .. " mod loadcond " .. k) end
    check(type(h.OptionsValues) == "table" and type(h.HooksTemp) == "table", sp.file .. " mod tables")
    local keys = lintOptions(sp.file, h.Options)
    for k in pairs(h.OptionsValues) do check(keys[k], sp.file .. " OptionsValues key " .. k .. " exists") end
  end
  PROFILES[sp.key] = P
  print(("profile ok  %-24s %d chars, %d keys, %d mods, %d tracked debuffs"):format(sp.file, #s,
    (function() local n = 0 for _ in pairs(P) do n = n + 1 end return n end)(), #P.hook_data,
    (function() local n = 0 for _ in pairs(dt) do n = n + 1 end return n end)()))
end
check(PROFILES.prot.hook_data[2].OptionsValues.useDefensive == true and PROFILES.arms.hook_data[2].OptionsValues.useDefensive == false, "per-profile threat mode values")

VERIFY_MODS = MODS
dofile("sim.lua")
fails = fails + (SIM_FAILS or 0)
print(fails == 0 and "ALL CHECKS PASSED" or ("FAILURES: " .. fails))
os.exit(fails == 0 and 0 or 1)
