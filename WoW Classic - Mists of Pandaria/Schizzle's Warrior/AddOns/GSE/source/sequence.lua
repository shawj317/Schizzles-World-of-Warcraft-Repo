-- Schizzle's Warrior level 8 leveling sequences for GSE (GnomeSequencer Enhanced) on MoP Classic 5.5.
-- Plain data: build.lua turns it into the GSE import string and the readable sheet, verify.lua checks both.
-- Every spell here is one a level 8 Warrior already knows in MoP (see README "Abilities at level 8"):
--   Heroic Strike 78 (level 1, off the GCD), Charge 100 (level 3, off the GCD), Victory Rush 34428 (level 5, GCD),
--   Execute 5308 (level 7, GCD) and the Orc racial Blood Fury 20572 (level 1, off the GCD, 2 min).
local TARGET = "/cleartarget [dead][help]\n/targetenemy [noexists][dead][help]\n/startattack\n"
local CHARGE_MOD = "/cast [mod:shift] Charge\n"

return {
  author = "Jon Shaw (Schizzle)",
  helplink = "https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo",
  toc = 50504,          -- MoP Classic 5.5.4
  gseVersion = 3330,    -- 3.3.30: anything this new or newer imports it (EnforceCompatability)
  specID = 1,           -- 1 = Warrior class-wide, so it works before a spec is picked at level 10
  lastUpdated = "20261103030000",
  sequences = {
    {
      name = "SCHIZ_WAR_L8",
      label = "Leveling",
      note = "Main button. Press it over and over in melee; hold Shift on the same key to Charge.",
      blocks = {
        { title = "Victory Rush, Blood Fury, Heroic Strike",
          macro = TARGET .. CHARGE_MOD .. "/cast Victory Rush\n/cast [combat] Blood Fury\n/cast Heroic Strike" },
        { title = "Execute, Heroic Strike",
          macro = TARGET .. CHARGE_MOD .. "/cast Execute\n/cast Heroic Strike" },
      },
    },
    {
      name = "SCHIZ_WAR_L8_CHG",
      label = "Charge",
      note = "Opener on its own key: picks the nearest enemy, Charges it and starts swinging.",
      blocks = {
        { title = "Charge opener",
          macro = "/cleartarget [dead][help]\n/targetenemy [noexists][dead][help]\n/cast Charge\n/startattack" },
      },
    },
  },
}
