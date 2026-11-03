-- Schizzle's Warrior GTFO settings: what the README tells you to set, and where
-- each option lives in GTFO's own source (checked by verify.lua).
return {
  folder = "GTFO",
  requireFiles = { "GTFO.lua", "Classic/GTFO_Classic.lua", "Localization/enUS.lua" },
  tocs = {
    { file = "GTFO_Mists.toc", interface = "50504" },    -- MoP Classic 5.5.x
    { file = "GTFO_Camelot.toc", interface = "16001" },  -- WoW Forever
  },
  options = {
    { key = "Volume = 3;", keyFile = "GTFO.lua", label = "GTFO Volume", labelFile = "Localization/enUS.lua", set = "2: Soft" },
    { label = "2: Soft", labelFile = "Localization/enUS.lua" },
    { key = 'SoundChannel = "Master";', keyFile = "GTFO.lua", label = "Sound Channel", labelFile = "Localization/enUS.lua", set = "Master (default)" },
    { key = "TrivialMode = nil;", keyFile = "GTFO.lua", label = "Trivial content alerts", labelFile = "Localization/enUS.lua", set = "off (default)" },
    { key = "Sounds = { true, true, true, true };", keyFile = "GTFO.lua", label = "Raid/High Damage sounds", labelFile = "Localization/enUS.lua", set = "on (default)" },
    { label = "PvP/Environment/Low Damage sounds", labelFile = "Localization/enUS.lua", set = "on (default)" },
    { label = "Fail Alert sounds", labelFile = "Localization/enUS.lua", set = "on (default)" },
    { label = "Friendly Fire sounds", labelFile = "Localization/enUS.lua", set = "on (default)" },
    { key = "UnmuteMode = nil;", keyFile = "GTFO.lua", label = "Play sounds when muted", labelFile = "Localization/enUS.lua", set = "off (default)" },
    { label = "Experimental/Beta Mode", labelFile = "Localization/enUS.lua", set = "off (default)" },
  },
  extraChecks = {
    { file = "GTFO.lua", text = 'Command == "OPTION" or Command == "OPTIONS"', why = "/gtfo options opens the options" },
    { file = "Classic/GTFO_Classic.lua", text = 'SLASH_GTFO1 = "/GTFO"', why = "/gtfo is GTFO's slash command on Classic" },
    { file = "GTFO.lua", text = "alarmbuzzer_soft.ogg", why = "Soft (2) plays the quieter _soft sound files" },
    { file = "GTFO.lua", text = "Play 2 times if the volume is at louder", why = "Loud (4) and up play each alert more than once" },
  },
}
