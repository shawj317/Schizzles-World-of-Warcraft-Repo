# Schizzle's TSM: Battle Pets (MoP Classic)

Part of [Schizzle's TSM](../README.md).

**227 cageable battle pet species (p:) and 102 tradeable pet items (i:)** in 8 subgroups. Audited against the MoP Classic client data (wago.tools BattlePetSpecies, Item/ItemSparse, ItemEffect and SpellEffect, build 5.5.4.70631).

- **A species is included** when it can be caged: the not-tradeable (0x10) and hidden (0x20) flags are both clear, and it has a source in MoP Classic. Wild-caught pets are never cageable in MoP, so there is no wild subgroup.
- **A companion item is included** when it is a Companion Pets item that is not soulbound or deprecated, and it teaches a pet that can be obtained in MoP Classic. The unlearned item sells on the AH separately from the caged pet. TSM treats `i:` (the item) and `p:` (the caged pet) as different items, so both can be in the group. A few items (Mechanical Chicken, Singing Cricket Cage, Darkmoon Glowfly, Stunted Direhorn) teach pets that can't be caged once learned, but the item can be sold.
- **Crafted pet items stay in their profession group**, following the "crafted items go to the maker" rule: Engineering 10, Enchanting 2, Jewelcrafting 2, Inscription 2 (listed below). The caged versions of those pets (`p:`) are in **Profession Pets**. No item appears in both a pets string and a profession string.

## Files

| Subgroup | Species | Items | Import string | What's in it |
|---|---|---|---|---|
| High Value | 26 | 12 | [`groups/pets/schizzles-tsm-pets-high-value.txt`](../groups/pets/schizzles-tsm-pets-high-value.txt) | Data-driven (v2.2): any pet whose realm value is at least 7,500g **and** whose region sale rate is at least 0.03, plus the TCG/promo pets (no other home). Realm value = realm market value, else realm historical, capped at 2x region market; pets with no realm price use 0.8x region market. Matched first, so these are never in another subgroup. |
| Vendor Pets | 56 | 42 | [`groups/pets/schizzles-tsm-pets-vendor.txt`](../groups/pets/schizzles-tsm-pets-vendor.txt) | Pets and companion items bought from vendors (gold or reputation). Classic vendor-flip items such as the cat carriers and parrot cages. |
| Profession Pets | 28 | 5 | [`groups/pets/schizzles-tsm-pets-profession.txt`](../groups/pets/schizzles-tsm-pets-profession.txt) | Caged pets made by professions (Engineering, Tailoring, Jewelcrafting, Enchanting, Inscription, Archaeology), plus companion items not owned by a profession group. |
| World Drops & Quests | 21 | 16 | [`groups/pets/schizzles-tsm-pets-world-drops.txt`](../groups/pets/schizzles-tsm-pets-world-drops.txt) | Old world through Cataclysm drops and quest rewards. |
| Raid & Dungeon Drops | 35 | 3 | [`groups/pets/schizzles-tsm-pets-raid-dungeon.txt`](../groups/pets/schizzles-tsm-pets-raid-dungeon.txt) | Pets from raid and dungeon bosses. |
| Pandaria Drops & Quests | 29 | 6 | [`groups/pets/schizzles-tsm-pets-pandaria.txt`](../groups/pets/schizzles-tsm-pets-pandaria.txt) | Pandaria drops, rares and quest rewards. |
| Holiday & Events | 32 | 17 | [`groups/pets/schizzles-tsm-pets-holiday-events.txt`](../groups/pets/schizzles-tsm-pets-holiday-events.txt) | World events (Hallow's End, Winter Veil, Lunar Festival, Noblegarden and others) and the Darkmoon Faire. |
| Pet Supplies | 0 | 1 | [`groups/pets/schizzles-tsm-pets-supplies.txt`](../groups/pets/schizzles-tsm-pets-supplies.txt) | Tradeable pet-battle supplies. Only the Flawless Battle-Stone qualifies: the typed/Polished/Perfect battle-stones, pet treats and pet bandages are all soulbound. |
| **All battle pets** | **227** | **102** | [`groups/pets/schizzles-tsm-battle-pets-all.txt`](../groups/pets/schizzles-tsm-battle-pets-all.txt) | Every subgroup above, nested under **Schizzle's TSM > Battle Pets** |

## How to import

1. Type `/tsm`, open the **Groups** tab, and click **Import Group**.
2. **Everything:** paste `schizzles-tsm-battle-pets-all.txt`. It creates **Schizzle's TSM > Battle Pets** with every subgroup. If you also imported `schizzles-tsm-all-professions.txt`, it lands under the same **Schizzle's TSM** parent.
3. **Only some subgroups:** paste the per-subgroup files you want. Each one creates **Battle Pets > (subgroup name)**. If TSM creates a second **Battle Pets** group instead of merging, drag the subgroup into the first one.
4. Use either the all string or the per-subgroup strings, not both. Remove the old v1 **Pets** group first, or let the import move the pets.
5. Attach your Auctioning operation to **Battle Pets**. The subgroups inherit it.

## High Value (38)

Rule: realm value ≥ 7,500g and region sale rate ≥ 0.03, or a TCG/promo pet. `[home: …]` shows the subgroup the pet would otherwise be in. Values are AH price stats from the TSM AppData snapshot of Nov 1 2026 (they change daily).

| Name | TSM ID | Source | Realm value | Region sale rate |
|---|---|---|---|---|
| Ashleaf Spriteling | p:1323 | Drop: Leafmender / Zone: Timeless Isle [home: Pandaria Drops & Quests] | 23,431g | 0.500 |
| Bananas | p:156 | Trading Card Game: Through the Dark Portal | TCG/promo rule |  |
| Captured Firefly | i:29960 | companion item (teaches Firefly) [home: World Drops & Quests] | 23,584g | 0.037 |
| Cat Carrier (Black Tabby) | i:8491 | companion item (teaches Black Tabby Cat) [home: World Drops & Quests] | 11,268g | 0.142 |
| Clockwork Gnome | p:277 | Profession: Archaeology [home: Profession Pets] | 8,577g | 0.285 |
| Darkmoon Eye | p:1063 | Drop: Darkmoon Pet Supplies [home: Holiday & Events] | 13,719g | 0.071 |
| Darkmoon Rabbit | p:848 | Drop: Darkmoon Rabbit / Zone: Darkmoon Island [home: Holiday & Events] | 17,275g | 0.260 |
| Eye of the Legion | p:348 | Trading Card Game: Timewalkers: War of the Anicents | TCG/promo rule |  |
| Feline Familiar | i:70908 | companion item (teaches Feline Familiar) [home: Holiday & Events] | 8,485g | 0.054 |
| Feline Familiar | p:319 | World Event: Hallow's End / Vendor: Chub / Zone: Tirisfal Glades / Cost: 150 / / Vendor: Dorothy / Zone: Stormwind City / Cost: 150 [home: Holiday & Events] | 8,002g | 0.272 |
| Festival Lantern | p:342 | World Event: Lunar Festival / Vendor: Valadar Starsong / Zone: Moonglade / Cost: 50 [home: Holiday & Events] | 17,579g | 1.000 |
| Firefly | p:146 | Drop: Bogflare Needler / Zone: Zangarmarsh [home: World Drops & Quests] | 7,850g | 0.062 |
| Gahz'rooki | p:1237 | Vendor: Ravika / Zone: Durotar / Cost: 1 / / Vendor: Tenuki / Zone: Durotar / Cost: 1 [home: Vendor Pets] | 23,392g | 0.034 |
| Gregarious Grell | p:333 | Trading Card Game: Crown of the Heavens | TCG/promo rule |  |
| Gu'chi Swarmling | p:1345 | Drop: Gu'chi the Swarmbringer / Zone: Timeless Isle [home: Pandaria Drops & Quests] | 8,941g | 0.500 |
| Gundrak Hatchling | i:48116 | companion item (teaches Gundrak Hatchling) [home: World Drops & Quests] | 10,204g | 1.000 |
| Gundrak Hatchling | p:234 | Drop: Gundrak Raptor / Zone: Zul'Drak [home: World Drops & Quests] | 11,557g | 1.000 |
| Jadefire Spirit | p:1348 | Drop: Spirit of Jadefire / Zone: Timeless Isle [home: Pandaria Drops & Quests] | 25,527g | 0.041 |
| Kovok | p:1334 | Drop: Paragons of the Klaxxi / Raid: Siege of Orgrimmar [home: Raid & Dungeon Drops] | 45,117g | 1.000 |
| Lumpy | p:337 | World Event: Feast of Winter Veil [home: Holiday & Events] | 11,040g | 0.045 |
| Macabre Marionette | p:1351 | World Event: Day of the Dead [home: Holiday & Events] | 25,277g | 0.047 |
| Magical Crawdad | p:132 | Profession: Fishing: Fishing (430) / Zone: Terokkar Forest (Fishing Nodes) [home: Profession Pets] | 33,773g | 1.000 |
| Mojo | p:165 | Drop: Forest Frog / Zone: Zul'Aman [home: Raid & Dungeon Drops] | 11,575g | 0.045 |
| Moon Moon | i:101570 | companion item (teaches Moon Moon) [home: Holiday & Events] | 28,273g | 0.111 |
| Mulgore Hatchling | i:44980 | companion item (teaches Mulgore Hatchling) [home: Vendor Pets] | 9,839g | 1.000 |
| Parrot Cage (Hyacinth Macaw) | i:8494 | companion item (teaches Hyacinth Macaw) [home: World Drops & Quests] | 15,092g | 0.052 |
| Pierre | p:1204 | Profession: Engineering [home: Profession Pets] | 20,965g | 0.046 |
| Rascal-Bot | p:1256 | Profession: Engineering [home: Profession Pets] | 15,484g | 0.066 |
| Rotten Helper Box | i:104317 | companion item (teaches Rotten Little Helper) [home: Holiday & Events] | 50,155g | 0.062 |
| Skunky Alemental | p:1336 | Drop: Zhu-Gon the Sour / Zone: Timeless Isle [home: Pandaria Drops & Quests] | 9,939g | 0.083 |
| Son of Animus | p:1183 | Drop: Animus / Zone: Throne of Thunder [home: Raid & Dungeon Drops] | 13,805g | 0.200 |
| Sprite Darter Hatchling | p:87 | Drop: World Drop / Zone: Feralas [home: World Drops & Quests] | 13,782g | 0.166 |
| Tiny Crimson Whelpling | i:8499 | companion item (teaches Crimson Whelpling) [home: World Drops & Quests] | 19,785g | 0.363 |
| Tiny Goldfish | i:85447 | companion item (teaches Tiny Goldfish) [home: Vendor Pets] | 8,056g | 0.071 |
| Tiny Red Carp | i:94932 | companion item (teaches Tiny Red Carp) [home: Profession Pets] | 8,726g | 0.070 |
| Tiny Red Carp | p:1206 | Profession: Fishing [home: Profession Pets] | 10,048g | 0.031 |
| Tirisfal Batling | i:44971 | companion item (teaches Tirisfal Batling) [home: Vendor Pets] | 7,597g | 0.125 |
| Vengeful Porcupette | p:1344 | Vendor: Speaker Gulan / Zone: Timeless Isle [home: Vendor Pets] | 20,000g | 0.300 |

## Vendor Pets (98)

| Name | TSM ID | Source |
|---|---|---|
| Albino Snake | i:44822 | companion item (teaches Albino Snake) |
| Albino Snake | p:74 | Vendor: Breanni / Zone: Dalaran / Cost: 50 |
| Ammen Vale Lashling | i:44984 | companion item (teaches Ammen Vale Lashling) |
| Ammen Vale Lashling | p:212 | Vendor: Irisee / Zone: Icecrown / Cost: 40 |
| Ancona Chicken | i:11023 | companion item (teaches Ancona Chicken) |
| Ancona Chicken | p:52 | Vendor: "Plucky" Johnson / Zone: Thousand Needles / Cost: 1 |
| Black Kingsnake | i:10360 | companion item (teaches Black Kingsnake) |
| Black Kingsnake | p:75 | Vendor: Xan'tish / Zone: Orgrimmar / Cost: 50 |
| Blue Clockwork Rocket Bot | p:254 | Vendor: World Vendors / Cost: 50 |
| Blue Dragonhawk Hatchling | i:29958 | companion item (teaches Blue Dragonhawk Hatchling) |
| Blue Dragonhawk Hatchling | p:145 | Vendor: Dealer Rashaad / Zone: Netherstorm / Cost: 10 |
| Blue Moth | p:138 | Vendor: Sixx / Zone: The Exodar / Cost: 50 |
| Blue Moth Egg | i:29901 | companion item (teaches Blue Moth) |
| Bombay Cat | p:40 | Vendor: Donni Anthania / Zone: Elwynn Forest / Cost: 40 |
| Brown Prairie Dog | p:70 | Vendor: Halpa, Naleen / Zone: Mulgore / Cost: 50 |
| Brown Rabbit | p:137 | Vendor: Dealer Rashaad / Zone: Netherstorm / Cost: 10 |
| Brown Rabbit Crate | i:29364 | companion item (teaches Brown Rabbit) |
| Brown Snake | i:10361 | companion item (teaches Brown Snake) |
| Brown Snake | p:77 | Vendor: Xan'tish / Zone: Orgrimmar / Cost: 50 |
| Calico Cat | p:224 | Vendor: Breanni / Zone: Crystalsong Forest / Cost: 50 |
| Cat Carrier (Bombay) | i:8485 | companion item (teaches Bombay Cat) |
| Cat Carrier (Calico Cat) | i:46398 | companion item (teaches Calico Cat) |
| Cat Carrier (Cornish Rex) | i:8486 | companion item (teaches Cornish Rex Cat) |
| Cat Carrier (Orange Tabby) | i:8487 | companion item (teaches Orange Tabby Cat) |
| Cat Carrier (Siamese) | i:8490 | companion item (teaches Siamese Cat) |
| Cat Carrier (Silver Tabby) | i:8488 | companion item (teaches Silver Tabby Cat) |
| Cat Carrier (White Kitten) | i:8489 | companion item (teaches White Kitten) |
| Cockatiel | p:47 | Vendor: Harry No-Hooks, Narkk / Zone: The Cape of Stranglethorn / Cost: 40 |
| Cornish Rex Cat | p:41 | Vendor: Donni Anthania / Zone: Elwynn Forest / Cost: 40 |
| Crimson Lasher | p:318 | Vendor: Ayla Shadowstorm / Zone: Molten Front / Cost: 1500 |
| Crimson Snake | i:10392 | companion item (teaches Crimson Snake) |
| Crimson Snake | p:78 | Vendor: Dealer Rashaad / Zone: Netherstorm / Cost: 50 / / Vendor: Xan'tish / Zone: Orgrimmar / Cost: 50 |
| Dun Morogh Cub | i:44970 | companion item (teaches Dun Morogh Cub) |
| Dun Morogh Cub | p:205 | Vendor: Derrick Brindlebeard / Zone: Icecrown / Cost: 40 |
| Durotar Scorpion | i:44973 | companion item (teaches Durotar Scorpion) |
| Durotar Scorpion | p:207 | Vendor: Freka Bloodaxe / Zone: Icecrown / Cost: 40 |
| Elwynn Lamb | i:44974 | companion item (teaches Elwynn Lamb) |
| Elwynn Lamb | p:209 | Vendor: Corporal Arthur Flew / Zone: Icecrown / Cost: 40 |
| Enchanted Broom | i:44982 | companion item (teaches Enchanted Broom) |
| Enchanted Broom | p:213 | Vendor: Trellis Morningsun / Zone: Icecrown / Cost: 40 |
| Ghostly Skull | p:190 | Vendor: Darahir / Zone: Crystalsong Forest / Cost: 40 |
| Gilnean Raven | p:630 | Vendor: Will Larsons / Zone: Darkshore |
| Golden Dragonhawk Hatchling | i:29953 | companion item (teaches Golden Dragonhawk Hatchling) |
| Golden Dragonhawk Hatchling | p:142 | Vendor: Jilanne / Zone: Eversong Woods / Cost: 50 |
| Great Horned Owl | i:8500 | companion item (teaches Great Horned Owl) |
| Great Horned Owl | p:68 | Vendor: Shylenai / Zone: Teldrassil / Cost: 50 |
| Harmonious Porcupette | p:1346 | Vendor: Mistweaver Ku / Zone: Timeless Isle / Faction: Shaohao - Pathwalker |
| Hawk Owl | i:8501 | companion item (teaches Hawk Owl) |
| Hawk Owl | p:67 | Vendor: Shylenai / Zone: Teldrassil / Cost: 50 |
| Hyjal Bear Cub | p:317 | Vendor: Varlan Highbough / Zone: Molten Front / Cost: 1500 |
| Jade Crane Chick | i:88148 | companion item (teaches Jade Crane Chick) |
| Jade Crane Chick | p:792 | Vendor: Audrey Burnhep, Varzok / Zone: Stormwind, Orgrimmar / Cost: 50 |
| Mana Wyrmling | i:29363 | companion item (teaches Mana Wyrmling) |
| Mana Wyrmling | p:136 | Vendor: Dealer Rashaad / Zone: Netherstorm / Cost: 40 |
| Mechanopeep | i:45002 | companion item (teaches Mechanopeep) |
| Mechanopeep | p:215 | Vendor: Rillie Spindlenut / Zone: Icecrown |
| Mulgore Hatchling | p:210 | Vendor: Doru Thunderhorn / Zone: Icecrown / Cost: 40 |
| Nether Ray Fry | p:186 | Vendor: Grella / Zone: Terokkar Forest / Faction: Sha'tari Skyguard - Exalted / Cost: 40 |
| Obsidian Hatchling | i:48120 | companion item (teaches Obsidian Hatchling) |
| Obsidian Hatchling | p:236 | Vendor: Breanni / Zone: Crystalsong Forest / Cost: 50 |
| Orange Tabby Cat | p:43 | Vendor: Donni Anthania, Steven Lisbane / Zone: Elwynn Forest / Cost: 40 |
| Parrot Cage (Cockatiel) | i:8496 | companion item (teaches Cockatiel) |
| Parrot Cage (Senegal) | i:8495 | companion item (teaches Senegal) |
| Pengu | p:198 | Vendor: Sairuk / Zone: Dragonblight / Faction: The Kalu'ak - Exalted / Cost: 12 / / Vendor: Tanaika / Zone: Howling Fjord / Faction: The Kalu'ak - Exalted / Cost: 12 |
| Prairie Dog Whistle | i:10394 | companion item (teaches Brown Prairie Dog) |
| Rabbit Crate (Snowshoe) | i:8497 | companion item (teaches Snowshoe Rabbit) |
| Red Dragonhawk Hatchling | i:29956 | companion item (teaches Red Dragonhawk Hatchling) |
| Red Dragonhawk Hatchling | p:143 | Vendor: Jilanne / Zone: Eversong Woods / Cost: 50 |
| Red Moth | p:139 | Vendor: Dealer Rashaad / Zone: Netherstorm / Cost: 10 |
| Red Moth Egg | i:29902 | companion item (teaches Red Moth) |
| Rustberg Gull | p:271 | Vendor: Quartermaster Brazie / Zone: Tol Barad Peninsula / Faction: Baradin's Wardens - Honored / Cost: 50 |
| Searing Scorchling | p:172 | Vendor: Zen'Vorka / Zone: Molten Front / Cost: 30 |
| Sen'jin Fetish | i:45606 | companion item (teaches Sen'jin Fetish) |
| Sen'jin Fetish | p:218 | Vendor: Samamba / Zone: Icecrown / Cost: 40 |
| Senegal | p:51 | Vendor: Narkk, Harry No-Hooks / Zone: The Cape of Stranglethorn / / / Vendor: Dealer Rashaad / Zone: Netherstorm / Cost: 40 |
| Shimmering Wyrmling | i:46820 | companion item (teaches Shimmering Wyrmling) |
| Shimmering Wyrmling | i:46821 | companion item (teaches Shimmering Wyrmling) |
| Shimmering Wyrmling | p:229 | Vendor: Hiren Loresong / Zone: Icecrown / Faction: The Silver Covenant - Exalted / Cost: 40 |
| Shore Crawler | p:629 | Vendor: Matty / Zone: Orgrimmar |
| Siamese Cat | p:44 | Vendor: Dealer Rashaad / Zone: Netherstorm / Cost: 60 |
| Silver Dragonhawk Hatchling | i:29957 | companion item (teaches Silver Dragonhawk Hatchling) |
| Silver Dragonhawk Hatchling | p:144 | Vendor: Jilanne / Zone: Eversong Woods / Cost: 50 |
| Silver Tabby Cat | p:45 | Vendor: Donni Anthania / Zone: Elwynn Forest / Cost: 40 |
| Snowshoe Rabbit | p:72 | Vendor: Yarlyn Amberstill / Zone: Dun Morogh / Cost: 20 |
| Teldrassil Sproutling | i:44965 | companion item (teaches Teldrassil Sproutling) |
| Teldrassil Sproutling | p:204 | Vendor: Rook Hawkfist / Zone: Icecrown / Cost: 40 |
| Tiny Goldfish | p:652 | Vendor: Nat Pagle / Zone: Krasarang Wilds / Faction: The Anglers - Honored / Cost: 250 |
| Tiny Sporebat | p:167 | Vendor: Mycah / Zone: Zangarmarsh / Faction: Sporeggar - Exalted / Cost: 30 |
| Tirisfal Batling | p:206 | Vendor: Eliza Killian / Zone: Icecrown / Cost: 40 |
| Undercity Cockroach | i:10393 | companion item (teaches Undercity Cockroach) |
| Undercity Cockroach | p:55 | Vendor: Dealer Rashaad / Zone: Netherstorm / Cost: 50 / / Vendor: Jeremiah Payson / Zone: Tirisfal Glades / Cost: 50 |
| White Kitten | p:46 | Vendor: Lil Timmy / Zone: Stormwind City / Cost: 60 |
| White Moth | p:141 | Vendor: Sixx / Zone: The Exodar / Cost: 50 |
| White Moth Egg | i:29904 | companion item (teaches White Moth) |
| Winterspring Cub | i:69239 | companion item (teaches Winterspring Cub) |
| Winterspring Cub | p:306 | Vendor: Michelle De Rum / Zone: Winterspring / Cost: 50 |
| Yellow Moth | p:140 | Vendor: Sixx / Zone: The Exodar / Cost: 50 |
| Yellow Moth Egg | i:29903 | companion item (teaches Yellow Moth) |

## Profession Pets (33)

| Name | TSM ID | Source |
|---|---|---|
| Chuck | p:174 | Profession: Fishing / Zone: Shattrath |
| Crawling Claw | p:264 | Profession: Archaeology |
| De-Weaponized Mechanical Companion | p:262 | Profession: Engineering |
| Enchanted Lantern | p:267 | Profession: Enchanting (525) / Formula: Enchanted Lantern |
| Fossilized Hatchling | p:266 | Profession: Archaeology |
| Giant Sewer Rat | p:193 | Profession: Fishing / Zone: Dalaran |
| Imperial Moth | i:90900 | companion item (teaches Imperial Moth) |
| Imperial Moth | p:1039 | Profession: Tailoring (Imperial Silk) |
| Imperial Silkworm | i:90902 | companion item (teaches Imperial Silkworm) |
| Imperial Silkworm | p:1040 | Profession: Tailoring (Imperial Silk) |
| Jade Owl | p:845 | Profession: Jewelcrafting |
| Lifelike Toad | p:95 | Profession: Engineering |
| Lil' Smoky | p:86 | Profession: Engineering |
| Magic Lamp | p:292 | Profession: Enchanting |
| Mechanical Pandaren Dragonling | p:844 | Profession: Engineering |
| Mechanical Squirrel | p:39 | Profession: Engineering |
| Muckbreath | p:164 | Profession: Fishing / Zone: Shattrath |
| Personal World Destroyer | p:261 | Profession: Engineering |
| Pet Bombling | p:85 | Profession: Engineering |
| Pterrordax Hatchling | p:309 | Profession: Archaeology |
| Sapphire Cub | p:846 | Profession: Jewelcrafting |
| Sea Pony | p:340 | Profession: Fishing / Zone: Darkmoon Island |
| Snarly | p:173 | Profession: Fishing / Zone: Shattrath |
| Strand Crawler | p:211 | Profession: Fishing / Zone: Northrend, Stormwind, Orgrimmar |
| Tiny Blue Carp | i:94933 | companion item (teaches Tiny Blue Carp) |
| Tiny Blue Carp | p:1207 | Profession: Fishing |
| Tiny Green Carp | i:94934 | companion item (teaches Tiny Green Carp) |
| Tiny Green Carp | p:1208 | Profession: Fishing |
| Tiny White Carp | i:94935 | companion item (teaches Tiny White Carp) |
| Tiny White Carp | p:1209 | Profession: Fishing |
| Toothy | p:163 | Profession: Fishing / Zone: Shattrath |
| Tranquil Mechanical Yeti | p:116 | Profession: Engineering |
| Voodoo Figurine | p:310 | Profession: Archaeology |

## World Drops & Quests (37)

| Name | TSM ID | Source |
|---|---|---|
| Azure Whelpling | i:34535 | companion item (teaches Azure Whelpling) |
| Azure Whelpling | p:57 | Drop: World Drop / Zone: Winterspring |
| Black Tabby Cat | p:42 | Drop: World Drop / Zone: Hillsbrad Foothills |
| Cobra Hatchling | i:39898 | companion item (teaches Cobra Hatchling) |
| Cobra Hatchling | p:197 | Drop: Mysterious Egg |
| Crimson Whelpling | p:58 | Drop: World Drop / Zone: Wetlands |
| Dark Whelpling | i:10822 | companion item (teaches Dark Whelpling) |
| Dark Whelpling | p:56 | Drop: Whelplings / Zone: Wetlands, Dustwallow Marsh, Badlands, Burning Steppes |
| Darting Hatchling | i:48112 | companion item (teaches Darting Hatchling) |
| Darting Hatchling | p:232 | Drop: Dart's Nest / Zone: Dustwallow Marsh |
| Disgusting Oozeling | i:20769 | companion item (teaches Disgusting Oozeling) |
| Disgusting Oozeling | p:114 | Drop: World Drop / Creature: Oozes, Slimes and Worms |
| Elementium Geode | i:67282 | companion item (teaches Elementium Geode) |
| Elementium Geode | p:293 | Drop: Elementium Vein, Rich Elementium Vein / Zone: Deepholm, Twilight Highlands, Uldum |
| Emerald Whelpling | p:59 | Drop: Noxious Whelp / Zone: Feralas |
| Fox Kit | p:278 | Drop: Baradin Fox / Zone: Tol Barad Peninsula |
| Hyacinth Macaw | p:49 | Drop: World Drop / Zone: Northern Stranglethorn, The Cape of Stranglethorn |
| Leaping Hatchling | i:48118 | companion item (teaches Leaping Hatchling) |
| Leaping Hatchling | p:235 | Drop: Takk's Nest / Zone: The Barrens |
| Mechanical Chicken | i:10398 | companion item (teaches Mechanical Chicken); the learned pet cannot be caged |
| Mr. Grubbs | p:286 | Drop: World Drop: Eastern Plaguelands (requires Fiona's Lucky Charm) |
| Porcupette | i:89587 | companion item (teaches Porcupette) |
| Porcupette | p:381 | Drop: Sack of Pet Supplies |
| Proto-Drake Whelp | i:44721 | companion item (teaches Proto-Drake Whelp) |
| Proto-Drake Whelp | p:196 | Drop: Mysterious Egg |
| Ravasaur Hatchling | i:48122 | companion item (teaches Ravasaur Hatchling) |
| Ravasaur Hatchling | p:237 | Drop: Ravasaur Matriarch's Nest / Zone: Un'goro Crater |
| Razormaw Hatchling | i:48124 | companion item (teaches Razormaw Hatchling) |
| Razormaw Hatchling | p:238 | Drop: Razormaw Matriarch's Nest / Zone: Wetlands |
| Razzashi Hatchling | i:48126 | companion item (teaches Razzashi Hatchling) |
| Razzashi Hatchling | p:239 | Drop: World Drop / Zone: Northern Stranglethorn, The Cape of Stranglethorn |
| Tickbird Hatchling | i:39896 | companion item (teaches Tickbird Hatchling) |
| Tickbird Hatchling | p:194 | Drop: Mysterious Egg |
| Tiny Emerald Whelpling | i:8498 | companion item (teaches Emerald Whelpling) |
| Tiny Shale Spider | p:279 | Drop: Jadefang / Zone: Deepholm |
| White Tickbird Hatchling | i:39899 | companion item (teaches White Tickbird Hatchling) |
| White Tickbird Hatchling | p:195 | Drop: Mysterious Egg |

## Raid & Dungeon Drops (38)

| Name | TSM ID | Source |
|---|---|---|
| Anubisath Idol | p:1155 | Drop: Emperor Vek'lor / Zone: Ahn'Qiraj |
| Ashstone Core | p:1150 | Drop: Golemagg the Incinerator / Zone: Molten Core |
| Blackfuse Bombling | p:1322 | Drop: Siegecrafter Blackfuse / Raid: Siege of Orgrimmar |
| Chrominius | p:1152 | Drop: Chromaggus / Zone: Blackwing Lair |
| Coilfang Stalker | p:1232 | Drop: Lady Vashj / Zone: Serpentshrine Cavern |
| Corefire Imp | p:1149 | Drop: Magmadar / Zone: Molten Core |
| Death Talon Whelpguard | p:1153 | Drop: Broodlord Lashlayer / Zone: Blackwing Lair |
| Deviate Hatchling | i:48114 | companion item (teaches Deviate Hatchling) |
| Deviate Hatchling | p:233 | Drop: Deviate Guardian, Deviate Ravager / Zone: Wailing Caverns |
| Droplet of Y'Shaarj | p:1331 | Drop: Sha of Pride / Raid: Siege of Orgrimmar / Difficulty: Flexible, Normal or Heroic |
| Fiendish Imp | p:1229 | Drop: Terestian Illhoof / Zone: Karazhan |
| Fungal Abomination | p:1144 | Drop: Loatheb / Zone: Naxxramas |
| Giant Bone Spider | p:1143 | Drop: Maexxna / Zone: Naxxramas |
| Gooey Sha-ling | p:1332 | Drop: Sha of Pride / Raid: Siege of Orgrimmar / Difficulty: LFR and Flexible |
| Green Wing Macaw | p:50 | Drop: Defias Pirate / Zone: The Deadmines |
| Harbinger of Flame | p:1147 | Drop: Sulfuron Harbinger / Zone: Molten Core |
| Ji-Kun Hatchling | p:1202 | Drop: Ji-Kun / Zone: Throne of Thunder |
| Lesser Voidcaller | p:1234 | Drop: High Astromancer Solarian / Zone: Tempest Keep |
| Lil' Bad Wolf | p:1226 | Drop: The Big Bad Wolf / Zone: Karazhan |
| Living Fluid | p:1243 | Drop: Primordius / Zone: Throne of Thunder / Difficulty: Looking For Raid |
| Living Sandling | p:1177 | Drop: Throne of Thunder |
| Menagerie Custodian | p:1227 | Drop: The Curator / Zone: Karazhan |
| Mini Mindslayer | p:1156 | Drop: The Prophet Skeram / Zone: Ahn'Qiraj |
| Netherspace Abyssal | p:1228 | Drop: Prince Malchezaar / Zone: Karazhan |
| Parrot Cage (Green Wing Macaw) | i:8492 | companion item (teaches Green Wing Macaw) |
| Phoenix Hatchling | p:175 | Drop: Kael'thas Sunstrider / Zone: Magisters' Terrace |
| Phoenix Hawk Hatchling | p:1235 | Drop: Al'ar / Zone: Tempest Keep |
| Pocket Reaver | p:1233 | Drop: Void Reaver / Zone: Tempest Keep |
| Pygmy Direhorn | i:94574 | companion item (teaches Pygmy Direhorn) |
| Pygmy Direhorn | p:1200 | Drop: Horridon / Zone: Throne of Thunder |
| Smolderweb Hatchling | p:90 | Drop: Mother Smolderweb / Zone: Lower Blackrock Spire |
| Stitched Pup | p:1146 | Drop: Gluth / Zone: Naxxramas |
| Tainted Waveling | p:1231 | Drop: Hydross the Unstable / Zone: Serpentshrine Cavern |
| Tideskipper | p:1230 | Drop: Morogrim Tidewalker / Zone: Serpentshrine Cavern |
| Untamed Hatchling | p:1151 | Drop: Razorgore the Untamed / Zone: Blackwing Lair |
| Viscidus Globule | p:1154 | Drop: Viscidus / Zone: Ahn'Qiraj |
| Viscous Horror | p:1244 | Drop: Primordius / Zone: Throne of Thunder / Difficulty: Normal or Heroic |
| Worg Pup | p:89 | Drop: Quartermaster Zigris / Zone: Lower Blackrock Spire |

## Pandaria Drops & Quests (35)

| Name | TSM ID | Source |
|---|---|---|
| Aqua Strider | p:836 | Drop: Nalash Verdantis / Zone: Dread Wastes |
| Azure Crane Chick | p:1321 | Drop: Crane Nest / Zone: Timeless Isle |
| Dandelion Frolicker | p:1329 | Drop: Scary Sprite / Zone: Timeless Isle |
| Death Adder Hatchling | p:1330 | Drop: Imperial Python / Zone: Timeless Isle |
| Direhorn Runt | i:94573 | companion item (teaches Direhorn Runt) |
| Direhorn Runt | p:1205 | Drop: Direhorns / Zone: Isle of Giants |
| Filthling | p:1245 | Drop: Quivering Filth |
| Fishy | p:847 | Quest: Let Them Burn / Zone: The Jade Forest |
| Grinder | p:834 | Drop: Karr the Darkener / Zone: Dread Wastes |
| Gulp Froglet | p:1338 | Drop: Bufo / Pet Battle: Timeless Isle |
| Jademist Dancer | p:1333 | Drop: Jademist Dancer / Zone: Timeless Isle |
| Lil' Bling | p:1320 | Drop: Blingtron Gift Package |
| Mountain Panda | p:1198 | Quest: Beasts of Fable |
| Ominous Flame | p:1335 | Drop: Foreboding Flame / Zone: Timeless Isle |
| Pandaren Air Spirit | p:1125 | Quest: Pandaren Spirit Tamer / Zone: Vale of Eternal Blossoms |
| Pandaren Earth Spirit | p:1126 | Quest: Pandaren Spirit Tamer / Zone: Vale of Eternal Blossoms |
| Pandaren Fire Spirit | p:1124 | Quest: Pandaren Spirit Tamer / Zone: Vale of Eternal Blossoms |
| Pandaren Water Spirit | p:868 | Quest: Pandaren Spirit Tamer / Zone: Vale of Eternal Blossoms |
| Ruby Droplet | p:1328 | Drop: Garnia / Zone: Timeless Isle |
| Singing Cricket Cage | i:88147 | companion item (teaches Singing Cricket); the learned pet cannot be caged |
| Snowy Panda | p:1197 | Quest: Beasts of Fable |
| Spawn of G'nathus | i:94595 | companion item (teaches Spawn of G'nathus) |
| Spawn of G'nathus | p:1201 | Drop: G'nathus / Zone: Townlong Steppes |
| Spectral Porcupette | i:94190 | companion item (teaches Spectral Porcupette) |
| Spectral Porcupette | p:1185 | Quest: A Large Pile of Giant Dinosaur Bones / Zone: Isle Of Giants |
| Spineclaw Crab | p:1337 | Drop: Monstrous Spineclaw / Zone: Timeless Isle |
| Stunted Direhorn | i:94191 | companion item (teaches Stunted Direhorn); the learned pet cannot be caged |
| Sunfur Panda | p:1196 | Quest: Beasts of Fable |
| Sunreaver Micro-Sentry | p:1178 | Drop: Haywire Sunreaver Construct / Zone: Isle of Thunder |
| Terrible Turnip | i:85220 | companion item (teaches Terrible Turnip) |
| Terrible Turnip | p:650 | Drop: World Drop / Zone: Valley of the Four Winds |
| Zandalari Anklerender | p:1211 | Drop: Zandalari Dinomancer / Zone: Isle Of Giants |
| Zandalari Footslasher | p:1212 | Drop: Zandalari Dinomancer / Zone: Isle Of Giants |
| Zandalari Kneebiter | p:1180 | Drop: Zandalari Dinomancer / Zone: Isle Of Giants |
| Zandalari Toenibbler | p:1213 | Drop: Zandalari Dinomancer / Zone: Isle Of Giants |

## Holiday & Events (49)

| Name | TSM ID | Source |
|---|---|---|
| Captured Flame | i:23083 | companion item (teaches Spirit of Summer) |
| Clockwork Rocket Bot | p:191 | World Event: Feast of Winter Veil |
| Darkmoon Cub | p:343 | Vendor: Lhara / Zone: Darkmoon Island / Cost: 90 |
| Darkmoon Eye | i:91040 | companion item (teaches Darkmoon Eye) |
| Darkmoon Glowfly | i:91031 | companion item (teaches Darkmoon Glowfly); the learned pet cannot be caged |
| Darkmoon Hatchling | i:91003 | companion item (teaches Darkmoon Hatchling) |
| Darkmoon Hatchling | p:1061 | Vendor: Lhara / Zone: Darkmoon Island / Cost: 90 |
| Darkmoon Monkey | p:330 | Vendor: Lhara / Zone: Darkmoon Island / Cost: 90 |
| Darkmoon Rabbit | i:80008 | companion item (teaches Darkmoon Rabbit) |
| Darkmoon Tonk | p:338 | Vendor: Lhara / Zone: Darkmoon Island / Cost: 90 |
| Darkmoon Turtle | p:335 | Vendor: Lhara / Zone: Darkmoon Island / Cost: 90 |
| Darkmoon Zeppelin | p:339 | Vendor: Lhara / Zone: Darkmoon Island / Cost: 90 |
| Egbert | p:158 | World Event: Children's Week |
| Father Winter's Helper | p:119 | World Event: Feast of Winter Veil |
| Festival Lantern | i:74611 | companion item (teaches Festival Lantern) |
| Frigid Frostling | p:253 | World Event: Midsummer Fire Festival |
| Green Helper Box | i:21301 | companion item (teaches Father Winter's Helper) |
| Jingling Bell | i:21308 | companion item (teaches Winter Reindeer) |
| Legs | p:308 | World Event: Children's Week |
| Lunar Lantern | i:74610 | companion item (teaches Lunar Lantern) |
| Lunar Lantern | p:341 | World Event: Lunar Festival / Vendor: Valadar Starsong / Zone: Moonglade / Cost: 50 |
| Moon Moon | p:1276 | Drop: Moonfang / Zone: Darkmoon Island |
| Mr. Wiggles | p:126 | World Event: Children's Week |
| Peanut | p:159 | World Event: Children's Week |
| Peddlefeet | p:122 | World Event: Love is in the Air / Vendor: Lovely Merchant / Cost: 40 |
| Pint-Sized Pink Pachyderm | i:46707 | companion item (teaches Pint-Sized Pink Pachyderm) |
| Pint-Sized Pink Pachyderm | p:166 | World Event: Brewfest / Vendor: Belbi Quikswitch / Zone: Dun Morogh / Cost: 100 / / Vendor: Bliz Fixwidget / Zone: Durotar / Cost: 100 |
| Red Helper Box | i:21305 | companion item (teaches Winter's Little Helper) |
| Rotten Little Helper | p:1349 | Quest: World Event: Feast of Winter Veil |
| Scooter the Snail | p:289 | World Event: Children's Week |
| Sinister Squashling | i:33154 | companion item (teaches Sinister Squashling) |
| Sinister Squashling | p:162 | World Event: Hallow's End |
| Snowman Kit | i:21309 | companion item (teaches Tiny Snowman) |
| Speedy | p:125 | World Event: Children's Week |
| Spirit of Summer | p:128 | World Event: Midsummer Fire Festival / Vendor: Midsummer Merchant / Cost: 350 |
| Spring Rabbit | p:200 | World Event: Noblegarden / Vendor: Noblegarden Merchant / Cost: 100 |
| Spring Rabbit's Foot | i:44794 | companion item (teaches Spring Rabbit) |
| Tiny Snowman | p:117 | World Event: Feast of Winter Veil |
| Toxic Wasteling | p:251 | World Event: Love is in the Air |
| Tree Frog | p:65 | Vendor: Flik / Zone: Darkmoon Island / Cost: 1 |
| Tree Frog Box | i:11026 | companion item (teaches Tree Frog) |
| Truesilver Shafted Arrow | i:22235 | companion item (teaches Peddlefeet) |
| Whiskers the Rat | p:127 | World Event: Children's Week |
| Willy | p:157 | World Event: Children's Week |
| Winter Reindeer | p:118 | World Event: Feast of Winter Veil |
| Winter's Little Helper | p:120 | World Event: Feast of Winter Veil |
| Wolpertinger | p:153 | World Event: Brewfest |
| Wood Frog | p:64 | Vendor: Flik / Zone: Darkmoon Island / Cost: 1 |
| Wood Frog Box | i:11027 | companion item (teaches Wood Frog) |

## Pet Supplies (1)

| Name | TSM ID | Source |
|---|---|---|
| Flawless Battle-Stone | i:92741 | Tradeable battle-stone (upgrades a pet to rare) |

## Crafted pet items kept in profession groups

| Item | TSM ID | Group |
|---|---|---|
| Mechanical Squirrel Box | i:4401 | Engineering |
| Pet Bombling | i:11825 | Engineering |
| Lil' Smoky | i:11826 | Engineering |
| Lifelike Mechanical Toad | i:15996 | Engineering |
| Tranquil Mechanical Yeti | i:21277 | Engineering |
| Personal World Destroyer | i:59597 | Engineering |
| De-Weaponized Mechanical Companion | i:60216 | Engineering |
| Enchanted Lantern | i:67274 | Enchanting |
| Magic Lamp | i:67275 | Enchanting |
| Jade Owl | i:82774 | Jewelcrafting |
| Sapphire Cub | i:82775 | Jewelcrafting |
| Mechanical Pandaren Dragonling | i:87526 | Engineering |
| Yu'lon Kite | i:89367 | Inscription |
| Chi-Ji Kite | i:89368 | Inscription |
| Pierre | i:94903 | Engineering |
| Rascal-Bot | i:100905 | Engineering |

## Not included

### Pet items

- Cat Carrier (Corrupted Kitten) (i:11903): teaches no obtainable battle pet species
- Pet Fish (i:13342): teaches no obtainable battle pet species
- Pet Stone (i:13343): teaches no obtainable battle pet species
- Turtle Egg (Albino) (i:18963): teaches no obtainable battle pet species
- Turtle Egg (Loggerhead) (i:18964): teaches no obtainable battle pet species
- Turtle Egg (Hawksbill) (i:18965): teaches no obtainable battle pet species
- Turtle Egg (Leatherback) (i:18966): teaches no obtainable battle pet species
- Turtle Egg (Olive) (i:18967): teaches no obtainable battle pet species
- Baby Shark (i:21168): pet is hidden/unobtainable in MoP Classic
- Silver Shafted Arrow (i:22200): teaches no obtainable battle pet species
- Baby Coralshell Turtle (i:39148): teaches no obtainable battle pet species
- XS-001 Constructor Bot (i:45942): pet is hidden/unobtainable in MoP Classic
- Guardian Cub (i:72068): pet is hidden/unobtainable in MoP Classic
- Typed, Polished and Perfect Battle-Stones, Marked Flawless Battle-Stones, Lesser Pet Treat, Pet Treat and Battle Pet Bandage: soulbound

### Species that cannot be caged

656 species in the client data are left out. Reasons:


#### Wild-caught (wild pets cannot be caged in MoP) (318)

Adder (p:635), Alpine Chipmunk (p:487), Alpine Foxling (p:724), Alpine Foxling Kit (p:725), Alpine Hare (p:441), Amber Moth (p:732), Amethyst Shale Hatchling (p:838), Amethyst Spiderling (p:716), Amorous Rooster (p:705), Anodized Robo Cub (p:1163), Arcane Eye (p:1160), Arctic Fox Kit (p:558), Arctic Hare (p:641), Ash Lizard (p:632), Ash Spiderling (p:427), Ash Viper (p:425), Ashwing Moth (p:1324), Baby Ape (p:411), Bandicoon (p:706), Bandicoon Kit (p:707), Bat (p:626), Beetle (p:406), Biletoad (p:649), Black Lamb (p:374), Black Rat (p:398), Bleat (p:1001), Blighted Squirrel (p:455), Blighthawk (p:456), Blizzy (p:927), Borean Marmot (p:639), Brood of Mothallus (p:995), Brown Marmot (p:449), Bucktooth Flapper (p:380), C92 Annihilator (p:1354), Carrion Rat (p:540), Cat (p:459), Cheetah Cub (p:474), Chi-Chi, Hatchling of Chi-Ji (p:1311), Chicken (p:646), Chirrup (p:1012), Clefthoof Runt (p:518), Clouded Hedgehog (p:742), Cockroach (p:393), Cogblade Raptor (p:1164), Coral Adder (p:562), Coral Snake (p:488), Creepy Crawly (p:468), Crested Owl (p:507), Crimson (p:1130), Crimson Geode (p:559), Crimson Moth (p:421), Crimson Shale Hatchling (p:554), Crow (p:1068), Crunchy Scorpion (p:745), Crusher (p:1009), Crystal Beetle (p:556), Crystal Spider (p:634), Dancing Water Skimmer (p:751), Darkmoon Glowfly (p:1062), Darkshore Cub (p:508), Darkwidow (p:880), Darnak the Tunneler (p:1137), Death's Head Cockroach (p:755), Deepholm Cockroach (p:555), Desert Spider (p:484), Devouring Maggot (p:523), Diemetradon Hatchling (p:504), Doopy (p:1247), Dos-Ryga (p:1193), Dragonbone Hatchling (p:537), Dung Beetle (p:467), Dusk Spiderling (p:396), Dusty (p:1135), Effervescent Glowfly (p:747), Elder Python (p:1181), Electrified Razortooth (p:1179), Elfin Rabbit (p:479), Emerald Boa (p:631), Emerald Proto-Whelp (p:1167), Emerald Shale Hatchling (p:837), Emerald Turtle (p:564), Emperor Crab (p:746), Eternal Strider (p:383), Fawn (p:447), Fel Flame (p:519), Festering Maggot (p:457), Feverbite Hatchling (p:714), Fezwick (p:1066), Fire Beetle (p:415), Fire-Proof Roach (p:541), Fjord Rat (p:644), Fjord Worg Pup (p:529), Flamering Moth (p:1325), Flayer Youngling (p:514), Fledgling Buzzard (p:395), Fledgling Nether Ray (p:521), Fluxfire Feline (p:1162), Forest Moth (p:478), Forest Spiderling (p:407), Frog (p:495), Fungal Moth (p:756), Garden Frog (p:569), Garden Moth (p:753), Gazelle Fawn (p:477), Gilded Moth (p:748), Giraffe Calf (p:475), Glowy (p:1131), Gold Beetle (p:430), Golden Civet (p:749), Golden Civet Kitten (p:750), Gorespine (p:1187), Grassland Hopper (p:733), Grasslands Cottontail (p:443), Grey Moth (p:464), Greyhoof (p:1189), Grizzly Squirrel (p:647), Grotto Vole (p:539), Grove Viper (p:571), Hare (p:448), Harpy Youngling (p:1157), Highlands Mouse (p:550), Highlands Skunk (p:823), Highlands Turkey (p:645), Honky-Tonk (p:1067), Hopling (p:835), Horned Lizard (p:851), Horny Toad (p:483), Huge Toad (p:648), Imperial Eagle Chick (p:534), Infected Fawn (p:628), Infected Squirrel (p:627), Infested Bear Cub (p:453), Infinite Whelpling (p:1161), Irradiated Roach (p:442), Jade Oozeling (p:446), Judgement (p:1065), Jumping Spider (p:699), Jungle Darter (p:565), Jungle Grub (p:678), Ka'wi the Gorger (p:1129), Kafi (p:1192), King Snake (p:438), Kuitan Mongoose (p:680), Kun-Lai Runt (p:1166), Lapin (p:1002), Larva (p:461), Lava Beetle (p:429), Lava Crab (p:423), Leopard Scorpid (p:545), Leopard Tree Frog (p:702), Lightstalker (p:1000), Little Black Ram (p:437), Lizard Hatchling (p:408), Locust (p:543), Lofty Libram (p:1159), Long-tailed Mole (p:404), Lost of Lordaeron (p:458), Lucky Yi (p:1190), Luyu Moth (p:718), Mac Frog (p:542), Maggot (p:450), Malayan Quillrat (p:708), Malayan Quillrat Pup (p:709), Marley (p:1132), Marsh Fiddler (p:710), Masked Tanuki (p:570), Masked Tanuki Pup (p:703), Mei Li Sparkler (p:722), Minfernal (p:500), Mirror Strider (p:566), Moccasin (p:422), Mollus (p:1005), Molten Hatchling (p:428), Mongoose (p:737), Mongoose Pup (p:739), Mountain Cottontail (p:391), Mountain Skunk (p:633), Mouse (p:385), Mutilator (p:1007), Nanners (p:885), Needleback (p:999), Nether Faerie Dragon (p:557), Nether Roach (p:638), Nexus Whelpling (p:1165), Nightstalker (p:947), Nitun (p:1194), No-No (p:1188), Nordrassil Wisp (p:547), Oasis Moth (p:544), Oily Slimeling (p:530), Parrot (p:403), Piqua (p:1003), Plains Monitor (p:726), Polly (p:409), Prairie Dog (p:386), Prairie Mouse (p:727), Qiraji Guardling (p:513), Rabbit (p:378), Rabid Nut Varmint 5000 (p:472), Rapana Whelk (p:743), Rat (p:417), Rat Snake (p:399), Rattlesnake (p:431), Ravager Hatchling (p:465), Red-Tailed Chipmunk (p:452), Redridge Rat (p:392), Resilient Roach (p:744), Restless Shadeling (p:439), Roach (p:424), Robo-Chick (p:471), Rock Viper (p:482), Ruby Sapling (p:460), Rusty Snail (p:496), Sand Kitten (p:491), Sandy Petrel (p:573), Savory Beetle (p:717), Scalded Basilisk Hatchling (p:528), Scarab Hatchling (p:512), Scorpid (p:414), Scorpling (p:416), Scourged Whelpling (p:538), Sea Gull (p:560), Shimmershell Snail (p:493), Shore Crab (p:388), Shrine Fly (p:754), Shy Bandicoon (p:677), Sidewinder (p:511), Sifang Otter (p:711), Sifang Otter Pup (p:712), Silent Hedgehog (p:741), Silithid Hatchling (p:494), Silkbead Snail (p:568), Silky Moth (p:503), Singing Cricket (p:820), Skitterer Xi'a (p:1195), Skittering Cavern Crawler (p:637), Skunk (p:397), Skyshaper (p:994), Skywisp Moth (p:1326), Sludgy (p:1134), Small Frog (p:419), Snake (p:387), Snow Cub (p:440), Snowshoe Hare (p:640), Snowy Owl (p:69), Softshell Snapling (p:713), Spawn of Onyxia (p:489), Spider (p:412), Spiky Lizard (p:433), Spiny Lizard (p:466), Spiny Terrapin (p:723), Spirebound Crab (p:572), Spirit Crab (p:463), Sporeling Sprout (p:515), Spotted Bell Frog (p:502), Squirrel (p:379), Stinkbug (p:492), Stone Armadillo (p:485), Stormlash (p:1011), Stormwind Rat (p:675), Stowaway Rat (p:553), Strand Crab (p:401), Stripe-Tailed Scorpid (p:432), Stunted Shardhorn (p:532), Stunted Yeti (p:1158), Summit Kid (p:679), Sumprush Rodent (p:1128), Swamp Croaker (p:1182), Swamp Moth (p:402), Szechuan Chicken (p:728), Tainted Cockroach (p:497), Tainted Moth (p:498), Tainted Rat (p:499), Temple Snake (p:567), Thundering Serpent Hatchling (p:802), Thundertail Flapper (p:1175), Ti'un the Wanderer (p:1191), Tiny Bog Beast (p:509), Tiny Harvester (p:389), Tiny Twister (p:445), Tiptoe (p:1133), Toad (p:420), Tol'vir Scarab (p:546), Tolai Hare (p:729), Tolai Hare Pup (p:730), Topaz Shale Hatchling (p:480), Tree Python (p:405), Tundra Penguin (p:536), Turkey (p:525), Turquoise Turtle (p:473), Twilight Beetle (p:469), Twilight Fiendling (p:552), Twilight Iguana (p:505), Twilight Spider (p:470), Unborn Val'kyr (p:1238), Undercity Rat (p:454), Venomspitter Hatchling (p:506), Wanderer's Festival Hatchling (p:1013), Warpstalker Hatchling (p:517), Water Snake (p:418), Water Waveling (p:535), Wharf Rat (p:410), Whiskers (p:1010), Whispertail (p:1136), Widow Spiderling (p:400), Widowling (p:1259), Wild Crimson Hatchling (p:819), Wild Golden Hatchling (p:818), Wild Jade Hatchling (p:817), Wild Silkworm (p:715), Wildhammer Gryphon Hatchling (p:548), Xu-Fu, Cub of Xuen (p:1267), Yakrat (p:740), Yellow-Bellied Bullfrog (p:752), Yellow-Bellied Marmot (p:549), Yu'la, Broodling of Yu'lon (p:1317), Zao, Calfling of Niuzao (p:1319), Zooey Snake (p:731)

#### Flagged not tradeable (cannot be caged) (272)

Acidous (p:897), Alex (p:1301), Alliance Balloon (p:331), Ambershell (p:901), Amythel (p:987), Angara (p:1258), Anklor (p:941), Arcanus (p:964), Argent Gruntling (p:216), Argent Squire (p:214), Armadillo Pup (p:272), Ashtail (p:981), Au (p:1278), Backswimmer Timbertooth (p:3326), Baneling (p:903), Banks (p:1279), Beacon (p:925), Beakmaster X-225 (p:978), Beamer (p:922), Bishibosh (p:948), Blackfang (p:881), Blaze (p:913), Bleakspinner (p:935), Blight (p:974), Bloom (p:977), Blossoming Ancient (p:1248), Blue Mini Jouster (p:259), Bolo (p:1292), Bonkers (p:1343), Boomy Jr. (p:832), Bounder (p:902), Brewly (p:1280), Burgle (p:888), Cadavus (p:976), Carpe Diem (p:1296), Carrion (p:936), Chaos (p:1271), Char (p:3024), Chi-Chi, Hatchling of Chi-Ji (p:1303), Chi-Ji Kite (p:849), Chirps (p:1281), Cho'guana (p:915), Chomps (p:961), Chubbs (p:1352), Cindy (p:1299), Clatter (p:989), Clock'em (p:1142), Cluckatron (p:908), Clucks (p:875), Comet (p:946), Constrictor (p:899), Core Hound Pup (p:244), Corpsefeeder (p:932), Crafty (p:1257), Cragmaw (p:959), Creepy Crate (p:321), Croaker (p:942), Crystallus (p:984), Curious Oracle Hatchling (p:225), Curious Wolvar Pup (p:226), Cypress (p:4273), Dah'da (p:1300), Dampwing (p:943), Dark Phoenix Hatchling (p:270), Darkmoon Balloon (p:336), Deathy (p:294), Delta (p:5120), Diamond (p:1006), Dinner (p:967), Dipsy (p:878), Dor the Wall (p:992), Dr. Stinky (p:833), Dragon Kite (p:169), Dramaticus (p:957), Dread Hatchling (p:1386), Drogar (p:973), ED-005 (p:952), Elayna (p:666), Emeralda (p:883), Essence of Competition (p:180), Ethereal Soul-Trader (p:183), Eyegouger (p:887), Fangor (p:993), Fangs (p:873), Fetish Shaman (p:346), Firetooth (p:911), Fishmonger May (p:4897), Flameclaw (p:912), Fleshrender (p:975), Flipsy (p:877), Flufftail (p:879), Flurky (p:4233), Flutterby (p:894), Foe Reaper 800 (p:876), Fracture (p:983), Frostmaw (p:928), Frosty (p:188), Fungor (p:953), Garnestrasz (p:939), Gizmo (p:909), Glimmer (p:906), Glitterfly (p:955), Glub (p:4236), Gnasher (p:960), Gobbles (p:966), Gold Mini Jouster (p:260), Golden Pig (p:170), Goliath (p:951), Grizzle (p:979), Grunty (p:228), Guild Herald (p:282), Guild Herald (p:283), Guild Page (p:280), Guild Page (p:281), Gurky (p:121), Hatewalker (p:923), Helios (p:986), Hippogryph Hatchling (p:130), Hoplet (p:4235), Horde Balloon (p:332), Ignious (p:945), Incinderous (p:980), Indigon (p:917), Jack (p:949), Jade Tiger (p:231), Jadefire (p:963), Jubling (p:106), Kali (p:982), Knowledge (p:1283), Lacewing (p:924), Lady Burninator (p:827), Lashtail Hatchling (p:307), Li (p:1293), Lil' B (p:1277), Lil' Deathwing (p:268), Lil' Oondasta (p:1339), Lil' Tarecgosa (p:320), Lil' Wrathion (p:4274), Longneck (p:893), Lord Landslide (p:828), Lucky (p:155), Lucky (p:4211), Lucky Quilen Cub (p:671), Lurky (p:111), Madam Flapsalot (p:829), Mechanical Chicken (p:83), Mini Diablo (p:93), Mini Thor (p:258), Mini Tyrael (p:189), Miniwing (p:149), Miss Mystical (p:831), Mister Pinch (p:896), Moltar (p:944), Monte (p:1289), Moonstalker (p:884), Mort (p:968), Mr. Chilly (p:192), Mr. Growls (p:825), Mrs. Skitters (p:826), Ms. Croaker (p:824), Muffin (p:800), Mumtar (p:889), Murkablo (p:329), Murkalot (p:1364), Murki (p:1168), Murkimus Tyrannicus (p:1255), Murkimus the Gladiator (p:217), Murky (p:107), Nairn (p:1288), Netherbite (p:962), Netherwhelp (p:131), Obsidion (p:937), Odoron (p:898), Onyx Panther (p:240), Oozer (p:895), Panda Cub (p:92), Pandaren Air Spirit (p:1140), Pandaren Earth Spirit (p:1141), Pandaren Fire Spirit (p:1139), Pandaren Water Spirit (p:1138), Panther Cub (p:301), Patience (p:1284), PattyMack 2.0 - WildBattlePet Test (p:444), Pinchy the Plunderer (p:4532), Pinky (p:5080), Plague (p:916), Plaguebringer (p:934), Plop (p:931), Plump Turkey (p:201), Poley (p:124), Pounder (p:1008), Prancer (p:904), Prince Wart (p:958), Pyth (p:991), Rasp (p:905), Red Cricket (p:1042), Red Panda (p:1176), Reven (p:4683), Rikki (p:1290), Ripper (p:891), River (p:1297), Rocket Chicken (p:168), Rockhide (p:900), Rot (p:971), Ruby (p:985), Sa'bak's Favored (p:4850), Screamer (p:1269), Sha-Warped Beaky (p:5051), Shadow (p:2062), Sheep (p:394), Silver Pig (p:171), Singing Sunflower (p:291), Sir Buckethead (p:830), Siren (p:997), Skimmer (p:1004), Sky Lantern (p:1350), Sleet (p:972), Slither (p:872), Smoldering Courage (p:4998), Socks (p:1291), Spectral Tiger Cub (p:242), Spike (p:890), Spirit of Competition (p:179), Spirus (p:1298), Sploder (p:950), Spooky Strangler (p:970), Spring (p:990), Springtail (p:892), Starshard Whelpling (p:4962), Stitch (p:969), Stompy (p:956), Stormoen (p:1287), Subject 142 (p:933), Summer (p:1286), Sunflutter Driftmoth (p:5113), Swoopy (p:4585), Teensy (p:874), Terky (p:1073), The Gurkster (p:375), The Sire's Ghastly Screecher (p:5042), Tiny Flamefly (p:287), Tiny Green Dragon (p:757), Tiny Red Dragon (p:758), Tinygos (p:929), Tonsa (p:1282), Toothbreaker (p:996), Treasure Goblin (p:1365), Trike (p:1268), Tripod (p:954), Tuskarr Kite (p:241), Twilight (p:988), Ultramus (p:921), Vampiric Batling (p:187), Veridia (p:938), Warble (p:965), Warbot (p:227), Webwinder (p:882), Westfall Chicken (p:84), Whirls (p:907), Willow (p:926), Wisdom (p:1285), Withers (p:220), Woodcarver (p:998), Xelnath (p:2), Xu-Fu, Cub of Xuen (p:1266), Yen (p:1295), Young Beaky (p:886), Yu'la, Broodling of Yu'lon (p:1304), Yu'lon Kite (p:850), Zao, Calfling of Niuzao (p:1305), Zergling (p:94), Zipao Tiger (p:247)

#### Hidden/unobtainable in MoP Classic (24)

Baby Shark (p:115), Cockatoo (p:4172), Deer (p:390), Elven Wisp (p:4185), Gazelle (p:476), Green Balloon (p:344), Green Water Snake (p:4182), Guardian Cub (p:311), Gusting Grimoire (p:1174), Jacob the Test Seagull (p:462), Landro's Lichling (p:302), Landro's Lil' XT (p:285), Mule Deer (p:486), Murkimus the Gladiator (p:257), Nightsaber Cub (p:303), PattyMack - WildBattlePet Test (p:354), Purple Puffer (p:328), Rabbot (p:510), Ram (p:434), Ribbon Snake (p:4183), Sand Scarab (p:665), Scarlet Snake (p:4184), Toy RC Mortar Tank (p:4206), Yellow Balloon (p:345)

#### Achievement reward (not cageable) (17)

Arfus (p:4329), Baby Blizzard Bear (p:202), Brilliant Kaliri (p:325), Celestial Dragon (p:255), Feral Vermling (p:821), Jade Tentacle (p:856), Kirin Tor Familiar (p:199), Little Fawn (p:203), Mr. Bigglesworth (p:1145), Nuts (p:323), Onyxian Whelpling (p:243), Pebble (p:265), Perky Pug (p:250), Stinker (p:160), Stunted Direhorn (p:1184), Tito (p:1236), Venus (p:855)

#### Blizzard store pet (not cageable) (17)

Alterac Brew-Pup (p:1363), Auspicious Pixiu (p:4902), Cenarion Hatchling (p:316), Cinder Kitten (p:1117), Gryphon Hatchling (p:245), Lil' Coalee (p:4907), Lil' K.T. (p:249), Lil' Ragnaros (p:297), Lil' XT (p:256), Moonkin Hatchling (p:296), Moonkin Hatchling (p:298), Pandaren Monk (p:248), Roofus (p:5000), Smoldering Valor (p:4862), Soul of the Aspects (p:347), Spectral Cub (p:1127), Wind Rider Cub (p:246)

#### No source in MoP Classic (not obtainable) (5)

Alarming Clockbot (p:4228), Otter Pup (p:384), Raccoon Kit (p:382), Ravager Hatchling (p:4204), XS-001 Constructor Bot (p:4229)

#### Classic-only promo species; cageability in MoP Classic unconfirmed (3)

Joyous (p:4734), Pebble (p:4234), Timbered Air Snakelet (p:4685)

## Changes from v1

- The species audit against the 5.5.4 client data found no species to add or remove. The 227 cageable species are unchanged, and no wild, achievement or store pet was in the old group.
- Added 102 tradeable pet items (`i:`): 101 companion items (unlearned vendor, drop, event and quest pet items) plus the Flawless Battle-Stone.
- New subgroups. "Vendor & Reputation" became **Vendor Pets**. "World Events" became **Holiday & Events** and now also holds the Darkmoon Faire pets. "Old World to Cata Drops" became **World Drops & Quests**. "Crafted & Profession" became **Profession Pets**. **Pet Supplies** is new.
- The group root changed from **Pets** to **Schizzle's TSM > Battle Pets** (or **Battle Pets** for the per-subgroup files).

## Operations (v2.2)

The old "Suggested Auctioning operation" text is replaced by real importable operations. See [../operations/README.md](../operations/README.md).

- **Battle Pets** (every subgroup except High Value): Auctioning **Schizzle Battle Pets**, Shopping **Schizzle Buy Pets**.
- **High Value:** Auctioning **Schizzle High Value**.
- Both post one pet at a time for 48h and **post at the minimum price** when undercut below it (they never skip).

Test any string with `/tsm price [shift-click caged pet] <string>`.
