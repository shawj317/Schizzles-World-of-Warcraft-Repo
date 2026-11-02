-- Builds ../Warrior Profile.txt with BetterBlizzPlates' own export code.
-- Usage (from this folder):  BBP_SRC=/path/to/BetterBlizzPlates lua build.lua
-- It sets BetterBlizzPlatesDB to the profile and calls BBP.ExportProfile(db, "fullProfile"),
-- exactly what the Export button in /bbp > Import & Export > Full Profile does.
local C = dofile("common.lua")
local profile = dofile("profile.lua")

BBP.exportDefaults = CopyTable(C.classicsDefaults)
BetterBlizzPlatesDB = CopyTable(profile)
local str = BBP.ExportProfile(BetterBlizzPlatesDB, "fullProfile")

local out = os.getenv("OUT") or "../Warrior Profile.txt"
local f = assert(io.open(out, "wb")); f:write(str); f:close()
print(("wrote %s (%d chars)"):format(out, #str))
