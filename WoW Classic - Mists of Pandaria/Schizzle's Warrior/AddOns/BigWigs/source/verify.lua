-- Checks ../Warrior Profile.txt with BigWigs' own code (BigWigs_Options/Sharing.lua):
--   BW_SRC=/path/to/AddOns LIBDEFLATE=/path/to/LibDeflate.lua lua verify.lua
-- 1. The string imports through SaveImportStringDataFromAddOn (the import path BigWigs offers
--    other add-ons; the Import box runs the same DecodeImportString and SaveData), BigWigs
--    reports success, and every plugin setting lands with the value from profile.lua.
-- 2. Every value passes the range and frame point checks in BigWigs' plugin files
--    (the checks that reset bad values to defaults on load).
-- 3. A changed string is rejected.
local C = dofile("common.lua")
local P = dofile("profile.lua")
local fails = 0
local function check(cond, what)
	if cond then print("ok   " .. what) else fails = fails + 1; print("FAIL " .. what) end
end

local f = assert(io.open("../Warrior Profile.txt", "rb"))
local str = f:read("*a"):gsub("%s+$", "")
f:close()
check(str:match("^BW2:[%w%+/=]+$") ~= nil, "one line, BW2: prefix, Base64 body")

-- 1. Import -----------------------------------------------------------------------------------
local profiles, messages = C.newBigWigs()
local sharing = C.loadSharing()
local result
sharing.SaveImportStringDataFromAddOn(str, function(ok) result = ok end)
check(result == true, "BigWigs import reports success")
local sawUpdate = false
for _, m in ipairs(messages) do if m == "BigWigs_ProfileUpdate" then sawUpdate = true end end
check(sawUpdate, "BigWigs sends BigWigs_ProfileUpdate (applies without a reload)")
for _, s in ipairs(C.SECTIONS) do
	local all = true
	for k, v in pairs(P[s[1]]) do
		if not C.equal(v, profiles[s[2]][k]) then all = false; print("     " .. s[1] .. "." .. k .. " differs") end
	end
	check(all, s[1] .. ": every setting imported as written")
end
for _, sec in ipairs(C.COLOR_SECTIONS) do
	local all = true
	for k, v in pairs(P[sec]) do
		if not C.equal(v, profiles.Colors[k].BigWigs_Plugins_Colors.default) then all = false; print("     " .. sec .. "." .. k .. " differs") end
	end
	check(all, sec .. ": every colour imported as the default colour")
end

-- Every key we set is one BigWigs exports (anything else would be dropped silently).
local src = io.open(C.BW_SRC .. "/BigWigs_Options/Sharing.lua"):read("*a")
local missing = {}
for name, sec in pairs(P) do
	local list = src:match("local " .. name .. "ToExport = (%b{})")
	for k in pairs(sec) do
		if not (list and list:find('"' .. k .. '"', 1, true)) then missing[#missing + 1] = name .. "." .. k end
	end
end
check(#missing == 0, "every key is in BigWigs' export lists" .. (#missing > 0 and (" (missing: " .. table.concat(missing, ", ") .. ")") or ""))

-- 2. Plugin load checks ------------------------------------------------------------------------
local function read(p) local h = assert(io.open(C.BW_SRC .. "/BigWigs_Plugins/" .. p)); local s = h:read("*a"); h:close(); return s end
local plugins = { Bars = read("Bars.lua"), Messages = read("Messages.lua"), Countdown = read("Countdown.lua") }
local consts = {}
for a, b, c, d in plugins.Bars:gmatch("local minBarWidth, minBarHeight, maxBarWidth, maxBarHeight = (%d+), (%d+), (%d+), (%d+)") do
	consts = { minBarWidth = tonumber(a), minBarHeight = tonumber(b), maxBarWidth = tonumber(c), maxBarHeight = tonumber(d) }
end
local function num(x) return tonumber(x) or consts[x] end
local ranges = 0
for name, code in pairs(plugins) do
	for key, lo, key2, hi in code:gmatch("db%.(%w+) < ([%w%.]+) or db%.(%w+) > ([%w%.]+)") do
		if key == key2 and num(lo) and num(hi) then
			for _, s in ipairs(C.SECTIONS) do
				local v = s[2] == name and P[s[1]][key]
				if type(v) == "number" then
					ranges = ranges + 1
					check(v >= num(lo) and v <= num(hi), ("%s %s = %s is within %s..%s"):format(name, key, v, num(lo), num(hi)))
				end
			end
		end
	end
end
check(ranges >= 10, "range checks found in BigWigs' plugin code (" .. ranges .. ")")
local points = { TOPLEFT = 1, TOP = 1, TOPRIGHT = 1, LEFT = 1, CENTER = 1, RIGHT = 1, BOTTOMLEFT = 1, BOTTOM = 1, BOTTOMRIGHT = 1 }
for _, pos in ipairs({ P.barPositions.normalPosition, P.barPositions.expPosition, P.messagePositions.normalPosition, P.messagePositions.emphPosition, P.countdownPositions.position }) do
	check(points[pos[1]] and points[pos[2]] and pos[3] == math.floor(pos[3]) and pos[4] == math.floor(pos[4]), "position " .. table.concat(pos, ",") .. " uses valid points and whole offsets")
end
for _, o in ipairs({ P.barSettings.outline, P.messageSettings.outline, P.messageSettings.emphOutline, P.countdownSettings.outline }) do
	check(o == "NONE" or o == "OUTLINE" or o == "THICKOUTLINE", "outline " .. o .. " is allowed")
end
-- Media: BigWigs falls back to its defaults if these aren't registered.
local wa = os.getenv("WA_TYPES")
if wa then
	local t = io.open(wa):read("*a")
	check(t:find("Fira Sans Condensed Medium", 1, true) ~= nil, "WeakAuras registers Fira Sans Condensed Medium")
end

-- 3. Tampering -----------------------------------------------------------------------------
-- Flip one character in the middle: BigWigs must not import anything.
local mid = math.floor(#str / 2)
local bad = str:sub(1, mid - 1) .. (str:sub(mid, mid) == "A" and "B" or "A") .. str:sub(mid + 1)
local fresh, msgs = C.newBigWigs()
local sharing2 = C.loadSharing()
sharing2.SaveImportStringDataFromAddOn(bad, function() end)
check(next(fresh.Bars) == nil and next(fresh.Messages) == nil, "a changed string imports nothing")

-- 4. Independent decode (Python zlib + cbor2), if Python with cbor2 is available ---------------
local py = io.popen([[python3 -c "
import sys,base64,zlib,cbor2
s=open('../Warrior Profile.txt').read().strip().split(':',1)[1]
d=cbor2.loads(zlib.decompress(base64.b64decode(s),-15))
print(sorted(k.decode() for k in d))
" 2>/dev/null]])
local out = py and py:read("*a") or ""
if py then py:close() end
if out ~= "" then
	check(out:find("barSettings", 1, true) and out:find("version", 1, true), "Python zlib + cbor2 decode the string on their own")
else
	print("skip independent Python decode (python3 with cbor2 not found)")
end

print(fails == 0 and "ALL CHECKS PASSED" or (fails .. " CHECK(S) FAILED"))
os.exit(fails == 0 and 0 or 1)
