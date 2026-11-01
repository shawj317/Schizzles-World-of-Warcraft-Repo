# Schizzle's TSM Groups

TradeSkillMaster group import strings for MoP Classic: trade goods (Mining, Herbalism, Cloth, Cooking), Alchemy, Engineering Blasting Powders, and cageable battle pets.

## Files
| File | Imports as |
|---|---|
| `schizzles-tsm-mining-group.txt` | Mining |
| `schizzles-tsm-herbalism-group.txt` | Herbalism |
| `schizzles-tsm-cloth-group.txt` | Cloth |
| `schizzles-tsm-cooking-group.txt` | Cooking |
| `schizzles-tsm-tradegoods-all.txt` | Trade Goods (all four above, nested) |
| `schizzles-tsm-alchemy-group.txt` | Alchemy |
| `schizzles-tsm-engineering-blasting-powders.txt` | Engineering > Blasting Powders |
| `schizzles-tsm-pets-group.txt` | Pets (7 subgroups) |

## Import
1. Type `/tsm` and open **Groups**.
2. Click **Import Group**, paste the whole contents of one file (one line, no line breaks) and confirm.
3. Repeat for each file you want. Use either the four separate trade goods files or `schizzles-tsm-tradegoods-all.txt`, not both.

## Version history
- **v1 (Nov 2026):** Trade Goods (Mining, Herbalism, Cloth, Cooking), Alchemy, Blasting Powders and Pets groups built from the MoP Classic 5.5.4 client data.
- **v1 rename (Nov 1 2026):** files and docs renamed with the "Schizzle's" prefix. The import strings are unchanged, and the in-game group names stay the same.

## Schizzle's TSM Trade Goods Groups (MoP Classic)

536 tradeable items in 4 top-level groups. Item IDs come from the MoP Classic client data (wago.tools Item + ItemSparse, build 5.5.4.70631). Every name was matched exactly. Soulbound items (bonding 1) are excluded, and so are items flagged deprecated or with placeholder/test names. No item ID appears in more than one group.

### Files

- `schizzles-tsm-mining-group.txt` imports as **Mining**.
- `schizzles-tsm-herbalism-group.txt` imports as **Herbalism**.
- `schizzles-tsm-cloth-group.txt` imports as **Cloth**.
- `schizzles-tsm-cooking-group.txt` imports as **Cooking**.
- `schizzles-tsm-tradegoods-all.txt` has all four in one string, nested under a parent group **Trade Goods**. Drag each one to the Base Group if you want them as top-level groups.

### Import steps

1. Type `/tsm`, open the **Groups** tab, and click **Import Group** at the top of the group tree.
2. Paste one file's whole contents (one line) and confirm. The summary shows the group and item counts.
3. Repeat for each file, or import the combined one once.
4. If any items already belong to another of your groups, TSM leaves them there. To move them, select them in the new group and use **Move items**.
5. Attach your Auctioning operations to the top-level groups. Subgroups inherit them.

### Counts

| Group | Subgroup | Items |
|---|---|---|
| Mining | Ore | 25 |
| Mining | Bars | 32 |
| Mining | Stone | 7 |
| Mining | Elementals | 11 |
| Mining | Gems & Prospecting | 62 |
| Mining | Bags & Supplies | 14 |
| **Mining** | **total** | **151** |
| Herbalism | Herbs - Classic | 30 |
| Herbalism | Herbs - Burning Crusade | 12 |
| Herbalism | Herbs - Wrath | 10 |
| Herbalism | Herbs - Cataclysm | 7 |
| Herbalism | Herbs - Pandaria | 7 |
| Herbalism | Herb Fragments (5.4) | 6 |
| Herbalism | Pigments | 18 |
| Herbalism | Inks | 20 |
| Herbalism | Elementals | 5 |
| Herbalism | Herb Bags | 7 |
| **Herbalism** | **total** | **122** |
| Cloth | Raw Cloth | 10 |
| Cloth | Bolts | 12 |
| Cloth | Specialty Cloth & Silk | 15 |
| Cloth | Tailoring Bags | 27 |
| **Cloth** | **total** | **64** |
| Cooking | Meat | 59 |
| Cooking | Fish | 51 |
| Cooking | Pandaria Fish | 9 |
| Cooking | Eggs | 5 |
| Cooking | Clams & Shellfish | 13 |
| Cooking | Pandaria Farm Produce | 10 |
| Cooking | Ironpaw & Specialty Ingredients | 16 |
| Cooking | Cooked Food | 36 |
| **Cooking** | **total** | **199** |

### Mining

#### Mining`Ore (25)

- Copper Ore (i:2770)
- Tin Ore (i:2771)
- Silver Ore (i:2775)
- Iron Ore (i:2772)
- Gold Ore (i:2776)
- Mithril Ore (i:3858)
- Truesilver Ore (i:7911)
- Thorium Ore (i:10620)
- Dark Iron Ore (i:11370)
- Fel Iron Ore (i:23424)
- Adamantite Ore (i:23425)
- Khorium Ore (i:23426)
- Eternium Ore (i:23427)
- Cobalt Ore (i:36909)
- Saronite Ore (i:36912)
- Titanium Ore (i:36910)
- Obsidium Ore (i:53038)
- Elementium Ore (i:52185)
- Pyrite Ore (i:52183)
- Ghost Iron Ore (i:72092)
- Kyparite (i:72093)
- Black Trillium Ore (i:72094)
- White Trillium Ore (i:72103)
- Ghost Iron Nugget (i:97512)
- Kyparite Fragment (i:97546)

#### Mining`Bars (32)

- Copper Bar (i:2840)
- Tin Bar (i:3576)
- Bronze Bar (i:2841)
- Silver Bar (i:2842)
- Iron Bar (i:3575)
- Gold Bar (i:3577)
- Steel Bar (i:3859)
- Mithril Bar (i:3860)
- Truesilver Bar (i:6037)
- Thorium Bar (i:12359)
- Dark Iron Bar (i:11371)
- Arcanite Bar (i:12360)
- Enchanted Thorium Bar (i:12655)
- Fel Iron Bar (i:23445)
- Adamantite Bar (i:23446)
- Eternium Bar (i:23447)
- Felsteel Bar (i:23448)
- Khorium Bar (i:23449)
- Hardened Adamantite Bar (i:23573)
- Hardened Khorium (i:35128)
- Cobalt Bar (i:36916)
- Saronite Bar (i:36913)
- Titanium Bar (i:41163)
- Titansteel Bar (i:37663)
- Obsidium Bar (i:54849)
- Elementium Bar (i:52186)
- Hardened Elementium Bar (i:53039)
- Pyrium Bar (i:51950)
- Truegold (i:58480)
- Ghost Iron Bar (i:72096)
- Trillium Bar (i:72095)
- Living Steel (i:72104)

#### Mining`Stone (7)

- Rough Stone (i:2835)
- Coarse Stone (i:2836)
- Heavy Stone (i:2838)
- Solid Stone (i:7912)
- Dense Stone (i:12365)
- Small Obsidian Shard (i:22202)
- Large Obsidian Shard (i:22203)

#### Mining`Elementals (11)

- Mote of Earth (i:22573)
- Mote of Fire (i:22574)
- Crystallized Earth (i:37701)
- Crystallized Fire (i:37702)
- Volatile Earth (i:52327)
- Volatile Fire (i:52325)
- Elemental Earth (i:7067)
- Primal Earth (i:22452)
- Primal Fire (i:21884)
- Eternal Earth (i:35624)
- Eternal Fire (i:36860)

#### Mining`Gems & Prospecting (62)

- Malachite (i:774)
- Tigerseye (i:818)
- Shadowgem (i:1210)
- Moss Agate (i:1206)
- Lesser Moonstone (i:1705)
- Jade (i:1529)
- Citrine (i:3864)
- Aquamarine (i:7909)
- Star Ruby (i:7910)
- Large Opal (i:12799)
- Blue Sapphire (i:12361)
- Huge Emerald (i:12364)
- Azerothian Diamond (i:12800)
- Arcane Crystal (i:12363)
- Blood Garnet (i:23077)
- Flame Spessarite (i:21929)
- Golden Draenite (i:23112)
- Deep Peridot (i:23079)
- Azure Moonstone (i:23117)
- Shadow Draenite (i:23107)
- Living Ruby (i:23436)
- Noble Topaz (i:23439)
- Dawnstone (i:23440)
- Talasite (i:23437)
- Star of Elune (i:23438)
- Nightseye (i:23441)
- Bloodstone (i:36917)
- Huge Citrine (i:36929)
- Sun Crystal (i:36920)
- Dark Jade (i:36932)
- Chalcedony (i:36923)
- Shadow Crystal (i:36926)
- Scarlet Ruby (i:36918)
- Monarch Topaz (i:36930)
- Autumn's Glow (i:36921)
- Forest Emerald (i:36933)
- Sky Sapphire (i:36924)
- Twilight Opal (i:36927)
- Carnelian (i:52177)
- Hessonite (i:52181)
- Alicite (i:52179)
- Jasper (i:52182)
- Zephyrite (i:52178)
- Nightstone (i:52180)
- Inferno Ruby (i:52190)
- Ember Topaz (i:52193)
- Amberjewel (i:52195)
- Dream Emerald (i:52192)
- Ocean Sapphire (i:52191)
- Demonseye (i:52194)
- Pandarian Garnet (i:76136)
- Sunstone (i:76134)
- Lapis Lazuli (i:76133)
- Alexandrite (i:76137)
- Roguestone (i:76135)
- Tiger Opal (i:76130)
- Primordial Ruby (i:76131)
- Vermilion Onyx (i:76140)
- Sun's Radiance (i:76142)
- Wild Jade (i:76139)
- River's Heart (i:76138)
- Imperial Amethyst (i:76141)

#### Mining`Bags & Supplies (14)

- Mining Sack (i:30746)
- Reinforced Mining Bag (i:29540)
- Mammoth Mining Bag (i:38347)
- Triple-Reinforced Mining Bag (i:70137)
- "Carriage - Christina" Precious Metal Bag (i:67396)
- Gem Pouch (i:30747)
- Bag of Jewels (i:24270)
- Luxurious Silk Gem Bag (i:70138)
- "Carriage - Exclusive" Gem Studded Clutch (i:67392)
- Mining Pick (i:2901)
- Coal (i:3857)
- Weak Flux (i:2880)
- Strong Flux (i:3466)
- Elemental Flux (i:18567)

### Herbalism

#### Herbalism`Herbs - Classic (30)

- Peacebloom (i:2447)
- Silverleaf (i:765)
- Earthroot (i:2449)
- Mageroyal (i:785)
- Briarthorn (i:2450)
- Swiftthistle (i:2452)
- Stranglekelp (i:3820)
- Bruiseweed (i:2453)
- Wild Steelbloom (i:3355)
- Grave Moss (i:3369)
- Kingsblood (i:3356)
- Liferoot (i:3357)
- Fadeleaf (i:3818)
- Goldthorn (i:3821)
- Khadgar's Whisker (i:3358)
- Dragon's Teeth (i:3819)
- Firebloom (i:4625)
- Purple Lotus (i:8831)
- Arthas' Tears (i:8836)
- Sungrass (i:8838)
- Blindweed (i:8839)
- Ghost Mushroom (i:8845)
- Gromsblood (i:8846)
- Golden Sansam (i:13464)
- Dreamfoil (i:13463)
- Mountain Silversage (i:13465)
- Sorrowmoss (i:13466)
- Icecap (i:13467)
- Black Lotus (i:13468)
- Wildvine (i:8153)

#### Herbalism`Herbs - Burning Crusade (12)

- Bloodthistle (i:22710)
- Felweed (i:22785)
- Dreaming Glory (i:22786)
- Ragveil (i:22787)
- Flame Cap (i:22788)
- Terocone (i:22789)
- Ancient Lichen (i:22790)
- Netherbloom (i:22791)
- Nightmare Vine (i:22792)
- Mana Thistle (i:22793)
- Fel Lotus (i:22794)
- Nightmare Seed (i:22797)

#### Herbalism`Herbs - Wrath (10)

- Goldclover (i:36901)
- Deadnettle (i:37921)
- Fire Leaf (i:39970)
- Tiger Lily (i:36904)
- Talandra's Rose (i:36907)
- Adder's Tongue (i:36903)
- Constrictor Grass (i:36902)
- Lichbloom (i:36905)
- Icethorn (i:36906)
- Frost Lotus (i:36908)

#### Herbalism`Herbs - Cataclysm (7)

- Cinderbloom (i:52983)
- Stormvine (i:52984)
- Azshara's Veil (i:52985)
- Heartblossom (i:52986)
- Deathspore Pod (i:52989)
- Twilight Jasmine (i:52987)
- Whiptail (i:52988)

#### Herbalism`Herbs - Pandaria (7)

- Green Tea Leaf (i:72234)
- Silkweed (i:72235)
- Rain Poppy (i:72237)
- Snow Lily (i:79010)
- Fool's Cap (i:79011)
- Golden Lotus (i:72238)
- Desecrated Herb (i:89639)

#### Herbalism`Herb Fragments (5.4) (6)

- Torn Green Tea Leaf (i:97619)
- Silkweed Stem (i:97621)
- Rain Poppy Petal (i:97620)
- Snow Lily Petal (i:97622)
- Fool's Cap Spores (i:97623)
- Desecrated Herb Pod (i:97624)

#### Herbalism`Pigments (18)

- Alabaster Pigment (i:39151)
- Dusky Pigment (i:39334)
- Golden Pigment (i:39338)
- Emerald Pigment (i:39339)
- Violet Pigment (i:39340)
- Silvery Pigment (i:39341)
- Nether Pigment (i:39342)
- Azure Pigment (i:39343)
- Ashen Pigment (i:61979)
- Shadow Pigment (i:79251)
- Verdant Pigment (i:43103)
- Burnt Pigment (i:43104)
- Indigo Pigment (i:43105)
- Ruby Pigment (i:43106)
- Sapphire Pigment (i:43107)
- Ebon Pigment (i:43108)
- Icy Pigment (i:43109)
- Misty Pigment (i:79253)

#### Herbalism`Inks (20)

- Ivory Ink (i:37101)
- Moonglow Ink (i:39469)
- Midnight Ink (i:39774)
- Hunter's Ink (i:43115)
- Lion's Ink (i:43116)
- Dawnstar Ink (i:43117)
- Jadefire Ink (i:43118)
- Royal Ink (i:43119)
- Celestial Ink (i:43120)
- Fiery Ink (i:43121)
- Shimmering Ink (i:43122)
- Ink of the Sky (i:43123)
- Ethereal Ink (i:43124)
- Darkflame Ink (i:43125)
- Ink of the Sea (i:43126)
- Snowfall Ink (i:43127)
- Blackfallow Ink (i:61978)
- Inferno Ink (i:61981)
- Ink of Dreams (i:79254)
- Starlight Ink (i:79255)

#### Herbalism`Elementals (5)

- Mote of Life (i:22575)
- Crystallized Life (i:37704)
- Volatile Life (i:52329)
- Primal Life (i:21886)
- Eternal Life (i:35625)

#### Herbalism`Herb Bags (7)

- Herb Pouch (i:22250)
- Cenarion Herb Bag (i:22251)
- Satchel of Cenarius (i:22252)
- Mycah's Botanical Bag (i:38225)
- Emerald Bag (i:45773)
- Hyjal Expedition Bag (i:54446)
- "Carriage - Going Green" Herb Tote Bag (i:67393)

### Cloth

#### Cloth`Raw Cloth (10)

- Linen Cloth (i:2589)
- Wool Cloth (i:2592)
- Silk Cloth (i:4306)
- Mageweave Cloth (i:4338)
- Runecloth (i:14047)
- Felcloth (i:14256)
- Netherweave Cloth (i:21877)
- Frostweave Cloth (i:33470)
- Embersilk Cloth (i:53010)
- Windwool Cloth (i:72988)

#### Cloth`Bolts (12)

- Bolt of Linen Cloth (i:2996)
- Bolt of Woolen Cloth (i:2997)
- Bolt of Silk Cloth (i:4305)
- Bolt of Mageweave (i:4339)
- Bolt of Runecloth (i:14048)
- Bolt of Netherweave (i:21840)
- Bolt of Imbued Netherweave (i:21842)
- Bolt of Soulcloth (i:21844)
- Bolt of Frostweave (i:41510)
- Bolt of Imbued Frostweave (i:41511)
- Bolt of Embersilk Cloth (i:53643)
- Bolt of Windwool Cloth (i:82441)

#### Cloth`Specialty Cloth & Silk (15)

- Mooncloth (i:14342)
- Primal Mooncloth (i:21845)
- Spellcloth (i:24271)
- Shadowcloth (i:24272)
- Ebon Felcloth (i:21883)
- Ebonweave (i:41593)
- Moonshroud (i:41594)
- Spellweave (i:41595)
- Spider's Silk (i:3182)
- Thick Spider's Silk (i:4337)
- Shadow Silk (i:10285)
- Ironweb Spider Silk (i:14227)
- Netherweb Spider Silk (i:21881)
- Iceweb Spider Silk (i:42253)
- Fiery Silk Gland (i:52341)

#### Cloth`Tailoring Bags (27)

- Linen Bag (i:4238)
- Red Linen Bag (i:5762)
- Woolen Bag (i:4240)
- Green Woolen Bag (i:4241)
- Red Woolen Bag (i:5763)
- Small Silk Pack (i:4245)
- Green Silk Pack (i:5764)
- Black Silk Pack (i:5765)
- Mageweave Bag (i:10050)
- Red Mageweave Bag (i:10051)
- Runecloth Bag (i:14046)
- Mooncloth Bag (i:14155)
- Felcloth Bag (i:21341)
- Core Felcloth Bag (i:21342)
- Netherweave Bag (i:21841)
- Imbued Netherweave Bag (i:21843)
- Ebon Shadowbag (i:21872)
- Primal Mooncloth Bag (i:21876)
- Frostweave Bag (i:41599)
- Glacial Bag (i:41600)
- Abyssal Bag (i:41597)
- Embersilk Bag (i:54443)
- Illusionary Bag (i:54444)
- Royal Satchel (i:82446)
- Enchanted Mageweave Pouch (i:22246)
- Enchanted Runecloth Bag (i:22248)
- Otherworldly Bag (i:54445)

### Cooking

#### Cooking`Meat (59)

- Chunk of Boar Meat (i:769)
- Stringy Wolf Meat (i:2672)
- Boar Ribs (i:2677)
- Crag Boar Rib (i:2886)
- Coyote Meat (i:2673)
- Kodo Meat (i:5467)
- Strider Meat (i:5469)
- Bear Meat (i:3173)
- Big Bear Meat (i:3730)
- Lean Wolf Flank (i:1015)
- Stag Meat (i:5471)
- Crocolisk Meat (i:2924)
- Tender Crocolisk Meat (i:3667)
- Lion Meat (i:3731)
- Turtle Meat (i:3712)
- Tough Condor Meat (i:1080)
- Buzzard Wing (i:3404)
- Mystery Meat (i:12037)
- Raptor Flesh (i:12184)
- Tiger Meat (i:12202)
- Red Wolf Meat (i:12203)
- Heavy Kodo Meat (i:12204)
- White Spider Meat (i:12205)
- Tender Wolf Meat (i:12208)
- Sandworm Meat (i:20424)
- Chimaerok Tenderloin (i:21024)
- Lynx Meat (i:27668)
- Bat Flesh (i:27669)
- Buzzard Meat (i:27671)
- Ravager Flesh (i:27674)
- Chunk o' Basilisk (i:27677)
- Clefthoof Meat (i:27678)
- Warped Flesh (i:27681)
- Talbuk Venison (i:27682)
- Raptor Ribs (i:31670)
- Serpent Flesh (i:31671)
- Chunk o' Mammoth (i:34736)
- Shoveltusk Flank (i:43009)
- Worm Meat (i:43010)
- Worg Haunch (i:43011)
- Rhino Meat (i:43012)
- Chilled Meat (i:43013)
- Slab of Blubber (i:38270)
- Lean Flank (i:38271)
- Bloody Giblets (i:38272)
- Toughened Flesh (i:62778)
- Monstrous Claw (i:62779)
- Snake Eye (i:62780)
- Giant Turtle Tongue (i:62781)
- Dragon Flank (i:62782)
- Basilisk "Liver" (i:62783)
- Crocolisk Tail (i:62784)
- Delicate Wing (i:62785)
- Raw Tiger Steak (i:74833)
- Mushan Ribs (i:74834)
- Raw Turtle Meat (i:74837)
- Wildfowl Breast (i:74839)
- Raw Crocolisk Belly (i:75014)
- Sirloin Steak (i:75015)

#### Cooking`Fish (51)

- Raw Brilliant Smallfish (i:6291)
- Raw Longjaw Mud Snapper (i:6289)
- Raw Slitherskin Mackerel (i:6303)
- Raw Bristle Whisker Catfish (i:6308)
- Raw Loch Frenzy (i:6317)
- Raw Rainbow Fin Albacore (i:6361)
- Raw Rockscale Cod (i:6362)
- Raw Spotted Yellowtail (i:4603)
- Raw Mithril Head Trout (i:8365)
- Raw Spinefin Halibut (i:8959)
- Raw Glossy Mightfish (i:13754)
- Raw Summer Bass (i:13756)
- Raw Redgill (i:13758)
- Raw Nightfin Snapper (i:13759)
- Raw Sunscale Salmon (i:13760)
- Raw Whitescale Salmon (i:13889)
- Raw Sagefish (i:21071)
- Raw Greater Sagefish (i:21153)
- Barbed Gill Trout (i:27422)
- Spotted Feltail (i:27425)
- Zangarian Sporefish (i:27429)
- Figluster's Mudfish (i:27435)
- Icefin Bluefish (i:27437)
- Golden Darter (i:27438)
- Furious Crawdad (i:27439)
- Huge Spotted Feltail (i:27515)
- Enormous Barbed Gill Trout (i:27516)
- Northern Icelip (i:38625)
- Deep Sea Monsterbelly (i:41800)
- Moonglow Cuttlefish (i:41801)
- Imperial Manta Ray (i:41802)
- Rockfin Grouper (i:41803)
- Icemouth Waveskipper (i:41804)
- Musselback Sculpin (i:41806)
- Dragonfin Angelfish (i:41807)
- Bonescale Snapper (i:41808)
- Glacial Salmon (i:41809)
- Fangtooth Herring (i:41810)
- Glassfin Minnow (i:41814)
- Nettlefish (i:41813)
- Sharptooth (i:53062)
- Mountain Trout (i:53063)
- Highland Guppy (i:53064)
- Albino Cavefish (i:53065)
- Blackbelly Mudfish (i:53066)
- Striped Lurker (i:53067)
- Lavascale Catfish (i:53068)
- Murglesnout (i:53069)
- Fathom Eel (i:53070)
- Algaefin Rockfish (i:53071)
- Deepsea Sagefish (i:53072)

#### Cooking`Pandaria Fish (9)

- Golden Carp (i:74866)
- Jade Lungfish (i:74856)
- Giant Mantis Shrimp (i:74857)
- Emperor Salmon (i:74859)
- Redbelly Mandarin (i:74860)
- Tiger Gourami (i:74861)
- Jewel Danio (i:74863)
- Reef Octopus (i:74864)
- Krasarang Paddlefish (i:74865)

#### Cooking`Eggs (5)

- Small Egg (i:6889)
- Raptor Egg (i:3685)
- Giant Egg (i:12207)
- Northern Egg (i:43501)
- Farm Egg (i:86100)

#### Cooking`Clams & Shellfish (13)

- Clam Meat (i:5503)
- Tangy Clam Meat (i:5504)
- Zesty Clam Meat (i:7974)
- Giant Clam Meat (i:4655)
- Jaggal Clam Meat (i:24477)
- Succulent Clam Meat (i:36782)
- Tender Crab Meat (i:12206)
- Crawler Meat (i:2674)
- Crawler Claw (i:2675)
- Darkclaw Lobster (i:13888)
- Blood Shrimp (i:62791)
- Raw Crab Meat (i:74838)
- Viseclaw Meat (i:85506)

#### Cooking`Pandaria Farm Produce (10)

- Green Cabbage (i:74840)
- Juicycrunch Carrot (i:74841)
- Mogu Pumpkin (i:74842)
- Scallions (i:74843)
- Red Blossom Leek (i:74844)
- Witchberries (i:74846)
- Jade Squash (i:74847)
- Striped Melon (i:74848)
- Pink Turnip (i:74849)
- White Turnip (i:74850)

#### Cooking`Ironpaw & Specialty Ingredients (16)

- Black Pepper (i:74661)
- Rice Flour (i:74662)
- 100 Year Soy Sauce (i:74853)
- Instant Noodles (i:74854)
- Barley (i:74832)
- Rice (i:74851)
- Yak Milk (i:74852)
- Farm Chicken (i:74659)
- Pandaren Peach (i:74660)
- Red Beans (i:85585)
- Needle Mushrooms (i:85583)
- Silkworm Pupa (i:85584)
- Ginseng (i:74845)
- Aged Balsamic Vinegar (i:102541)
- Ancient Pandaren Spices (i:102542)
- Aged Mogu'shan Cheese (i:102543)

#### Cooking`Cooked Food (36)

- Banquet of the Grill (i:87226)
- Great Banquet of the Grill (i:87228)
- Banquet of the Wok (i:87230)
- Great Banquet of the Wok (i:87232)
- Banquet of the Pot (i:87234)
- Great Banquet of the Pot (i:87236)
- Banquet of the Steamer (i:87238)
- Great Banquet of the Steamer (i:87240)
- Banquet of the Oven (i:87242)
- Great Banquet of the Oven (i:87244)
- Banquet of the Brew (i:87246)
- Great Banquet of the Brew (i:87248)
- Pandaren Banquet (i:74919)
- Great Pandaren Banquet (i:75016)
- Black Pepper Ribs and Shrimp (i:74646)
- Sea Mist Rice Noodles (i:74648)
- Mogu Fish Stew (i:74650)
- Steamed Crab Surprise (i:74653)
- Chun Tian Spring Rolls (i:74656)
- Mad Brewer's Breakfast (i:75038)
- Eternal Blossom Fish (i:74645)
- Fire Spirit Salmon (i:74652)
- Braised Turtle (i:74649)
- Twin Fish Platter (i:74655)
- Spicy Salmon (i:86073)
- Spicy Vegetable Chips (i:86074)
- Wildfowl Ginseng Soup (i:86070)
- Tangy Yogurt (i:81409)
- Peach Pie (i:81411)
- Fortune Cookie (i:62649)
- Beer-Basted Crocolisk (i:62670)
- Skewered Eel (i:62669)
- Severed Sagefish Head (i:62671)
- Baked Rockfish (i:62661)
- Blackbelly Sushi (i:62668)
- Fish Feast (i:43015)

### Skipped / not included

- **Soulbound in the game data:** Spirit of Harmony, Mote of Harmony, Imperial Silk, Celestial Cloth, Dreamcloth, Seafood Magnifique Feast, Broiled Dragon Feast.
- **Deprecated or removed** (flagged in the data): Azurite Ore/Bar, Black Iron Ore/Bar, Old Dark Iron Ore, Manticyte Bar, Titansteel (DEPRECATED), Silver Ink, Volatile Shadow, the "Deprecated ..." inks and ingots, and test items such as Test Firebloom.
- **Not a real item:** "Sha-Touched Herb" does not exist. The MoP herb from Dread Wastes is Desecrated Herb, which is included.
- **Left out on purpose:** Bloodvine (Zul'Gurub herb, removed when the zone was revamped), Froststeel Bar, Sulfuron Ingot, Elementium Ingot and Enchanted Elementium Bar (raid or legendary items), the Folded Ghost Iron / Heavy Ghost Iron Bar Blacksmithing intermediates, vendor threads, and Engineer's Ink.
- **Cooking filler left out:** gray vendor-trash meats, the "Northrend Meat 01-12" placeholders, and the event-only Turkey items.
- **Possibly 5.4-only:** the Herb Fragments subgroup (Torn Green Tea Leaf etc.), plus Ghost Iron Nugget and Kyparite Fragment. If those fragments don't drop on your realm's current patch, TSM just shows no prices for them.

## Schizzle's TSM Alchemy Group (MoP Classic 5.5.4)

**269 items** in `schizzles-tsm-alchemy-group.txt`, imports as **Alchemy**. These are every tradeable item that an Alchemy recipe (SkillLine 171) creates in the 5.5.4.70631 client data. Soulbound items are excluded. Items already in the Mining, Herbalism, Cloth or Cooking groups are left out, so no ID is in two groups.

Import the same way as before: `/tsm` > Groups > Import Group > paste > confirm.

### Counts

| Subgroup | Items |
|---|---|
| Alchemy`Pandaria`Flasks | 5 |
| Alchemy`Pandaria`Elixirs - Battle | 5 |
| Alchemy`Pandaria`Elixirs - Guardian | 3 |
| Alchemy`Pandaria`Potions - Healing & Mana | 4 |
| Alchemy`Pandaria`Potions - Combat | 4 |
| Alchemy`Pandaria`Potions - Utility | 3 |
| Alchemy`Cataclysm`Flasks | 5 |
| Alchemy`Cataclysm`Elixirs - Battle | 5 |
| Alchemy`Cataclysm`Elixirs - Guardian | 3 |
| Alchemy`Cataclysm`Potions - Healing & Mana | 5 |
| Alchemy`Cataclysm`Potions - Combat | 5 |
| Alchemy`Cataclysm`Potions - Utility | 3 |
| Alchemy`Wrath`Flasks | 5 |
| Alchemy`Wrath`Elixirs - Battle | 10 |
| Alchemy`Wrath`Elixirs - Guardian | 6 |
| Alchemy`Wrath`Potions - Healing & Mana | 8 |
| Alchemy`Wrath`Potions - Combat | 8 |
| Alchemy`Burning Crusade`Flasks | 5 |
| Alchemy`Burning Crusade`Elixirs - Battle | 11 |
| Alchemy`Burning Crusade`Elixirs - Guardian | 6 |
| Alchemy`Burning Crusade`Elixirs - Utility | 2 |
| Alchemy`Burning Crusade`Potions - Healing & Mana | 8 |
| Alchemy`Burning Crusade`Potions - Combat | 11 |
| Alchemy`Burning Crusade`Potions - Utility | 2 |
| Alchemy`Classic`Flasks | 3 |
| Alchemy`Classic`Elixirs - Battle | 18 |
| Alchemy`Classic`Elixirs - Guardian | 15 |
| Alchemy`Classic`Elixirs - Utility | 8 |
| Alchemy`Classic`Potions - Healing & Mana | 18 |
| Alchemy`Classic`Potions - Combat | 18 |
| Alchemy`Classic`Potions - Utility | 9 |
| Alchemy`Transmutes & Elementals | 28 |
| Alchemy`Stones & Trinkets | 2 |
| Alchemy`Oils & Misc | 13 |
| Alchemy`Cauldrons | 5 |

#### Alchemy`Pandaria`Flasks (5)

- Flask of Spring Blossoms (i:76084)
- Flask of the Warm Sun (i:76085)
- Flask of Falling Leaves (i:76086)
- Flask of the Earth (i:76087)
- Flask of Winter's Bite (i:76088)

#### Alchemy`Pandaria`Elixirs - Battle (5)

- Mad Hozen Elixir (i:76076)
- Elixir of Weaponry (i:76077)
- Elixir of the Rapids (i:76078)
- Elixir of Perfection (i:76080)
- Monk's Elixir (i:76083)

#### Alchemy`Pandaria`Elixirs - Guardian (3)

- Mantid Elixir (i:76075)
- Elixir of Peace (i:76079)
- Elixir of Mirrors (i:76081)

#### Alchemy`Pandaria`Potions - Healing & Mana (4)

- Potion of Focus (i:76092)
- Alchemist's Rejuvenation (i:76094)
- Master Healing Potion (i:76097)
- Master Mana Potion (i:76098)

#### Alchemy`Pandaria`Potions - Combat (4)

- Virmen's Bite (i:76089)
- Potion of the Mountains (i:76090)
- Potion of the Jade Serpent (i:76093)
- Potion of Mogu Power (i:76095)

#### Alchemy`Pandaria`Potions - Utility (3)

- Darkwater Potion (i:76096)
- Potion of Luck (i:93351)
- Venerable Potion of Invisibility (i:247802)

#### Alchemy`Cataclysm`Flasks (5)

- Flask of Steelskin (i:58085)
- Flask of the Draconic Mind (i:58086)
- Flask of the Winds (i:58087)
- Flask of Titanic Strength (i:58088)
- Flask of Flowing Water (i:67438)

#### Alchemy`Cataclysm`Elixirs - Battle (5)

- Elixir of the Naga (i:58089)
- Elixir of the Cobra (i:58092)
- Elixir of Impossible Accuracy (i:58094)
- Elixir of Mighty Speed (i:58144)
- Elixir of the Master (i:58148)

#### Alchemy`Cataclysm`Elixirs - Guardian (3)

- Ghost Elixir (i:58084)
- Elixir of Deep Earth (i:58093)
- Prismatic Elixir (i:58143)

#### Alchemy`Cataclysm`Potions - Healing & Mana (5)

- Mysterious Potion (i:57099)
- Mythical Healing Potion (i:57191)
- Mythical Mana Potion (i:57192)
- Mighty Rejuvenation Potion (i:57193)
- Potion of Concentration (i:57194)

#### Alchemy`Cataclysm`Potions - Combat (5)

- Earthen Potion (i:58090)
- Volcanic Potion (i:58091)
- Potion of the Tol'vir (i:58145)
- Golemblood Potion (i:58146)
- Draught of War (i:67415)

#### Alchemy`Cataclysm`Potions - Utility (3)

- Potion of Deepholm (i:58487)
- Potion of Treasure Finding (i:58488)
- Potion of Illusion (i:58489)

#### Alchemy`Wrath`Flasks (5)

- Lesser Flask of Toughness (i:40079)
- Flask of the Frost Wyrm (i:46376)
- Flask of Endless Rage (i:46377)
- Flask of Pure Mojo (i:46378)
- Flask of Stoneblood (i:46379)

#### Alchemy`Wrath`Elixirs - Battle (10)

- Elixir of Mighty Agility (i:39666)
- Wrath Elixir (i:40068)
- Spellpower Elixir (i:40070)
- Elixir of Mighty Strength (i:40073)
- Guru's Elixir (i:40076)
- Elixir of Accuracy (i:44325)
- Elixir of Deadly Strikes (i:44327)
- Elixir of Expertise (i:44329)
- Elixir of Armor Piercing (i:44330)
- Elixir of Lightning Speed (i:44331)

#### Alchemy`Wrath`Elixirs - Guardian (6)

- Elixir of Spirit (i:40072)
- Elixir of Mighty Fortitude (i:40078)
- Elixir of Protection (i:40097)
- Elixir of Mighty Mageblood (i:40109)
- Elixir of Mighty Defense (i:44328)
- Elixir of Mighty Thoughts (i:44332)

#### Alchemy`Wrath`Potions - Healing & Mana (8)

- Runic Healing Potion (i:33447)
- Runic Mana Potion (i:33448)
- Mad Alchemist's Potion (i:34440)
- Resurgent Healing Potion (i:39671)
- Icy Mana Potion (i:40067)
- Crazy Alchemist's Potion (i:40077)
- Potion of Nightmares (i:40081)
- Powerful Rejuvenation Potion (i:40087)

#### Alchemy`Wrath`Potions - Combat (8)

- Indestructible Potion (i:40093)
- Potion of Speed (i:40211)
- Potion of Wild Magic (i:40212)
- Mighty Arcane Protection Potion (i:40213)
- Mighty Fire Protection Potion (i:40214)
- Mighty Frost Protection Potion (i:40215)
- Mighty Nature Protection Potion (i:40216)
- Mighty Shadow Protection Potion (i:40217)

#### Alchemy`Burning Crusade`Flasks (5)

- Flask of Fortification (i:22851)
- Flask of Mighty Restoration (i:22853)
- Flask of Relentless Assault (i:22854)
- Flask of Blinding Light (i:22861)
- Flask of Pure Death (i:22866)

#### Alchemy`Burning Crusade`Elixirs - Battle (11)

- Elixir of Major Strength (i:22824)
- Elixir of Healing Power (i:22825)
- Elixir of Major Frost Power (i:22827)
- Elixir of Major Agility (i:22831)
- Elixir of Major Firepower (i:22833)
- Elixir of Major Shadow Power (i:22835)
- Elixir of Empowerment (i:22848)
- Onslaught Elixir (i:28102)
- Adept's Elixir (i:28103)
- Elixir of Mastery (i:28104)
- Fel Strength Elixir (i:31679)

#### Alchemy`Burning Crusade`Elixirs - Guardian (6)

- Elixir of Major Defense (i:22834)
- Elixir of Major Mageblood (i:22840)
- Elixir of Major Fortitude (i:32062)
- Earthen Elixir (i:32063)
- Elixir of Draenic Wisdom (i:32067)
- Elixir of Ironskin (i:32068)

#### Alchemy`Burning Crusade`Elixirs - Utility (2)

- Elixir of Camouflage (i:22823)
- Elixir of the Searching Eye (i:22830)

#### Alchemy`Burning Crusade`Potions - Healing & Mana (8)

- Super Healing Potion (i:22829)
- Super Mana Potion (i:22832)
- Major Dreamless Sleep Potion (i:22836)
- Super Rejuvenation Potion (i:22850)
- Volatile Healing Potion (i:28100)
- Unstable Mana Potion (i:28101)
- Fel Regeneration Potion (i:31676)
- Fel Mana Potion (i:31677)

#### Alchemy`Burning Crusade`Potions - Combat (11)

- Insane Strength Potion (i:22828)
- Heroic Potion (i:22837)
- Haste Potion (i:22838)
- Destruction Potion (i:22839)
- Major Fire Protection Potion (i:22841)
- Major Frost Protection Potion (i:22842)
- Major Nature Protection Potion (i:22844)
- Major Arcane Protection Potion (i:22845)
- Major Shadow Protection Potion (i:22846)
- Major Holy Protection Potion (i:22847)
- Ironshield Potion (i:22849)

#### Alchemy`Burning Crusade`Potions - Utility (2)

- Sneaking Potion (i:22826)
- Shrouding Potion (i:22871)

#### Alchemy`Classic`Flasks (3)

- Flask of the Titans (i:13510)
- Flask of Distilled Wisdom (i:13511)
- Flask of Supreme Power (i:13512)

#### Alchemy`Classic`Elixirs - Battle (18)

- Elixir of Lion's Strength (i:2454)
- Elixir of Minor Agility (i:2457)
- Elixir of Lesser Agility (i:3390)
- Elixir of Ogre's Strength (i:3391)
- Elixir of Firepower (i:6373)
- Elixir of Giant Growth (i:6662)
- Elixir of Agility (i:8949)
- Arcane Elixir (i:9155)
- Elixir of Greater Agility (i:9187)
- Elixir of Giants (i:9206)
- Elixir of Demonslaying (i:9224)
- Elixir of Shadow Power (i:9264)
- Elixir of the Mongoose (i:13452)
- Elixir of Brute Force (i:13453)
- Greater Arcane Elixir (i:13454)
- Elixir of Frost Power (i:17708)
- Elixir of Greater Firepower (i:21546)
- Elixir of Minor Accuracy (i:45621)

#### Alchemy`Classic`Elixirs - Guardian (15)

- Elixir of Minor Fortitude (i:2458)
- Weak Troll's Blood Elixir (i:3382)
- Elixir of Wisdom (i:3383)
- Strong Troll's Blood Elixir (i:3388)
- Elixir of Defense (i:3389)
- Elixir of Fortitude (i:3825)
- Major Troll's Blood Elixir (i:3826)
- Elixir of Minor Defense (i:5997)
- Elixir of Greater Defense (i:8951)
- Gift of Arthas (i:9088)
- Elixir of Greater Intellect (i:9179)
- Elixir of Superior Defense (i:13445)
- Elixir of the Sages (i:13447)
- Mighty Troll's Blood Elixir (i:20004)
- Mageblood Elixir (i:20007)

#### Alchemy`Classic`Elixirs - Utility (8)

- Elixir of Detect Lesser Invisibility (i:3828)
- Elixir of Water Breathing (i:5996)
- Elixir of Water Walking (i:8827)
- Elixir of Detect Undead (i:9154)
- Elixir of Dream Vision (i:9197)
- Elixir of Detect Demon (i:9233)
- Catseye Elixir (i:10592)
- Elixir of Greater Water Breathing (i:18294)

#### Alchemy`Classic`Potions - Healing & Mana (18)

- Minor Healing Potion (i:118)
- Lesser Healing Potion (i:858)
- Healing Potion (i:929)
- Greater Healing Potion (i:1710)
- Minor Mana Potion (i:2455)
- Minor Rejuvenation Potion (i:2456)
- Lesser Mana Potion (i:3385)
- Mana Potion (i:3827)
- Superior Healing Potion (i:3928)
- Discolored Healing Potion (i:4596)
- Greater Mana Potion (i:6149)
- Wildvine Potion (i:9144)
- Dreamless Sleep Potion (i:12190)
- Superior Mana Potion (i:13443)
- Major Mana Potion (i:13444)
- Major Healing Potion (i:13446)
- Major Rejuvenation Potion (i:18253)
- Greater Dreamless Sleep Potion (i:20002)

#### Alchemy`Classic`Potions - Combat (18)

- Limited Invulnerability Potion (i:3387)
- Lesser Stoneshield Potion (i:4623)
- Rage Potion (i:5631)
- Great Rage Potion (i:5633)
- Shadow Protection Potion (i:6048)
- Fire Protection Potion (i:6049)
- Frost Protection Potion (i:6050)
- Holy Protection Potion (i:6051)
- Nature Protection Potion (i:6052)
- Mighty Rage Potion (i:13442)
- Greater Stoneshield Potion (i:13455)
- Greater Frost Protection Potion (i:13456)
- Greater Fire Protection Potion (i:13457)
- Greater Nature Protection Potion (i:13458)
- Greater Shadow Protection Potion (i:13459)
- Greater Holy Protection Potion (i:13460)
- Greater Arcane Protection Potion (i:13461)
- Potion of Petrification (i:13506)

#### Alchemy`Classic`Potions - Utility (9)

- Swiftness Potion (i:2459)
- Potion of Curing (i:3386)
- Lesser Invisibility Potion (i:3823)
- Free Action Potion (i:5634)
- Swim Speed Potion (i:6372)
- Restorative Potion (i:9030)
- Invisibility Potion (i:9172)
- Purification Potion (i:13462)
- Living Action Potion (i:20008)

#### Alchemy`Transmutes & Elementals (28)

- Elemental Fire (i:7068)
- Essence of Earth (i:7076)
- Essence of Fire (i:7078)
- Essence of Water (i:7080)
- Essence of Air (i:7082)
- Living Essence (i:12803)
- Essence of Undeath (i:12808)
- Primal Water (i:21885)
- Primal Air (i:22451)
- Primal Shadow (i:22456)
- Primal Mana (i:22457)
- Primal Might (i:23571)
- Earthstorm Diamond (i:25867)
- Skyfire Diamond (i:25868)
- Eternal Water (i:35622)
- Eternal Air (i:35623)
- Eternal Shadow (i:35627)
- Cardinal Ruby (i:36919)
- King's Amber (i:36922)
- Majestic Zircon (i:36925)
- Dreadstone (i:36928)
- Ametrine (i:36931)
- Eye of Zul (i:36934)
- Eternal Might (i:40248)
- Skyflare Diamond (i:41266)
- Earthsiege Diamond (i:41334)
- Shadowspirit Diamond (i:52303)
- Primal Diamond (i:76132)

#### Alchemy`Stones & Trinkets (2)

- Mercurial Stone (i:31080)
- Vial of the Sands (i:65891)

#### Alchemy`Oils & Misc (13)

- Shadow Oil (i:3824)
- Frost Oil (i:3829)
- Blackmouth Oil (i:6370)
- Fire Oil (i:6371)
- Oil of Immolation (i:8956)
- Goblin Rocket Fuel (i:9061)
- Ghost Dye (i:9210)
- Stonescale Oil (i:13423)
- Pygmy Oil (i:40195)
- Ethereal Oil (i:44958)
- Deepstone Oil (i:56850)
- Deathblood Venom (i:58142)
- Desecrated Oil (i:87872)

#### Alchemy`Cauldrons (5)

- Cauldron of Major Arcane Protection (i:32839)
- Cauldron of Major Fire Protection (i:32849)
- Cauldron of Major Frost Protection (i:32850)
- Cauldron of Major Nature Protection (i:32851)
- Cauldron of Major Shadow Protection (i:32852)

### Not included

- **Already in your other groups (transmute products):** Gold, Truesilver, Arcanite, Titanium, Pyrium, Truegold, Trillium Bar and Living Steel are in Mining`Bars. Primal Fire/Earth and Eternal Fire/Earth are in Mining`Elementals. Primal Life and Eternal Life are in Herbalism`Elementals. The Cataclysm and Pandaria rare gems (Inferno Ruby ... Imperial Amethyst, Primordial Ruby ... Sun's Radiance) are in Mining`Gems & Prospecting.
- **Soulbound:** every Alchemist Stone trinket (Alchemist Stone through Zen Alchemist Stone), Philosopher's Stone, Alchemist's Flask, Endless Healing/Mana Potion, Cauldron of Battle and Big Cauldron of Battle. Mercurial Stone (BoE crafting component) and Vial of the Sands (BoE mount) are the only tradeable items in "Stones & Trinkets".
- **Junk:** Gurubashi Mojo Madness (old Zul'Gurub quest item) and Elemental Shard (gray).
- **Vendor vials and reagents** (Crystal Vial and others) are skipped because they are not worth posting on the AH.

### Notes

- The Battle / Guardian / Utility elixir split comes from my own knowledge of the game. The client data does not store that type. The item IDs themselves are all verified.
- Potions are split three ways: "Healing & Mana" covers healing, mana, rejuvenation and Dreamless Sleep. "Combat" covers DPS, defensive and resistance (protection) potions. "Utility" covers invisibility, water, cure and luck potions.
- The expansion is assigned by item ID range. Elixir of Minor Accuracy was added later but is a low-level item, so it is filed under Classic.
- Venerable Potion of Invisibility (i:247802) is in the 5.5.4 data as a new Alchemy recipe, filed under Pandaria utility.

### Blasting Powders and Blood Shards

| Item | ID | Class / subclass | Source |
|---|---|---|---|
| Rough Blasting Powder | i:4357 | Trade Goods / Parts (7/1) | Engineering craft |
| Coarse Blasting Powder | i:4364 | Trade Goods / Parts (7/1) | Engineering craft |
| Heavy Blasting Powder | i:4377 | Trade Goods / Parts (7/1) | Engineering craft |
| Solid Blasting Powder | i:10505 | Trade Goods / Parts (7/1) | Engineering craft |
| Dense Blasting Powder | i:15992 | Trade Goods / Parts (7/1) | Engineering craft |
| Elemental Blasting Powder | i:23781 | Trade Goods / Parts (7/1) | Engineering craft |
| Blood Shard | i:5075 | Quest (12/0), BoE, sells to vendor for 25c | Drops from Bristleback quilboar in the Barrens and from Barrens mining nodes |

- **Blasting Powders** are Engineering-made parts (TSM shows them as Trade Goods > Parts). They don't belong in Mining, since no node gives them. The best home is a new **Engineering** group, with a **Blasting Powders** subgroup. `schizzles-tsm-engineering-blasting-powders.txt` has that group (6 items) as a separate import, and none of these IDs are in your other groups.
- **Blood Shard** is an old quest-type item. Its only use was buying buffs from Mangletooth at Camp Taurajo, and the Cataclysm revamp removed those quests, so it is dead in MoP. Its only value is the vendor price. Don't put it in an Auctioning group. If you want to track it, put it in a Vendor/Junk group that has a Vendoring operation. It is not in any of the files.

## Schizzle's TSM Pet Group: "Pets" (MoP Classic)

227 cageable battle pets in 7 subgroups. Species IDs and tradeability come from the MoP Classic client data (wago.tools BattlePetSpecies, build 5.5.4.70631). A pet counts as cageable when the untradeable (0x10) and unobtainable (0x20) flags are both clear.

| Subgroup | Pets |
|---|---|
| Pets`High Value | 40 |
| Pets`Crafted & Profession | 17 |
| Pets`Vendor & Reputation | 63 |
| Pets`World Events | 27 |
| Pets`Raid & Dungeon Drops | 29 |
| Pets`Pandaria Drops & Quests | 32 |
| Pets`Old World to Cata Drops | 19 |

### Pets`High Value (40)

| Pet | Species ID | Source |
|---|---|---|
| Bananas | p:156 | Trading Card Game: Through the Dark Portal |
| Clockwork Gnome | p:277 | Profession: Archaeology |
| Crawling Claw | p:264 | Profession: Archaeology |
| Crimson Lasher | p:318 | Vendor: Ayla Shadowstorm / Zone: Molten Front / Cost: 1500 |
| Droplet of Y'Shaarj | p:1331 | Drop: Sha of Pride / Raid: Siege of Orgrimmar / Difficulty: Flexible, Normal or Heroic |
| Elementium Geode | p:293 | Drop: Elementium Vein, Rich Elementium Vein / Zone: Deepholm, Twilight Highlands, Uldum |
| Enchanted Lantern | p:267 | Profession: Enchanting (525) / Formula: Enchanted Lantern |
| Eye of the Legion | p:348 | Trading Card Game: Timewalkers: War of the Anicents |
| Fossilized Hatchling | p:266 | Profession: Archaeology |
| Fox Kit | p:278 | Drop: Baradin Fox / Zone: Tol Barad Peninsula |
| Gregarious Grell | p:333 | Trading Card Game: Crown of the Heavens |
| Hyjal Bear Cub | p:317 | Vendor: Varlan Highbough / Zone: Molten Front / Cost: 1500 |
| Imperial Moth | p:1039 | Profession: Tailoring (Imperial Silk) |
| Imperial Silkworm | p:1040 | Profession: Tailoring (Imperial Silk) |
| Jade Owl | p:845 | Profession: Jewelcrafting |
| Ji-Kun Hatchling | p:1202 | Drop: Ji-Kun / Zone: Throne of Thunder |
| Kovok | p:1334 | Drop: Paragons of the Klaxxi / Raid: Siege of Orgrimmar |
| Lil' Bling | p:1320 | Drop: Blingtron Gift Package |
| Lil' Smoky | p:86 | Profession: Engineering |
| Magic Lamp | p:292 | Profession: Enchanting |
| Mechanical Pandaren Dragonling | p:844 | Profession: Engineering |
| Mini Mindslayer | p:1156 | Drop: The Prophet Skeram / Zone: Ahn'Qiraj |
| Mojo | p:165 | Drop: Forest Frog / Zone: Zul'Aman |
| Moon Moon | p:1276 | Drop: Moonfang / Zone: Darkmoon Island |
| Mr. Grubbs | p:286 | World Drop: Eastern Plaguelands (requires Fiona's Lucky Charm) |
| Personal World Destroyer | p:261 | Profession: Engineering |
| Phoenix Hatchling | p:175 | Drop: Kael'thas Sunstrider / Zone: Magisters' Terrace |
| Pierre | p:1204 | Profession: Engineering |
| Pterrordax Hatchling | p:309 | Profession: Archaeology |
| Rascal-Bot | p:1256 | Profession: Engineering |
| Sapphire Cub | p:846 | Profession: Jewelcrafting |
| Searing Scorchling | p:172 | Vendor: Zen'Vorka / Zone: Molten Front / Cost: 30 |
| Smolderweb Hatchling | p:90 | Drop: Mother Smolderweb / Zone: Lower Blackrock Spire |
| Son of Animus | p:1183 | Drop: Animus / Zone: Throne of Thunder |
| Spawn of G'nathus | p:1201 | Drop: G'nathus / Zone: Townlong Steppes |
| Sprite Darter Hatchling | p:87 | Drop: World Drop / Zone: Feralas |
| Sunreaver Micro-Sentry | p:1178 | Drop: Haywire Sunreaver Construct / Zone: Isle of Thunder |
| Tiny Shale Spider | p:279 | Drop: Jadefang / Zone: Deepholm |
| Voodoo Figurine | p:310 | Profession: Archaeology |
| Worg Pup | p:89 | Drop: Quartermaster Zigris / Zone: Lower Blackrock Spire |

### Pets`Crafted & Profession (17)

| Pet | Species ID | Source |
|---|---|---|
| Chuck | p:174 | Profession: Fishing / Zone: Shattrath |
| De-Weaponized Mechanical Companion | p:262 | Profession: Engineering |
| Giant Sewer Rat | p:193 | Profession: Fishing / Zone: Dalaran |
| Lifelike Toad | p:95 | Profession: Engineering |
| Magical Crawdad | p:132 | Fishing: Fishing (430) / Zone: Terokkar Forest (Fishing Nodes) |
| Mechanical Squirrel | p:39 | Profession: Engineering |
| Muckbreath | p:164 | Profession: Fishing / Zone: Shattrath |
| Pet Bombling | p:85 | Profession: Engineering |
| Sea Pony | p:340 | Profession: Fishing / Zone: Darkmoon Island |
| Snarly | p:173 | Profession: Fishing / Zone: Shattrath |
| Strand Crawler | p:211 | Profession: Fishing / Zone: Northrend, Stormwind, Orgrimmar |
| Tiny Blue Carp | p:1207 | Profession: Fishing |
| Tiny Green Carp | p:1208 | Profession: Fishing |
| Tiny Red Carp | p:1206 | Profession: Fishing |
| Tiny White Carp | p:1209 | Profession: Fishing |
| Toothy | p:163 | Profession: Fishing / Zone: Shattrath |
| Tranquil Mechanical Yeti | p:116 | Profession: Engineering |

### Pets`Vendor & Reputation (63)

| Pet | Species ID | Source |
|---|---|---|
| Albino Snake | p:74 | Vendor: Breanni / Zone: Dalaran / Cost: 50 |
| Ammen Vale Lashling | p:212 | Vendor: Irisee / Zone: Icecrown / Cost: 40 |
| Ancona Chicken | p:52 | Vendor: "Plucky" Johnson / Zone: Thousand Needles / Cost: 1 |
| Black Kingsnake | p:75 | Vendor: Xan'tish / Zone: Orgrimmar / Cost: 50 |
| Blue Clockwork Rocket Bot | p:254 | Vendor: World Vendors / Cost: 50 |
| Blue Dragonhawk Hatchling | p:145 | Vendor: Dealer Rashaad / Zone: Netherstorm / Cost: 10 |
| Blue Moth | p:138 | Vendor: Sixx / Zone: The Exodar / Cost: 50 |
| Bombay Cat | p:40 | Vendor: Donni Anthania / Zone: Elwynn Forest / Cost: 40 |
| Brown Prairie Dog | p:70 | Vendor: Halpa, Naleen / Zone: Mulgore / Cost: 50 |
| Brown Rabbit | p:137 | Vendor: Dealer Rashaad / Zone: Netherstorm / Cost: 10 |
| Brown Snake | p:77 | Vendor: Xan'tish / Zone: Orgrimmar / Cost: 50 |
| Calico Cat | p:224 | Vendor: Breanni / Zone: Crystalsong Forest / Cost: 50 |
| Cockatiel | p:47 | Vendor: Harry No-Hooks, Narkk / Zone: The Cape of Stranglethorn / Cost: 40 |
| Cornish Rex Cat | p:41 | Vendor: Donni Anthania / Zone: Elwynn Forest / Cost: 40 |
| Crimson Snake | p:78 | Vendor: Dealer Rashaad / Zone: Netherstorm / Cost: 50 / / Vendor: Xan'tish / Zone: Orgrimmar / Cost: 50 |
| Darkmoon Cub | p:343 | Vendor: Lhara / Zone: Darkmoon Island / Cost: 90 |
| Darkmoon Hatchling | p:1061 | Vendor: Lhara / Zone: Darkmoon Island / Cost: 90 |
| Darkmoon Monkey | p:330 | Vendor: Lhara / Zone: Darkmoon Island / Cost: 90 |
| Darkmoon Tonk | p:338 | Vendor: Lhara / Zone: Darkmoon Island / Cost: 90 |
| Darkmoon Turtle | p:335 | Vendor: Lhara / Zone: Darkmoon Island / Cost: 90 |
| Darkmoon Zeppelin | p:339 | Vendor: Lhara / Zone: Darkmoon Island / Cost: 90 |
| Dun Morogh Cub | p:205 | Vendor: Derrick Brindlebeard / Zone: Icecrown / Cost: 40 |
| Durotar Scorpion | p:207 | Vendor: Freka Bloodaxe / Zone: Icecrown / Cost: 40 |
| Elwynn Lamb | p:209 | Vendor: Corporal Arthur Flew / Zone: Icecrown / Cost: 40 |
| Enchanted Broom | p:213 | Vendor: Trellis Morningsun / Zone: Icecrown / Cost: 40 |
| Gahz'rooki | p:1237 | Vendor: Ravika / Zone: Durotar / Cost: 1 / / Vendor: Tenuki / Zone: Durotar / Cost: 1 |
| Ghostly Skull | p:190 | Vendor: Darahir / Zone: Crystalsong Forest / Cost: 40 |
| Gilnean Raven | p:630 | Vendor: Will Larsons / Zone: Darkshore |
| Golden Dragonhawk Hatchling | p:142 | Vendor: Jilanne / Zone: Eversong Woods / Cost: 50 |
| Great Horned Owl | p:68 | Vendor: Shylenai / Zone: Teldrassil / Cost: 50 |
| Harmonious Porcupette | p:1346 | Vendor: Mistweaver Ku / Zone: Timeless Isle / Faction: Shaohao - Pathwalker |
| Hawk Owl | p:67 | Vendor: Shylenai / Zone: Teldrassil / Cost: 50 |
| Jade Crane Chick | p:792 | Vendor: Audrey Burnhep, Varzok / Zone: Stormwind, Orgrimmar / Cost: 50 |
| Mana Wyrmling | p:136 | Vendor: Dealer Rashaad / Zone: Netherstorm / Cost: 40 |
| Mechanopeep | p:215 | Vendor: Rillie Spindlenut / Zone: Icecrown |
| Mulgore Hatchling | p:210 | Vendor: Doru Thunderhorn / Zone: Icecrown / Cost: 40 |
| Nether Ray Fry | p:186 | Vendor: Grella / Zone: Terokkar Forest / Faction: Sha'tari Skyguard - Exalted / Cost: 40 |
| Obsidian Hatchling | p:236 | Vendor: Breanni / Zone: Crystalsong Forest / Cost: 50 |
| Orange Tabby Cat | p:43 | Vendor: Donni Anthania, Steven Lisbane / Zone: Elwynn Forest / Cost: 40 |
| Pengu | p:198 | Vendor: Sairuk / Zone: Dragonblight / Faction: The Kalu'ak - Exalted / Cost: 12 / / Vendor: Tanaika / Zone: Howling Fjord / Faction: The Kalu'ak - Exalted / Cost: 12 |
| Red Dragonhawk Hatchling | p:143 | Vendor: Jilanne / Zone: Eversong Woods / Cost: 50 |
| Red Moth | p:139 | Vendor: Dealer Rashaad / Zone: Netherstorm / Cost: 10 |
| Rustberg Gull | p:271 | Vendor: Quartermaster Brazie / Zone: Tol Barad Peninsula / Faction: Baradin's Wardens - Honored / Cost: 50 |
| Sen'jin Fetish | p:218 | Vendor: Samamba / Zone: Icecrown / Cost: 40 |
| Senegal | p:51 | Vendor: Narkk, Harry No-Hooks / Zone: The Cape of Stranglethorn / / / Vendor: Dealer Rashaad / Zone: Netherstorm / Cost: 40 |
| Shimmering Wyrmling | p:229 | Vendor: Hiren Loresong / Zone: Icecrown / Faction: The Silver Covenant - Exalted / Cost: 40 |
| Shore Crawler | p:629 | Vendor: Matty / Zone: Orgrimmar |
| Siamese Cat | p:44 | Vendor: Dealer Rashaad / Zone: Netherstorm / Cost: 60 |
| Silver Dragonhawk Hatchling | p:144 | Vendor: Jilanne / Zone: Eversong Woods / Cost: 50 |
| Silver Tabby Cat | p:45 | Vendor: Donni Anthania / Zone: Elwynn Forest / Cost: 40 |
| Snowshoe Rabbit | p:72 | Vendor: Yarlyn Amberstill / Zone: Dun Morogh / Cost: 20 |
| Teldrassil Sproutling | p:204 | Vendor: Rook Hawkfist / Zone: Icecrown / Cost: 40 |
| Tiny Goldfish | p:652 | Vendor: Nat Pagle / Zone: Krasarang Wilds / Faction: The Anglers - Honored / Cost: 250 |
| Tiny Sporebat | p:167 | Vendor: Mycah / Zone: Zangarmarsh / Faction: Sporeggar - Exalted / Cost: 30 |
| Tirisfal Batling | p:206 | Vendor: Eliza Killian / Zone: Icecrown / Cost: 40 |
| Tree Frog | p:65 | Vendor: Flik / Zone: Darkmoon Island / Cost: 1 |
| Undercity Cockroach | p:55 | Vendor: Dealer Rashaad / Zone: Netherstorm / Cost: 50 / / Vendor: Jeremiah Payson / Zone: Tirisfal Glades / Cost: 50 |
| Vengeful Porcupette | p:1344 | Vendor: Speaker Gulan / Zone: Timeless Isle |
| White Kitten | p:46 | Vendor: Lil Timmy / Zone: Stormwind City / Cost: 60 |
| White Moth | p:141 | Vendor: Sixx / Zone: The Exodar / Cost: 50 |
| Winterspring Cub | p:306 | Vendor: Michelle De Rum / Zone: Winterspring / Cost: 50 |
| Wood Frog | p:64 | Vendor: Flik / Zone: Darkmoon Island / Cost: 1 |
| Yellow Moth | p:140 | Vendor: Sixx / Zone: The Exodar / Cost: 50 |

### Pets`World Events (27)

| Pet | Species ID | Source |
|---|---|---|
| Clockwork Rocket Bot | p:191 | World Event: Feast of Winter Veil |
| Egbert | p:158 | World Event: Children's Week |
| Father Winter's Helper | p:119 | World Event: Feast of Winter Veil |
| Feline Familiar | p:319 | World Event: Hallow's End / Vendor: Chub / Zone: Tirisfal Glades / Cost: 150 / / Vendor: Dorothy / Zone: Stormwind City / Cost: 150 |
| Festival Lantern | p:342 | World Event: Lunar Festival / Vendor: Valadar Starsong / Zone: Moonglade / Cost: 50 |
| Frigid Frostling | p:253 | World Event: Midsummer Fire Festival |
| Legs | p:308 | World Event: Children's Week |
| Lumpy | p:337 | World Event: Feast of Winter Veil |
| Lunar Lantern | p:341 | World Event: Lunar Festival / Vendor: Valadar Starsong / Zone: Moonglade / Cost: 50 |
| Macabre Marionette | p:1351 | World Event: Day of the Dead |
| Mr. Wiggles | p:126 | World Event: Children's Week |
| Peanut | p:159 | World Event: Children's Week |
| Peddlefeet | p:122 | World Event: Love is in the Air / Vendor: Lovely Merchant / Cost: 40 |
| Pint-Sized Pink Pachyderm | p:166 | World Event: Brewfest / Vendor: Belbi Quikswitch / Zone: Dun Morogh / Cost: 100 / / Vendor: Bliz Fixwidget / Zone: Durotar / Cost: 100 |
| Rotten Little Helper | p:1349 | World Event: Feast of Winter Veil |
| Scooter the Snail | p:289 | World Event: Children's Week |
| Sinister Squashling | p:162 | World Event: Hallow's End |
| Speedy | p:125 | World Event: Children's Week |
| Spirit of Summer | p:128 | World Event: Midsummer Fire Festival / Vendor: Midsummer Merchant / Cost: 350 |
| Spring Rabbit | p:200 | World Event: Noblegarden / Vendor: Noblegarden Merchant / Cost: 100 |
| Tiny Snowman | p:117 | World Event: Feast of Winter Veil |
| Toxic Wasteling | p:251 | World Event: Love is in the Air |
| Whiskers the Rat | p:127 | World Event: Children's Week |
| Willy | p:157 | World Event: Children's Week |
| Winter Reindeer | p:118 | World Event: Feast of Winter Veil |
| Winter's Little Helper | p:120 | World Event: Feast of Winter Veil |
| Wolpertinger | p:153 | World Event: Brewfest |

### Pets`Raid & Dungeon Drops (29)

| Pet | Species ID | Source |
|---|---|---|
| Anubisath Idol | p:1155 | Drop: Emperor Vek'lor / Zone: Ahn'Qiraj |
| Ashstone Core | p:1150 | Drop: Golemagg the Incinerator / Zone: Molten Core |
| Blackfuse Bombling | p:1322 | Drop: Siegecrafter Blackfuse / Raid: Siege of Orgrimmar |
| Chrominius | p:1152 | Drop: Chromaggus / Zone: Blackwing Lair |
| Coilfang Stalker | p:1232 | Drop: Lady Vashj / Zone: Serpentshrine Cavern |
| Corefire Imp | p:1149 | Drop: Magmadar / Zone: Molten Core |
| Death Talon Whelpguard | p:1153 | Drop: Broodlord Lashlayer / Zone: Blackwing Lair |
| Deviate Hatchling | p:233 | Drop: Deviate Guardian, Deviate Ravager / Zone: Wailing Caverns |
| Fiendish Imp | p:1229 | Drop: Terestian Illhoof / Zone: Karazhan |
| Fungal Abomination | p:1144 | Drop: Loatheb / Zone: Naxxramas |
| Giant Bone Spider | p:1143 | Drop: Maexxna / Zone: Naxxramas |
| Gooey Sha-ling | p:1332 | Drop: Sha of Pride / Raid: Siege of Orgrimmar / Difficulty: LFR and Flexible |
| Green Wing Macaw | p:50 | Drop: Defias Pirate / Zone: The Deadmines |
| Harbinger of Flame | p:1147 | Drop: Sulfuron Harbinger / Zone: Molten Core |
| Lesser Voidcaller | p:1234 | Drop: High Astromancer Solarian / Zone: Tempest Keep |
| Lil' Bad Wolf | p:1226 | Drop: The Big Bad Wolf / Zone: Karazhan |
| Living Fluid | p:1243 | Drop: Primordius / Zone: Throne of Thunder / Difficulty: Looking For Raid |
| Living Sandling | p:1177 | Drop: Throne of Thunder |
| Menagerie Custodian | p:1227 | Drop: The Curator / Zone: Karazhan |
| Netherspace Abyssal | p:1228 | Drop: Prince Malchezaar / Zone: Karazhan |
| Phoenix Hawk Hatchling | p:1235 | Drop: Al'ar / Zone: Tempest Keep |
| Pocket Reaver | p:1233 | Drop: Void Reaver / Zone: Tempest Keep |
| Pygmy Direhorn | p:1200 | Drop: Horridon / Zone: Throne of Thunder |
| Stitched Pup | p:1146 | Drop: Gluth / Zone: Naxxramas |
| Tainted Waveling | p:1231 | Drop: Hydross the Unstable / Zone: Serpentshrine Cavern |
| Tideskipper | p:1230 | Drop: Morogrim Tidewalker / Zone: Serpentshrine Cavern |
| Untamed Hatchling | p:1151 | Drop: Razorgore the Untamed / Zone: Blackwing Lair |
| Viscidus Globule | p:1154 | Drop: Viscidus / Zone: Ahn'Qiraj |
| Viscous Horror | p:1244 | Drop: Primordius / Zone: Throne of Thunder / Difficulty: Normal or Heroic |

### Pets`Pandaria Drops & Quests (32)

| Pet | Species ID | Source |
|---|---|---|
| Aqua Strider | p:836 | Drop: Nalash Verdantis / Zone: Dread Wastes |
| Ashleaf Spriteling | p:1323 | Drop: Leafmender / Zone: Timeless Isle |
| Azure Crane Chick | p:1321 | Drop: Crane Nest / Zone: Timeless Isle |
| Dandelion Frolicker | p:1329 | Drop: Scary Sprite / Zone: Timeless Isle |
| Darkmoon Eye | p:1063 | Drop: Darkmoon Pet Supplies |
| Darkmoon Rabbit | p:848 | Drop: Darkmoon Rabbit / Zone: Darkmoon Island |
| Death Adder Hatchling | p:1330 | Drop: Imperial Python / Zone: Timeless Isle |
| Direhorn Runt | p:1205 | Drop: Direhorns / Zone: Isle of Giants |
| Filthling | p:1245 | Drop: Quivering Filth |
| Fishy | p:847 | Quest: Let Them Burn / Zone: The Jade Forest |
| Grinder | p:834 | Drop: Karr the Darkener / Zone: Dread Wastes |
| Gu'chi Swarmling | p:1345 | Drop: Gu'chi the Swarmbringer / Zone: Timeless Isle |
| Gulp Froglet | p:1338 | Drop: Bufo / Pet Battle: Timeless Isle |
| Jadefire Spirit | p:1348 | Drop: Spirit of Jadefire / Zone: Timeless Isle |
| Jademist Dancer | p:1333 | Drop: Jademist Dancer / Zone: Timeless Isle |
| Mountain Panda | p:1198 | Quest: Beasts of Fable |
| Ominous Flame | p:1335 | Drop: Foreboding Flame / Zone: Timeless Isle |
| Pandaren Air Spirit | p:1125 | Quest: Pandaren Spirit Tamer / Zone: Vale of Eternal Blossoms |
| Pandaren Earth Spirit | p:1126 | Quest: Pandaren Spirit Tamer / Zone: Vale of Eternal Blossoms |
| Pandaren Fire Spirit | p:1124 | Quest: Pandaren Spirit Tamer / Zone: Vale of Eternal Blossoms |
| Pandaren Water Spirit | p:868 | Quest: Pandaren Spirit Tamer / Zone: Vale of Eternal Blossoms |
| Ruby Droplet | p:1328 | Drop: Garnia / Zone: Timeless Isle |
| Skunky Alemental | p:1336 | Drop: Zhu-Gon the Sour / Zone: Timeless Isle |
| Snowy Panda | p:1197 | Quest: Beasts of Fable |
| Spectral Porcupette | p:1185 | Quest: A Large Pile of Giant Dinosaur Bones / Zone: Isle Of Giants |
| Spineclaw Crab | p:1337 | Drop: Monstrous Spineclaw / Zone: Timeless Isle |
| Sunfur Panda | p:1196 | Quest: Beasts of Fable |
| Terrible Turnip | p:650 | Drop: World Drop / Zone: Valley of the Four Winds |
| Zandalari Anklerender | p:1211 | Drop: Zandalari Dinomancer / Zone: Isle Of Giants |
| Zandalari Footslasher | p:1212 | Drop: Zandalari Dinomancer / Zone: Isle Of Giants |
| Zandalari Kneebiter | p:1180 | Drop: Zandalari Dinomancer / Zone: Isle Of Giants |
| Zandalari Toenibbler | p:1213 | Drop: Zandalari Dinomancer / Zone: Isle Of Giants |

### Pets`Old World to Cata Drops (19)

| Pet | Species ID | Source |
|---|---|---|
| Azure Whelpling | p:57 | Drop: World Drop / Zone: Winterspring |
| Black Tabby Cat | p:42 | Drop: World Drop / Zone: Hillsbrad Foothills |
| Cobra Hatchling | p:197 | Drop: Mysterious Egg |
| Crimson Whelpling | p:58 | Drop: World Drop / Zone: Wetlands |
| Dark Whelpling | p:56 | Drop: Whelplings / Zone: Wetlands, Dustwallow Marsh, Badlands, Burning Steppes |
| Darting Hatchling | p:232 | Drop: Dart's Nest / Zone: Dustwallow Marsh |
| Disgusting Oozeling | p:114 | Drop: World Drop / Creature: Oozes, Slimes and Worms |
| Emerald Whelpling | p:59 | Drop: Noxious Whelp / Zone: Feralas |
| Firefly | p:146 | Drop: Bogflare Needler / Zone: Zangarmarsh |
| Gundrak Hatchling | p:234 | Drop: Gundrak Raptor / Zone: Zul'Drak |
| Hyacinth Macaw | p:49 | Drop: World Drop / Zone: Northern Stranglethorn, The Cape of Stranglethorn |
| Leaping Hatchling | p:235 | Drop: Takk's Nest / Zone: The Barrens |
| Porcupette | p:381 | Drop: Sack of Pet Supplies |
| Proto-Drake Whelp | p:196 | Drop: Mysterious Egg |
| Ravasaur Hatchling | p:237 | Drop: Ravasaur Matriarch's Nest / Zone: Un'goro Crater |
| Razormaw Hatchling | p:238 | Drop: Razormaw Matriarch's Nest / Zone: Wetlands |
| Razzashi Hatchling | p:239 | Drop: World Drop / Zone: Northern Stranglethorn, The Cape of Stranglethorn |
| Tickbird Hatchling | p:194 | Drop: Mysterious Egg |
| White Tickbird Hatchling | p:195 | Drop: Mysterious Egg |

### Skipped (tradeable flag set but no source or not a MoP-era pet)

- Raccoon Kit (p:382): no source text
- Otter Pup (p:384): no source text
- Ravager Hatchling (p:4204): no source text
- Alarming Clockbot (p:4228): no source text
- XS-001 Constructor Bot (p:4229): no source text
- Pebble (p:4234): Promotion
- Timbered Air Snakelet (p:4685): Promotion
- Joyous (p:4734): Promotion

### How to import

1. Type `/tsm`, open the **Groups** tab, and click **Import Group** at the top of the group tree.
2. Paste the whole contents of `schizzles-tsm-pets-group.txt` (one line, no line breaks) and confirm. TSM shows a summary (7 groups, 227 items) and creates a top-level group named **Pets** with the 7 subgroups.
3. Any of these pets you already have in another group stay there unless you choose to move them. To move them, select the items in the Pets subgroup and use **Move items**.
4. Attach your Auctioning operation to **Pets**. The subgroups inherit it.

### Suggested Auctioning operation ("Pets")

Caged pets have no vendor sell price, so there is a hard gold floor instead of a `vendorsell` floor.

- **Minimum:** `max(20g, 0.8*min(first(dbmarket, dbregionmarketavg), first(dbregionsaleavg, dbregionmarketavg)))`
- **Normal:** `max(20g, first(dbmarket, dbregionsaleavg, dbregionmarketavg))`
- **Maximum:** `max(40g, 2*first(dbmarket, dbregionmarketavg))`
- **Settings:** stack size 1, post cap 1 or 2, 48h duration. Set "When Below Minimum" to **Don't Post**. Pets sell slowly, so it pays to wait out a cheap listing.
- **Vendor & Reputation subgroup:** override the minimum with what the pet costs you to buy, plus the AH cut. For example `max(<vendor cost>*1.1, ...)`.
- **Sniper/Shopping for pets:** `min(0.6*first(dbmarket, dbregionmarketavg), 0.6*first(dbregionsaleavg, dbregionmarketavg))`

Test any string with `/tsm price [shift-click caged pet] <string>`.

## License

MIT, with an attribution requirement. See [LICENSE](LICENSE). Original repo: https://github.com/shawj317/schizzles-mop-classic/tree/main/schizzles-tsm-groups
