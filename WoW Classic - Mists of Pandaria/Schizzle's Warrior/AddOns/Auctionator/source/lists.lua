-- Schizzle's Warrior Auctionator shopping lists (Jon Shaw / Schizzle), MIT with attribution.
-- build.lua turns these into Auctionator's list import format: one list per line,
-- "List Name^term^term". Every term is quoted, which makes it an exact-name search.
-- Sources: Wowhead MoP Classic Arms and Protection Warrior consumables guides (2026).
return {
  {
    name = "Schizzle's Warrior DPS",
    items = {
      "Flask of Winter's Bite",        -- +1000 Strength
      "Potion of Mogu Power",          -- +4000 Strength
      "Black Pepper Ribs and Shrimp",  -- +300 Strength food
      "Bold Primordial Ruby",          -- red / prismatic gem, Strength
      "Inscribed Vermilion Onyx",      -- yellow gem, Strength / Crit
      "Etched Imperial Amethyst",      -- blue gem, Strength / Hit
      "Living Steel Belt Buckle",      -- extra belt socket
    },
  },
  {
    name = "Schizzle's Warrior Tank",
    items = {
      "Flask of the Earth",            -- Stamina flask (big hits)
      "Flask of Winter's Bite",        -- Strength flask (everything else)
      "Potion of Mogu Power",          -- Strength potion (preferred)
      "Potion of the Mountains",       -- +12000 armour potion
      "Chun Tian Spring Rolls",        -- +450 Stamina food
      "Black Pepper Ribs and Shrimp",  -- +300 Strength food
      "Solid River's Heart",           -- blue gem, Stamina
      "Living Steel Belt Buckle",      -- extra belt socket
    },
  },
}
