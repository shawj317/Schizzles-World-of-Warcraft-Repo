-- Checks this guide against the addon's own source: every option key and every
-- on-screen label the README tells you to click really exists, the defaults the
-- README describes are the addon's real defaults, and the README names each label.
-- Usage: lua verify.lua /path/to/Interface/AddOns
local dir = arg[0]:match("^(.*)/") or "."
local root = assert(arg[1], "usage: lua verify.lua /path/to/Interface/AddOns")
local guide = dofile(dir .. "/settings.lua")
local fails = 0
local function check(ok, msg) if ok then print("ok   " .. msg) else print("FAIL " .. msg); fails = fails + 1 end end
local cache = {}
local function readFile(rel)
  local p = root .. "/" .. guide.folder .. "/" .. rel
  if cache[p] == nil then
    local f = io.open(p, "rb")
    cache[p] = f and f:read("*a") or false
    if f then f:close() end
  end
  return cache[p]
end
local function has(rel, needle)
  local s = readFile(rel)
  return s and s:find(needle, 1, true) ~= nil
end
local readme = assert(io.open(dir .. "/../README.md", "rb")):read("*a")

for _, f in ipairs(guide.requireFiles or {}) do
  check(readFile(f) ~= false, guide.folder .. "/" .. f .. " exists")
end
for _, t in ipairs(guide.tocs or {}) do
  local s = readFile(t.file)
  local iface = s and s:match("## Interface:%s*([^\r\n]+)")
  check(iface and iface:find(t.interface, 1, true) ~= nil, t.file .. " lists Interface " .. t.interface .. " (" .. tostring(iface) .. ")")
end
for _, o in ipairs(guide.options) do
  if o.key then check(has(o.keyFile, o.key), ("key %s is in %s"):format(o.key, o.keyFile)) end
  if o.label then
    check(has(o.labelFile, o.label), ("label %q is in %s"):format(o.label, o.labelFile))
    check(readme:find(o.readmeLabel or o.label, 1, true) ~= nil, ("README names %q"):format(o.readmeLabel or o.label))
  end
  if o.default then
    check(has(o.defaultFile or o.keyFile, o.default), ("default for %s: %s"):format(o.key or o.label, o.default))
  end
end
for _, c in ipairs(guide.extraChecks or {}) do
  check(has(c.file, c.text), c.why)
end
if fails == 0 then print("ALL CHECKS PASSED") else print(fails .. " CHECK(S) FAILED"); os.exit(1) end
