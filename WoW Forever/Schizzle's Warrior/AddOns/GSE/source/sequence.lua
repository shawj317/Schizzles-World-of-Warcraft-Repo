-- ProtWar24 for GSE 3.3.37-a on WoW Forever. Plain data. build.lua turns it into the import string.
-- The two blocks are the exact macro text requested. Nothing else is added: no target line, no Heroic Strike
-- on an unmodified press, no Taunt, Shield Bash or cooldown.
--
-- SpecID 1 is the Warrior class id. GSE.SpecIDClassList[1] = 1 and GSE.GetClassIDforSpec(1) returns 1 because
-- any id <= 13 is that class (CharacterFunctions.lua). Id 8 is Mage. Id 73 is the Protection talent tree,
-- which also files under class 1, but this sequence is the class-wide Warrior entry so it is there for the
-- Warrior before a tree filter would hide it.
-- The two lines below are the macro text, character for character.
local BLOCK_1 = "/startattack\n/cast [mod:alt,mod:shift] Cleave; [mod:shift] Thunder Clap; [mod:ctrl] Shield Block; [mod:alt] Heroic Strike; [stance:2] Revenge"
local BLOCK_2 = "/startattack\n/cast [mod:alt,mod:shift] Cleave; [mod:shift] Thunder Clap; [mod:ctrl] Shield Block; [mod:alt] Heroic Strike; [stance:2] Sunder Armor"

return {
  name = "ProtWar24",
  author = "Jon Shaw (Schizzle)",
  helplink = "https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo",
  -- Forever's interface number. GSE 3.3.37-a lists 16001 in GSE.toc and in release.json as flavor "forever".
  -- GSE.TOCFlavour(16001) is "forever", so a Forever client does not print the other-version warning.
  toc = 16001,
  -- GSE.ParseVersion("3.3.37-a") drops the "-a" and returns 3*1000 + 3*100 + 37 = 3337.
  -- Equal to that build: no older-version note, and EnforceCompatability does not refuse it.
  gseVersionString = "3.3.37-a",
  gseVersion = 3337,
  specID = 1,
  lastUpdated = "20261108210000",
  label = "Level 24",
  help = "Each press runs the next block, then the first again. With no modifier the block tries Revenge, then the next press tries Sunder Armor, only in stance 2. Shift is Thunder Clap, Ctrl is Shield Block, Alt is Heroic Strike, Alt-Shift is Cleave. A press does not try the next spell if this one cannot be cast.",
  blocks = { BLOCK_1, BLOCK_2 },
}
