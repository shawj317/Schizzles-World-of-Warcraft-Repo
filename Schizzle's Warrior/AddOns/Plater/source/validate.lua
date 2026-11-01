-- every profile key must exist in Plater's defaults with the same type (catches typos and stale keys)
dofile("common.lua")
local D = dofile("defaults.lua").profile
local freeform = {["aura_tracker.debuff_tracked"] = true, ["color_override_colors"] = true}
local errs, n = {}, 0
local function walk(o, d, path)
  for k, v in pairs(o) do
    local p = path and (path .. "." .. tostring(k)) or tostring(k)
    n = n + 1
    if path and freeform[path] then
      if path == "color_override_colors" and type(d[k]) ~= "table" then errs[#errs + 1] = "missing reaction " .. p end
      if path == "aura_tracker.debuff_tracked" and (type(k) ~= "number" or type(v) ~= "boolean") then errs[#errs + 1] = "bad debuff entry " .. p end
    elseif d == nil or d[k] == nil then
      errs[#errs + 1] = "unknown key: " .. p
    elseif type(d[k]) ~= type(v) then
      errs[#errs + 1] = ("type mismatch %s: default %s, override %s"):format(p, type(d[k]), type(v))
    elseif type(v) == "table" then
      if #d[k] > 0 and #v ~= #d[k] and not freeform[p] then
        errs[#errs + 1] = ("array length %s: default %d, override %d"):format(p, #d[k], #v)
      end
      walk(v, d[k], p)
    end
  end
end
for _, sp in ipairs(SPECS) do
  local O = assert(loadfile("profile.lua"))(sp.key)
  walk(O, D, nil)
end
print("checked entries:", n)
for _, e in ipairs(errs) do print("ERR", e) end
os.exit(#errs == 0 and 0 or 1)
