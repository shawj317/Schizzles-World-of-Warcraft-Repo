-- Writes ../Warrior Profile.txt with BigWigs' own export code (GetExportString, the code behind
-- the Export box), fed the settings from profile.lua.
--   BW_SRC=/path/to/AddOns LIBDEFLATE=/path/to/LibDeflate.lua lua build.lua
local C = dofile("common.lua")
local P = dofile("profile.lua")
local profiles = C.newBigWigs()
for _, s in ipairs(C.SECTIONS) do
	for k, v in pairs(P[s[1]]) do profiles[s[2]][k] = C.copy(v) end
end
for _, sec in ipairs(C.COLOR_SECTIONS) do
	for k, v in pairs(P[sec]) do profiles.Colors[k].BigWigs_Plugins_Colors.default = C.copy(v) end
end
local sharing = C.loadSharing()
local str = sharing.GetExportString(true)
assert(str:sub(1, 4) == "BW2:")
local f = assert(io.open("../Warrior Profile.txt", "wb"))
f:write(str, "\n")
f:close()
print("wrote ../Warrior Profile.txt (" .. #str .. " chars)")
