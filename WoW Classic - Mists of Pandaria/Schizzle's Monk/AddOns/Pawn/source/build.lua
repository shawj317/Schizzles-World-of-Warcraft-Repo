-- Writes the three Pawn scale tags.  Usage (from this folder): lua build.lua   env: OUT_DIR
local HERE = (arg and arg[0] or ""):match("^(.*[/\\])") or "./"
local OUT_DIR = os.getenv("OUT_DIR") or (HERE .. "../")
local S = dofile(HERE .. "scales.lua")
local function fmt(v) if type(v) == "string" then return v end local s = string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", "") return s end
for _, sc in ipairs(S) do
  local list = {}
  for _, p in ipairs(sc.values) do list[#list + 1] = p end
  for _, p in ipairs(S.extras.all) do list[#list + 1] = p end
  if sc.role ~= "tank" then for _, p in ipairs(S.extras.nontank) do list[#list + 1] = p end end
  if sc.role ~= "healer" then for _, p in ipairs(S.extras.agility) do list[#list + 1] = p end end
  local parts = {"Class=Monk", "Spec=" .. sc.spec}
  for _, p in ipairs(list) do parts[#parts + 1] = p[1] .. "=" .. fmt(p[2]) end
  local tag = string.format('( Pawn: v1: "%s": %s )', sc.name, table.concat(parts, ", "))
  local f = assert(io.open(OUT_DIR .. sc.file, "wb")) f:write(tag, "\n") f:close()
  print(sc.file, #tag)
end
