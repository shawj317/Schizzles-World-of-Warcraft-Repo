-- Theme resolution and the borderless backdrop. Lua 5.1: lua5.1 theme_test.lua
local function script_dir()
	local source = debug.getinfo(1, "S").source
	if source:sub(1, 1) == "@" then
		source = source:sub(2)
	end
	return source:match("^(.*)[/\\]") or "."
end

local ns = {}
assert(loadfile(script_dir() .. "/../AddOns/Wayfarer/Theme.lua"))("Wayfarer", ns)

local fails = 0
local function check(cond, msg)
	if not cond then
		fails = fails + 1
		print("FAIL " .. msg)
	end
end

local wayfarer = ns.ResolveTheme("wayfarer")
check(wayfarer.border[1] == 0.72 and wayfarer.id == "wayfarer", "wayfarer theme is the kit bronze")
local unknown = ns.ResolveTheme("nope")
check(unknown.bgFile == wayfarer.bgFile, "an unknown theme falls back to Wayfarer")

local blizzard = ns.ResolveTheme("blizzard")
check(string.find(blizzard.edgeFile, "UI-DialogBox-Border", 1, true) ~= nil, "classic uses the dialog border")
check(blizzard.border[1] == 1 and blizzard.border[2] == 0.82, "classic border is gold")

local color, fallback = ns.ClassColorOrFallback(nil)
check(fallback == true and math.abs(color.r - 0.72) < 0.001, "missing class color uses the bronze fallback")
local given, usedFallback = ns.ClassColorOrFallback({ r = 0.0, g = 0.44, b = 0.87 })
check(usedFallback == false and given.b == 0.87, "a real class color is kept")

local classed = ns.ResolveTheme("class", { r = 0.0, g = 0.44, b = 0.87 })
check(classed.border[3] == 0.87 and classed.pinRing[3] == 0.87, "class theme tints the border and the pin ring")
check(classed.bg[1] < 0.2, "class theme stays on a dark backdrop")

local bare = ns.ResolveTheme("class", nil)
check(math.abs(bare.border[1] - 0.72) < 0.001, "class theme without a class color uses the fallback")

local open = ns.BackdropSpec(wayfarer, 0.85, true)
check(open.edgeFile ~= nil and open.edgeSize > 0 and open.insets.left > 0, "border on keeps an edge")
check(math.abs(open.bgAlpha - 0.85) < 0.001, "backdrop alpha is separate from the edge")

local shut = ns.BackdropSpec(blizzard, 0.4, false)
check(shut.edgeFile == nil and shut.edgeSize == 0, "border off drops the edge texture")
check(shut.insets.left == 0 and shut.insets.top == 0 and shut.pad == 2, "border off has no leftover inset")
check(shut.border == nil, "border off does not tint an edge")
check(math.abs(shut.bgAlpha - 0.4) < 0.001, "opacity still applies with no border")

local clipped = ns.BackdropSpec(wayfarer, 2, true)
check(clipped.bgAlpha == 1, "opacity clamps at 100%")

if fails > 0 then
	print(fails .. " failed")
	os.exit(1)
end
print("OK")
