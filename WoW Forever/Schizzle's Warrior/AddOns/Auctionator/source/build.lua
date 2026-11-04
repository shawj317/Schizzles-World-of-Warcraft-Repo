-- Writes "../Shopping Lists.txt" (Auctionator list import) from lists.lua.
-- Usage: lua build.lua [--check]
local dir = arg[0]:match("^(.*)/") or "."
local lines = {}
for _, list in ipairs(dofile(dir .. "/lists.lua")) do
  local parts = {list.name}
  for _, item in ipairs(list.items) do parts[#parts + 1] = '"' .. item .. '"' end
  lines[#lines + 1] = table.concat(parts, "^")
end
local out = table.concat(lines, "\n") .. "\n"
local path = dir .. "/../Shopping Lists.txt"
if arg[1] == "--check" then
  local f = assert(io.open(path, "rb")); local cur = f:read("*a"); f:close()
  if cur ~= out then print("Shopping Lists.txt is out of date; run lua build.lua"); os.exit(1) end
  print("Shopping Lists.txt is current")
else
  local f = assert(io.open(path, "wb")); f:write(out); f:close()
  print(("wrote Shopping Lists.txt (%d lists, %d chars)"):format(#lines, #out))
end
