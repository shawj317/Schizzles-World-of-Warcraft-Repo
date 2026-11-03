-- Checks "Shopping Lists.txt" with Auctionator's own import and search code.
-- Usage: lua verify.lua /path/to/Interface/AddOns   (folder holding Auctionator)
local dir = arg[0]:match("^(.*)/") or "."
local AT = assert(arg[1], "usage: lua verify.lua /path/to/Interface/AddOns") .. "/Auctionator/"
local fails = 0
local function check(ok, msg) if ok then print("ok   " .. msg) else print("FAIL " .. msg); fails = fails + 1 end end
local function readFile(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return s end
local text = readFile(dir .. "/../Shopping Lists.txt")
local want = dofile(dir .. "/lists.lua")

-- game API stand-ins
gsub = string.gsub
function strsplit(sep, s, limit)
  local t, start = {}, 1
  while true do
    if limit and #t == limit - 1 then t[#t + 1] = s:sub(start); break end
    local i = s:find(sep, start, true)
    if not i then t[#t + 1] = s:sub(start); break end
    t[#t + 1] = s:sub(start, i - 1); start = i + 1
  end
  return unpack(t)
end
AUCTIONATOR_L_IMPORTED, AUCTIONATOR_L_TEMPORARY_LOWER_CASE = "Imported", "temporary"
-- a list manager with the methods Auctionator's import calls
local lists, order, fired = {}, {}, {}
local function newList(name)
  local l = {name = name, items = {}}
  function l:ClearItems() self.items = {} end
  function l:AppendItems(t) for _, v in ipairs(t) do self.items[#self.items + 1] = v end end
  function l:InsertItem(v) self.items[#self.items + 1] = v end
  function l:GetName() return self.name end
  return l
end
Auctionator = {
  Shopping = { Lists = {}, Events = {ListImportFinished = "ListImportFinished"} },
  Debug = { Message = function() end },
  Constants = { AdvancedSearchDivider = ";" },
  EventBus = {},
  Search = {},
}
function Auctionator.EventBus:RegisterSource() return self end
function Auctionator.EventBus:UnregisterSource() return self end
function Auctionator.EventBus:Fire(_, e, name) fired[#fired + 1] = {e, name}; return self end
Auctionator.Shopping.ListManager = {
  GetIndexForName = function(_, n) for i, x in ipairs(order) do if x == n then return i end end end,
  Create = function(_, n) lists[n] = newList(n); order[#order + 1] = n end,
  GetByName = function(_, n) return lists[n] end,
}
-- an old list with the same item, to show it isn't touched
Auctionator.Shopping.ListManager:Create("My Old List")
lists["My Old List"]:InsertItem("Golden Lotus")

assert(loadfile(AT .. "Source/Shopping/ImportExport.lua"))()
local adv = readFile(AT .. "Source/Search/Advanced.lua")
assert(loadstring(assert(adv:match("(function Auctionator.Search.SplitAdvancedSearch.-\nend)\n"))))()

-- the Import button's choice (Source/Tabs/Shopping/Mixins/ImportFrame.lua)
local frame = readFile(AT .. "Source/Tabs/Shopping/Mixins/ImportFrame.lua")
check(frame:find('string.match%(importString, "%%%^"%)%s*then%s*[^\n]*\n%s*Auctionator.Shopping.Lists.BatchImportFromString') ~= nil
  or frame:find("BatchImportFromString(importString)", 1, true) ~= nil, "the Import button sends ^ strings to BatchImportFromString")
check(text:find("^", 1, true) ~= nil, "the file contains ^, so it takes that path")
check(not text:find("*", 1, true), "no *, so it isn't mistaken for the old format")

-- build is current
local lines = {}
for _, list in ipairs(want) do
  local p = {list.name}; for _, i in ipairs(list.items) do p[#p + 1] = '"' .. i .. '"' end
  lines[#lines + 1] = table.concat(p, "^")
end
check(text == table.concat(lines, "\n") .. "\n", "Shopping Lists.txt matches lists.lua")

Auctionator.Shopping.Lists.BatchImportFromString(text)
for _, list in ipairs(want) do
  local got = lists[list.name]
  check(got ~= nil, "list '" .. list.name .. "' created")
  if got then
    check(#got.items == #list.items, ("  %d entries"):format(#list.items))
    for i, item in ipairs(list.items) do
      local term = got.items[i] or ""
      local s = Auctionator.Search.SplitAdvancedSearch(term)
      check(s.searchString == item and s.isExact == true, ("  %-30s exact search for %q"):format(term, item))
    end
  end
  local seen = false
  for _, f in ipairs(fired) do if f[2] == list.name then seen = true end end
  check(seen, "  ListImportFinished fired, so the Shopping tab shows it")
end
local count = 0; for _ in pairs(lists) do count = count + 1 end
check(count == #want + 1, "no stray lists (blank lines are skipped)")
check(#lists["My Old List"].items == 1, "other lists are left alone")
-- importing again replaces the entries instead of doubling them
Auctionator.Shopping.Lists.BatchImportFromString(text)
check(#lists[want[1].name].items == #want[1].items, "importing twice doesn't double the entries")

print(fails == 0 and "ALL CHECKS PASSED" or (fails .. " CHECK(S) FAILED"))
os.exit(fails == 0 and 0 or 1)
