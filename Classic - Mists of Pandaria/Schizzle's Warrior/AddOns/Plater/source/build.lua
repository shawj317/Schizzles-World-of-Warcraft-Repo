-- Builds the three Schizzle's Warrior Plater profile strings (mods embedded) and the
-- stand-alone mod strings. Run from this folder: lua build.lua [outdir]
dofile("common.lua")
local OUT = arg[1] or ".."
local TOC = 50504
local NOW = tonumber(os.getenv("BUILD_TIME") or "") or 1793563200 -- fixed default so rebuilds are reproducible
local AUTHOR = "Schizzle (Jon Shaw)"

local function emptyLoad() return {affix={},class={},encounter_ids={},group={},map_ids={},pvptalent={},race={},role={},spec={},talent={}} end
local function trimHooks(h) local r = {} for k, v in pairs(h) do r[k] = (v:gsub("^%s+", ""):gsub("%s+$", "")) end return r end

-- per-profile mod option values (anything not listed uses the mod's default)
local MOD_VALUES = {
  arms = {["Schizzle's Warrior Threat Mode"] = {useProtSpec = true, useDefensive = false}},
  fury = {["Schizzle's Warrior Threat Mode"] = {useProtSpec = true, useDefensive = false}},
  prot = {["Schizzle's Warrior Threat Mode"] = {useProtSpec = true, useDefensive = true}},
}

MODS = {}
for i, f in ipairs(MOD_FILES) do
  local M = dofile("mods/" .. f .. ".lua")
  M.uid = string.format("0x%08x%08x", NOW, 5317000 + i)
  MODS[i] = M
end

-- stand-alone mod import strings (Plater > Modding > Import)
local function modExport(M)
  return {
    ["1"] = M.name, ["2"] = M.icon, ["3"] = M.desc, ["4"] = AUTHOR,
    ["5"] = NOW, ["6"] = M.revision, ["7"] = 1, ["8"] = M.load or emptyLoad(), ["9"] = trimHooks(M.hooks),
    options = M.options, addon = "Plater", tocversion = TOC, type = "hook", UID = M.uid,
  }
end
-- the same mod as it is stored inside a profile (what Plater.BuildScriptObjectFromIndexTable makes)
local function modObject(M, values)
  return {
    Enabled = true, Name = M.name, Icon = M.icon, Desc = M.desc, Author = AUTHOR, Time = NOW,
    Revision = M.revision, PlaterCore = 1, LoadConditions = M.load or emptyLoad(),
    Hooks = trimHooks(M.hooks), HooksTemp = {}, LastHookEdited = "",
    Options = deepcopy(M.options), OptionsValues = deepcopy(values or {}),
    url = "", version = -1, semver = "", UID = M.uid, Prio = 99,
  }
end

os.execute('mkdir -p "' .. OUT .. '/Mods"')
for _, M in ipairs(MODS) do
  local s = encode(modExport(M))
  writef(OUT .. "/Mods/" .. M.file .. ".txt", s)
  print(("mod      %-26s %6d chars"):format(M.file, #s))
end

for _, sp in ipairs(SPECS) do
  local prof = deepcopy(assert(loadfile("profile.lua"))(sp.key))
  prof.hook_data = {}
  for _, M in ipairs(MODS) do
    prof.hook_data[#prof.hook_data + 1] = modObject(M, MOD_VALUES[sp.key][M.name])
  end
  prof.tocversion = TOC
  prof.profile_name = sp.name
  local s = encode(prof)
  writef(OUT .. "/" .. sp.file, s)
  print(("profile  %-26s %6d chars  %s"):format(sp.file, #s, s:sub(1, 30)))
end
