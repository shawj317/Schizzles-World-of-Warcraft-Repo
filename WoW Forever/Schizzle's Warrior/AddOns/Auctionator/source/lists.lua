-- Schizzle's Warrior Auctionator shopping list for WoW Forever (Jon Shaw / Schizzle), MIT with attribution.
-- build.lua turns it into Auctionator's list import format: one list per line, "List Name^term^term".
-- Every term is quoted, which makes it an exact-name search. Leveling consumables for a Warrior, using the
-- original game's item names; anything Forever renamed or removed just finds nothing.
return {
  {
    name = "Schizzle's Warrior Leveling",
    items = {
      "Minor Healing Potion",      -- healing potions, level 1 up
      "Lesser Healing Potion",
      "Healing Potion",
      "Greater Healing Potion",
      "Superior Healing Potion",
      "Major Healing Potion",
      "Elixir of Lion's Strength", -- Strength elixirs
      "Elixir of Ogre's Strength",
      "Elixir of Giants",
      "Elixir of Minor Agility",   -- Agility elixirs (crit)
      "Elixir of Agility",
      "Elixir of the Mongoose",
      "Rough Sharpening Stone",    -- blade sharpening stones by level
      "Coarse Sharpening Stone",
      "Heavy Sharpening Stone",
      "Solid Sharpening Stone",
      "Dense Sharpening Stone",
      "Heavy Linen Bandage",       -- bandages (First Aid)
      "Heavy Wool Bandage",
      "Heavy Silk Bandage",
      "Heavy Mageweave Bandage",
      "Heavy Runecloth Bandage",
      "Linen Bag",                 -- bags
      "Woolen Bag",
      "Mageweave Bag",
      "Runecloth Bag",
    },
  },
}
