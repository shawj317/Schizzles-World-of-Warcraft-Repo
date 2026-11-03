-- Writes ../Warrior Profile.txt (Baganator JSON profile import) from profile.lua.
-- Usage: lua build.lua [--check]
local dir = arg[0]:match("^(.*)/") or "."
package.path = dir .. "/?.lua;" .. package.path
local json = require("json")
local out = json.encode(dofile(dir .. "/profile.lua"))
local path = dir .. "/../Warrior Profile.txt"
if arg[1] == "--check" then
  local f = assert(io.open(path, "rb")); local cur = f:read("*a"); f:close()
  if cur ~= out then print("Warrior Profile.txt is out of date; run lua build.lua"); os.exit(1) end
  print("Warrior Profile.txt is current")
else
  local f = assert(io.open(path, "wb")); f:write(out); f:close()
  print(("wrote Warrior Profile.txt (%d chars)"):format(#out))
end
