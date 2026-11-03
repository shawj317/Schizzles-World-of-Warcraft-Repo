-- Loads BigWigs_Options/Sharing.lua (BigWigs' own import/export code) with just enough of the
-- game mocked to run its export and import. Paths come from the environment:
--   BW_SRC      folder with BigWigs_Options and BigWigs_Plugins (an Interface/AddOns copy)
--   LIBDEFLATE  path to LibDeflate.lua (BetterBlizzPlates and Plater ship it)
local C = {}
C.BW_SRC = assert(os.getenv("BW_SRC"), "set BW_SRC")
local enc = dofile("encoding.lua")
enc.init(assert(os.getenv("LIBDEFLATE"), "set LIBDEFLATE"))
C_EncodingUtil = enc.C_EncodingUtil

local function noop() end
local function widget()
	local w = { editBox = { SetScript = noop }, button = { Hide = noop } }
	return w
end

-- Fresh BigWigs plugin profiles; Colors keeps BigWigs' layout (profile[name][module][key]).
function C.newBigWigs()
	local profiles = { Bars = {}, Messages = {}, Countdown = {}, Colors = {} }
	local colors = profiles.Colors
	for _, k in ipairs({ "barBackground", "barText", "barTextShadow", "barColor", "barEmphasized", "red", "blue", "orange", "yellow", "green", "cyan", "purple" }) do
		colors[k] = { BigWigs_Plugins_Colors = {} }
	end
	local messages = {}
	BigWigs = {
		GetPlugin = function(_, name) if profiles[name] then return { db = { profile = profiles[name] } } end end,
		Print = function(_, m) messages[#messages + 1] = m end,
		SendMessage = function(_, m) messages[#messages + 1] = m end,
	}
	BigWigsLoader = { db = { GetNamespace = function() return nil end }, zoneTbl = {}, currentExpansion = {} }
	return profiles, messages
end

function C.loadSharing()
	LibStub = setmetatable({}, { __call = function() return { RegisterWidgetType = noop, Create = widget } end })
	BigWigsAPI = { GetLocale = function() return setmetatable({}, { __index = function(_, k) return k end }) end }
	GetLocale = function() return "enUS" end
	local addonTable = {}
	assert(loadfile(C.BW_SRC .. "/BigWigs_Options/Sharing.lua"))("BigWigs_Options", addonTable)
	assert(addonTable.GetExportString and addonTable.SaveImportStringDataFromAddOn, "Sharing.lua API changed")
	return addonTable
end

function C.copy(v)
	if type(v) ~= "table" then return v end
	local r = {}
	for k, x in pairs(v) do r[k] = C.copy(x) end
	return r
end

function C.equal(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then return a == b end
	for k, v in pairs(a) do if not C.equal(v, b[k]) then return false end end
	for k in pairs(b) do if a[k] == nil then return false end end
	return true
end

C.SECTIONS = {
	{ "barPositions", "Bars" }, { "barSettings", "Bars" }, { "messagePositions", "Messages" },
	{ "messageSettings", "Messages" }, { "countdownPositions", "Countdown" }, { "countdownSettings", "Countdown" },
	{ "countdownColors", "Countdown" },
}
C.COLOR_SECTIONS = { "barColors", "messageColors" }
return C
