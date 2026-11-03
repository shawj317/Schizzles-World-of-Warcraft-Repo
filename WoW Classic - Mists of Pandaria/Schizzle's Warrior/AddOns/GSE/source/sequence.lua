-- Schizzle's Warrior level 8 leveling sequences for GSE (GnomeSequencer Enhanced) on MoP Classic 5.5.
-- Plain data: build.lua turns it into the GSE import string and the readable sheet, verify.lua checks both.
-- Every spell here is one a level 8 Warrior already knows in MoP (see README "Abilities at level 8"):
--   Heroic Strike 78 (level 1, off the GCD), Charge 100 (level 3, off the GCD), Victory Rush 34428 (level 5, GCD),
--   Execute 5308 (level 7, GCD) and the Orc racial Blood Fury 20572 (level 1, off the GCD, 2 min).
--
-- Targeting lives in one GSE variable, SCHIZ_TARGET, which every block calls with the line =GSE.V["SCHIZ_TARGET"]().
-- GSE runs the variable when it compiles the sequence (out of combat) and puts what it returns in place of that line.
-- GSE 3.3.36 reads a block as macro text only if its first line is a slash command; a block that starts with a
-- variable line is taken as the name of a WoW macro and does nothing. So /cleartarget stays as each block's first
-- line, and the variable holds the target-picking line after it.
local TARGET_VAR = "SCHIZ_TARGET"
local TARGET_LINE = "/targetenemy [noexists][dead][help]"
local CALL = '=GSE.V["' .. TARGET_VAR .. '"]()'
local TARGET = "/cleartarget [dead][help]\n" .. CALL .. "\n"
local CHARGE_MOD = "/cast [mod:shift] Charge\n"

return {
  author = "Jon Shaw (Schizzle)",
  helplink = "https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo",
  toc = 50504,          -- MoP Classic 5.5.4
  -- GSE turns its version "3.3.36-a" into 3*1000 + 3*100 + 36 = 3336 (GSE.ParseVersion). A sequence stamped lower
  -- than the installed GSE gets the "created with an older version" notice; one stamped higher is refused
  -- (EnforceCompatability). 3336 is exactly GSE 3.3.36, so 3.3.36 imports it with no notice.
  gseVersionString = "3.3.36",
  gseVersion = 3336,
  specID = 1,           -- 1 = Warrior class-wide, so it works before a spec is picked at level 10
  lastUpdated = "20261103031500",
  -- GSE variables shipped in the same collection. funct is the Lua GSE runs; it must return the text to insert.
  variables = {
    { name = TARGET_VAR, call = CALL, returns = TARGET_LINE,
      note = "Picks the nearest enemy when you have no target, or your target is dead or friendly.",
      funct = 'function()\n  return "' .. TARGET_LINE .. '"\nend' },
  },
  sequences = {
    {
      name = "SCHIZ_WAR_L8",
      label = "Leveling",
      note = "Main button. Press it over and over in melee; hold Shift on the same key to Charge.",
      blocks = {
        { title = "Victory Rush, Blood Fury, Heroic Strike",
          macro = TARGET .. "/startattack\n" .. CHARGE_MOD .. "/cast Victory Rush\n/cast [combat] Blood Fury\n/cast Heroic Strike" },
        { title = "Execute, Heroic Strike",
          macro = TARGET .. "/startattack\n" .. CHARGE_MOD .. "/cast Execute\n/cast Heroic Strike" },
      },
    },
    {
      name = "SCHIZ_WAR_L8_CHG",
      label = "Charge",
      note = "Opener on its own key: picks the nearest enemy, Charges it and starts swinging.",
      blocks = {
        { title = "Charge opener",
          macro = TARGET .. "/cast Charge\n/startattack" },
      },
    },
  },
}
