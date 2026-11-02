# Schizzle's TSM

TradeSkillMaster (TSM4) group import strings for World of Warcraft: Mists of Pandaria Classic. The groups work on any realm and region. There is one group per profession, covering all 15 professions, primary and secondary, from Classic through Pandaria. You can import a single profession or all of them at once with one string. Battle pets have their own strings in `groups/pets/`: one per subgroup, plus one for all pets. Ready-made **operations** (v2.2) are in `operations/`, either already attached to the full group tree or as an operations-only string.

Every item ID comes from the MoP Classic client data (wago.tools DB2 tables Item, ItemSparse, SkillLineAbility, SpellEffect and SpellReagents, build 5.5.4.70631). The groups only contain items you can sell on the auction house. **No item appears in more than one group**, so the profession strings never conflict with each other.

## Groups

| Profession | Items | Subgroups | Import string | Item list | What's in it |
|---|---|---|---|---|---|
| Alchemy | 281 | 36 | [`groups/professions/schizzles-tsm-alchemy.txt`](groups/professions/schizzles-tsm-alchemy.txt) | [docs/alchemy.md](docs/alchemy.md) | Flasks, elixirs, potions, transmutes, alchemist stones, alchemy-only reagents (vials, other elementals) |
| Blacksmithing | 763 | 18 | [`groups/professions/schizzles-tsm-blacksmithing.txt`](groups/professions/schizzles-tsm-blacksmithing.txt) | [docs/blacksmithing.md](docs/blacksmithing.md) | Plate/mail armor, shields and weapons by expansion; sharpening stones, weightstones, skeleton keys, weapon chains, shield spikes, buckles, grinding stones, folded metals |
| Enchanting | 383 | 20 | [`groups/professions/schizzles-tsm-enchanting.txt`](groups/professions/schizzles-tsm-enchanting.txt) | [docs/enchanting.md](docs/enchanting.md) | Dust, essences and shards by expansion; enchant scrolls by slot; oils, rods, wands, spheres |
| Engineering | 302 | 14 | [`groups/professions/schizzles-tsm-engineering.txt`](groups/professions/schizzles-tsm-engineering.txt) | [docs/engineering.md](docs/engineering.md) | Parts, blasting powders, explosives, devices, scopes, guns and bows, goggles and gear, mounts, pets |
| Herbalism | 77 | 7 | [`groups/professions/schizzles-tsm-herbalism.txt`](groups/professions/schizzles-tsm-herbalism.txt) | [docs/herbalism.md](docs/herbalism.md) | Herbs by expansion, 5.4 herb fragments, life elementals |
| Inscription | 596 | 22 | [`groups/professions/schizzles-tsm-inscription.txt`](groups/professions/schizzles-tsm-inscription.txt) | [docs/inscription.md](docs/inscription.md) | Pigments, inks, glyphs (by class), off-hands, staves, cards, trinkets, scrolls, vellum and other reagents |
| Jewelcrafting | 706 | 22 | [`groups/professions/schizzles-tsm-jewelcrafting.txt`](groups/professions/schizzles-tsm-jewelcrafting.txt) | [docs/jewelcrafting.md](docs/jewelcrafting.md) | Uncut gems and pearls by expansion (prospected or transmuted), cut gems by color/type, rings, necks, figurines |
| Leatherworking | 871 | 16 | [`groups/professions/schizzles-tsm-leatherworking.txt`](groups/professions/schizzles-tsm-leatherworking.txt) | [docs/leatherworking.md](docs/leatherworking.md) | Leather/mail armor and cloaks by expansion, armor kits, leg armor, drums, bags, LW reagents |
| Mining | 80 | 6 | [`groups/professions/schizzles-tsm-mining.txt`](groups/professions/schizzles-tsm-mining.txt) | [docs/mining.md](docs/mining.md) | Ore, bars (incl. transmuted metals), stone, earth/fire elementals, coal/flux, mining pick |
| Skinning | 68 | 6 | [`groups/professions/schizzles-tsm-skinning.txt`](groups/professions/schizzles-tsm-skinning.txt) | [docs/skinning.md](docs/skinning.md) | All leather, hides and scales by expansion, skinning knife |
| Tailoring | 646 | 16 | [`groups/professions/schizzles-tsm-tailoring.txt`](groups/professions/schizzles-tsm-tailoring.txt) | [docs/tailoring.md](docs/tailoring.md) | Raw cloth, bolts, specialty cloth (incl. Imperial Silk), cloth armor and cloaks, bags, spellthreads |
| Cooking | 422 | 11 | [`groups/professions/schizzles-tsm-cooking.txt`](groups/professions/schizzles-tsm-cooking.txt) | [docs/cooking.md](docs/cooking.md) | Meat, eggs, clams, Pandaria farm produce, Ironpaw and other ingredients, cooked food by expansion |
| Fishing | 84 | 6 | [`groups/professions/schizzles-tsm-fishing.txt`](groups/professions/schizzles-tsm-fishing.txt) | [docs/fishing.md](docs/fishing.md) | Raw fish by expansion, lures and fishing poles |
| First Aid | 25 | 2 | [`groups/professions/schizzles-tsm-first-aid.txt`](groups/professions/schizzles-tsm-first-aid.txt) | [docs/first-aid.md](docs/first-aid.md) | Bandages, anti-venoms |
| Archaeology | 11 | 1 | [`groups/professions/schizzles-tsm-archaeology.txt`](groups/professions/schizzles-tsm-archaeology.txt) | [docs/archaeology.md](docs/archaeology.md) | Tradeable keystones only (see below) |
| **All professions** | **5315** | 203 | [`groups/professions/schizzles-tsm-all-professions.txt`](groups/professions/schizzles-tsm-all-professions.txt) | (per-profession docs) | All 15 groups above, nested under one parent group **Schizzle's TSM** |
| Battle Pets: High Value | 38 | 1 | [`groups/pets/schizzles-tsm-pets-high-value.txt`](groups/pets/schizzles-tsm-pets-high-value.txt) | [docs/battle-pets.md](docs/battle-pets.md) | Data-driven (v2.2): any pet whose realm value was at least 7,500g in the US realm snapshot used to build the list (1 Nov 2026) **and** whose region sale rate is at least 0.03, plus the TCG/promo pets (no other home). Realm value = realm market value, else realm historical, capped at 2x region market; pets with no realm price use 0.8x region market. Matched first, so these are never in another subgroup. Prices on your realm will differ, so move pets in or out as you like. |
| Battle Pets: Vendor Pets | 98 | 1 | [`groups/pets/schizzles-tsm-pets-vendor.txt`](groups/pets/schizzles-tsm-pets-vendor.txt) | [docs/battle-pets.md](docs/battle-pets.md) | Pets and companion items bought from vendors (gold or reputation). Classic vendor-flip items such as the cat carriers and parrot cages. |
| Battle Pets: Profession Pets | 33 | 1 | [`groups/pets/schizzles-tsm-pets-profession.txt`](groups/pets/schizzles-tsm-pets-profession.txt) | [docs/battle-pets.md](docs/battle-pets.md) | Caged pets made by professions (Engineering, Tailoring, Jewelcrafting, Enchanting, Inscription, Archaeology), plus companion items not owned by a profession group. |
| Battle Pets: World Drops & Quests | 37 | 1 | [`groups/pets/schizzles-tsm-pets-world-drops.txt`](groups/pets/schizzles-tsm-pets-world-drops.txt) | [docs/battle-pets.md](docs/battle-pets.md) | Old world through Cataclysm drops and quest rewards. |
| Battle Pets: Raid & Dungeon Drops | 38 | 1 | [`groups/pets/schizzles-tsm-pets-raid-dungeon.txt`](groups/pets/schizzles-tsm-pets-raid-dungeon.txt) | [docs/battle-pets.md](docs/battle-pets.md) | Pets from raid and dungeon bosses. |
| Battle Pets: Pandaria Drops & Quests | 35 | 1 | [`groups/pets/schizzles-tsm-pets-pandaria.txt`](groups/pets/schizzles-tsm-pets-pandaria.txt) | [docs/battle-pets.md](docs/battle-pets.md) | Pandaria drops, rares and quest rewards. |
| Battle Pets: Holiday & Events | 49 | 1 | [`groups/pets/schizzles-tsm-pets-holiday-events.txt`](groups/pets/schizzles-tsm-pets-holiday-events.txt) | [docs/battle-pets.md](docs/battle-pets.md) | World events (Hallow's End, Winter Veil, Lunar Festival, Noblegarden and others) and the Darkmoon Faire. |
| Battle Pets: Pet Supplies | 1 | 1 | [`groups/pets/schizzles-tsm-pets-supplies.txt`](groups/pets/schizzles-tsm-pets-supplies.txt) | [docs/battle-pets.md](docs/battle-pets.md) | Tradeable pet-battle supplies. Only the Flawless Battle-Stone qualifies: the typed/Polished/Perfect battle-stones, pet treats and pet bandages are all soulbound. |
| **All battle pets** | **329** | 8 | [`groups/pets/schizzles-tsm-battle-pets-all.txt`](groups/pets/schizzles-tsm-battle-pets-all.txt) | [docs/battle-pets.md](docs/battle-pets.md) | 227 cageable species (p:) and 102 pet items (i:), nested under **Schizzle's TSM > Battle Pets**. It nests next to the professions when both are imported. |

Most crafted gear and consumables are split into subgroups by expansion (Classic, Burning Crusade, Wrath, Cataclysm, Pandaria). That way you can attach different Auctioning operations to old-world and current-tier items.

## Operations (v2.2)

The [`operations/`](operations/README.md) folder ships 10 TSM operations. They price from **your realm** first (`dbmarket`, then `dbhistorical`, then 0.8× region market), are capped at 2× region market, and always **post at the minimum price** when undercut below it. The full string `operations/schizzles-tsm-everything-with-operations.txt` creates the whole group tree with these operations already attached:

| Groups | Auctioning | Other operations |
|---|---|---|
| **Schizzle's TSM** root (consumables and everything not listed below inherit it) | Schizzle Normal | Shopping *Schizzle Buy*, Crafting *Schizzle Craft*, Sniper *Schizzle Snipe* |
| Bulk materials: Herbalism, Mining (ore, bars, stone, elementals, smelting), Skinning leather, raw cloth and bolts, dust and essences, raw gems, pigments and inks, raw fish, cooking ingredients, Parts, Shared Reagents, keystones (57 groups) | Schizzle Bulk Mats | |
| Crafted gear: armor, weapons, jewelry, goggles, cloaks, bags, off-hands, trinkets, wands, tools (54 groups) | Schizzle Gear | Vendoring *Schizzle Vendor Gear* |
| **Battle Pets** and the profession **Companion Pets** groups | Schizzle Battle Pets | Shopping *Schizzle Buy Pets* |
| **Battle Pets > High Value** and the **Mounts** groups | Schizzle High Value | |

Mailing operations can't be put in an import string. TSM leaves them out on purpose, so set Mailing up by hand. The exact settings, every formula, the Mailing setup and the import steps are in [operations/README.md](operations/README.md). The data behind the pricing is in [docs/pricing-analysis.md](docs/pricing-analysis.md).

## How to import

1. Type `/tsm`, open the **Groups** tab, and click **Import Group** at the top of the group tree.
2. Open the `.txt` file you want, copy its whole contents (one line, no line breaks), paste it and confirm. TSM shows a summary of the groups and items before creating them.
3. **Pick one approach. Don't use both:**
   - **Only some professions:** import just the per-profession files you want. Each one creates its own top-level group (e.g. **Alchemy**, **Fishing**).
   - **Everything:** import `schizzles-tsm-all-professions.txt`. This creates one parent group **Schizzle's TSM** with all 15 professions under it. Attach your operation to the parent and every subgroup inherits it, or override it per profession.
4. TSM won't take an item out of a group you already have unless you choose to move it. If you have older versions of these groups (e.g. the v1 **Mining**, **Herbalism**, **Cloth**, **Cooking**, **Trade Goods** or **Alchemy** groups), delete them first or let the import move the items.
5. The all-professions string is about 52 KB. Pasting it can freeze the game client for a few seconds. That's normal.
6. Optionally, import the battle pets: `groups/pets/schizzles-tsm-battle-pets-all.txt`, or just the per-subgroup files you want. The all string uses the same **Schizzle's TSM** parent as the all-professions string, so both nest together. No pets item overlaps with any profession group. See [docs/battle-pets.md](docs/battle-pets.md).

## Ownership rules (why an item is where it is)

Since an item can only be in one group, each item goes to exactly one profession using these rules, in this order:

1. **Gathered goods go to the gathering profession.**
   - **Mining:** ore, all metal bars (including transmuted ones such as Arcanite, Truegold, Living Steel and Elementium Ingot), stone, earth/fire elementals, coal and flux.
   - **Herbalism:** herbs, 5.4 herb fragments and life elementals.
   - **Skinning:** all leather, hides and scales, including leathers that Leatherworking can craft and cured hides (e.g. Heavy Leather, Thick Leather, Cured Heavy Hide). Salt goes to Leatherworking.
   - **Tailoring:** all cloth, bolts and specialty silks. There's no separate cloth group in v2. Cloth lives in Tailoring.
   - **Fishing:** all raw fish (moved out of Cooking in v2), lures and fishing poles.
   - **Cooking:** meat, eggs, clams/shellfish and farm produce.
   - **Jewelcrafting:** every uncut gem and pearl, whether prospected, mined or transmuted. They moved from Mining and Alchemy in v2.
   - **Enchanting:** dust, essences and shards.
   - **Inscription:** pigments and inks.
   - **Alchemy:** all other elementals (air, water, mana, shadow, etc.).
2. **Crafted items go to the profession that makes them.** If more than one profession can craft an item, it goes to the profession with more recipes for it, then to this fixed priority: Alchemy, Blacksmithing, Leatherworking, Tailoring, Engineering, Jewelcrafting, Inscription, Enchanting, Cooking, First Aid. Enchant scrolls go to Enchanting.
3. **Shared or bought reagents** that nobody crafts (e.g. vials, salt, Righteous Orbs, dyes, threads) go to the profession that uses them in the most recipes. They're in each profession's **Shared Reagents** subgroup, or **Other Ingredients** for Cooking. Some of these land in a surprising place: Righteous Orb ends up in Blacksmithing, for example, and some raid orbs in Leatherworking. If you'd rather keep them somewhere else, move them in TSM after you import.
4. **Battle pets.** Crafted pet items (`i:`, e.g. the Engineering mechanical pets) stay in their profession group. Their caged versions (`p:`) and all other cageable species and tradeable pet items are in the Battle Pets groups. TSM treats `i:` and `p:` as different items, so nothing is duplicated.

## Not included

- **Soulbound / bind-on-pickup items.** These can't be listed on the AH. That means BoP crafted gear, profession-only items and quest items. Each profession's doc file lists its excluded soulbound items: Enchanting 2, Tailoring 16, Blacksmithing 78, Alchemy 19, Engineering 63, Jewelcrafting 97, Leatherworking 31, Cooking 3, Archaeology 143, Inscription 14.
- **Archaeology is deliberately small.** Every restored artifact and Pandaria crate is soulbound, so the only Archaeology items you can trade are the 11 keystones (Dwarf Rune Stone, Highborne Scroll, Draenei Tome, Vrykul Rune Stick, Nerubian Obelisk, Orc Blood Text, Tol'vir Hieroglyphic, Pandaren Pottery Shard, Mogu Statue Piece, Mantid Amber Sliver, Mantid Amber Piece). The group isn't padded with anything else.
- **Recipes, patterns, plans, formulas and designs** (item class 9). These may come in a later version.
- **Profession tools that can't be traded.** Archaeology survey tools and profession-only bound tools are left out. Tradeable tools (Mining Pick, Skinning Knife, Blacksmith Hammer, fishing poles) are included.
- **Dead items:** Blood Shard (5075, quest item, no use since Cataclysm), Gurubashi Mojo Madness (19931), Elemental Shard (24507, gray item no recipe uses).
- **Placeholders:** items flagged deprecated in the client data, and test/placeholder/"OLD"/"Monster -" names. "Sha-Touched Herb" does not exist as an item and isn't included.

## Notes and caveats

- The expansion subgroups use required level and item ID ranges, so a few items near expansion boundaries may sit one expansion off.
- Some old crafted items come from recipes that can no longer be learned, but the items still exist and can still be traded on the AH, so they're kept.
- The 5.4 items (herb fragments, Ghost Iron Nugget, Kyparite Fragment, etc.) are included even if your realm hasn't reached that patch yet. They do no harm in a group.
- The Alchemy Battle/Guardian elixir split is based on how the elixirs work in game, not on a client data field.

## Version history

- **v1 (Nov 2026):** Trade Goods (Mining, Herbalism, Cloth, Cooking), Alchemy, Engineering Blasting Powders and Pets groups, built from the MoP Classic 5.5.4 client data.
- **v1 rename (Nov 1 2026):** Files and docs renamed with the "Schizzle's" prefix.
- **v2 (Nov 2026): all professions.** The folder was renamed `schizzles-tsm-groups` → `schizzles-tsm` and the project renamed to **Schizzle's TSM**. All 15 professions now have groups, including First Aid, Cooking, Fishing and Archaeology. Each profession has its own import string, plus one all-professions string. Every item belongs to exactly one profession using the ownership rules above. Changes from v1: raw fish moved from Cooking to Fishing, gems moved from Mining and Alchemy to Jewelcrafting, pigments and inks moved from Herbalism to Inscription, cloth now lives in Tailoring, and blasting powders are in Engineering. The v1 strings were replaced by the v2 files. Battle pets were unchanged in v2.

- **v2.1 (Nov 2026): pets revised.** Battle pets moved to `groups/pets/`. The species audit against 5.5.4 data confirmed 227 cageable species. Added 102 tradeable pet items (101 companion items plus the Flawless Battle-Stone). Pets are reorganized into 8 subgroups, each with its own string, plus `schizzles-tsm-battle-pets-all.txt` nested under **Schizzle's TSM > Battle Pets**. Crafted pet items stay in their professions.

- **v2.2 (Nov 2026): operations and price-based High Value.**
  - **Operations.** New `operations/` folder with 10 realm-first operations:
    - Auctioning: Normal, Bulk Mats, Gear, Battle Pets, High Value
    - Shopping: Buy, Buy Pets
    - Crafting: Craft
    - Sniper: Snipe
    - Vendoring: Vendor Gear

    They come as one full group-tree string with the operations attached, plus an operations-only string. The strings were checked against TSM's own import code and formula compiler.
  - **High Value is now data-driven.** It used to be hand-picked. A pet now goes in when its realm value (in the build snapshot) is at least 7,500g and its region sale rate is at least 0.03, plus the TCG/promo pets. That takes it from 45 to 38 entries: 11 kept, 34 moved back to their home subgroups, 27 added.
  - **Pricing analysis.** Added [docs/pricing-analysis.md](docs/pricing-analysis.md), which compares realm and region prices.

## License

MIT, with an attribution requirement. See [LICENSE](LICENSE). Original repo: https://github.com/shawj317/schizzles-mop-classic/https://github.com/shawj317/schizzles-mop-classic/tree/main/Schizzle's%20TSM
