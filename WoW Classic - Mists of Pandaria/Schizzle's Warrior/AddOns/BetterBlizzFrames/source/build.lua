-- Builds ../Warrior Profile.txt with BetterBlizzFrames' own export code.
-- Usage (from this folder):  BBF_SRC=/path/to/BetterBlizzFrames lua build.lua
-- It sets BetterBlizzFramesDB to the profile and calls BBF.ExportProfile(db, "fullProfile"),
-- exactly what the Export button in /bbf > Import & Export > Full Profile does.
local C = dofile("common.lua")
local profile = dofile("profile.lua")

BBF.exportDefaults = CopyTable(C.classicsDefaults)
BetterBlizzFramesDB = CopyTable(profile)
local str = BBF.ExportProfile(BetterBlizzFramesDB, "fullProfile")

local out = os.getenv("OUT") or "../Warrior Profile.txt"
local f = assert(io.open(out, "wb")); f:write(str); f:close()
print(("wrote %s (%d chars)"):format(out, #str))
