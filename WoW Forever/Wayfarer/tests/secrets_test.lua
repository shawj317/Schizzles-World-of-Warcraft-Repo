-- Secret-value guards. Run with Lua 5.1:
--   lua5.1 secrets_test.lua
local function script_dir()
	local source = debug.getinfo(1, "S").source
	if source:sub(1, 1) == "@" then
		source = source:sub(2)
	end
	return source:match("^(.*)[/\\]") or "."
end

issecretvalue = function(value)
	return value == "SECRET"
end

local ns = {}
local chunk = assert(loadfile(script_dir() .. "/../AddOns/Wayfarer/Secrets.lua"))
chunk("QuestRoute", ns)

local fails = 0
local function check(cond, msg)
	if not cond then
		fails = fails + 1
		print("FAIL " .. msg)
	end
end

check(ns.Readable(4, 0) == 4, "plain number passes through")
check(ns.Readable(nil, 7) == nil, "nil is not a secret")
check(ns.Readable("SECRET", 3) == 3, "secret falls back")
check(ns.Num("SECRET", 8) == 8, "secret number falls back")
check(ns.Num("12", 0) == 12, "numeric string")
check(ns.Num("nope", 4) == 4, "bad number falls back")
check(ns.Num(nil, 1) == 1, "nil number falls back")
check(ns.Text("SECRET", "no") == "no", "secret text falls back")
check(ns.Text("Hi", "no") == "Hi", "plain text passes through")
check(ns.Text("", "no") == "no", "empty text falls back")
check(ns.Flag("SECRET") == false, "secret boolean is not yes")
check(ns.Flag(true) == true, "true stays true")
check(ns.Flag(1) == true, "one stays true")
check(ns.Flag(nil) == false, "nil is not yes")
check(ns.IsRestrictionActive(nil) == false, "no restriction argument")
check(ns.IsRestrictionActive("Map") == false, "no restriction api")
check(ns.InCombat() == false, "no combat api")

C_RestrictedActions = {
	IsAddOnRestrictionActive = function(value)
		return value == "Map"
	end,
}
check(ns.IsRestrictionActive("Map") == true, "map restriction is active")
check(ns.IsRestrictionActive("Chat") == false, "chat restriction is not active")

if fails > 0 then
	print(fails .. " failed")
	os.exit(1)
end
print("OK")
