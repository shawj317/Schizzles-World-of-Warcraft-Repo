# Schizzle's TSM: Operations (v2.2)

Part of [Schizzle's TSM](../README.md), by Jon Shaw (Schizzle). These are TSM4 operations for MoP Classic, set up for selling battle pets, profession mats and crafted goods. Every price reads your own realm's AuctionDB data first, so they work on any realm.

Use the full string if you want the groups and these operations together. Use the operations-only string if your groups are already imported and you only want the pricing rules. You need TSM4 on MoP Classic. Back up `TradeSkillMaster.lua` before you paste. The steps are in [How to import](#how-to-import).

## Files

| File | What it creates |
|---|---|
| [`schizzles-tsm-everything-with-operations.txt`](schizzles-tsm-everything-with-operations.txt) | The whole **Schizzle's TSM** tree: all 15 professions plus Battle Pets, 5,644 items in 233 groups. The 10 operations below are already attached to the right groups. About 34 KB. |
| [`schizzles-tsm-operations-only.txt`](schizzles-tsm-operations-only.txt) | Just the 10 operations. They sit on an empty helper group, **Schizzle's TSM Operations**, with one empty subgroup per Auctioning operation (Normal, Bulk Mats, Gear, Battle Pets, High Value). Use this to add the operations to groups you already have. Once the operations exist, you can delete the helper group. |

Both strings use TSM's own export format: `LibSerialize` → `LibDeflate` compress → print-encode, with magic `TSM_EXPORT` version 1. They were checked against the TSM4 source (`GroupImport.lua`, MoP Classic build):

- Both decode with no errors, and the decoded tables match the tables they were built from exactly.
- In strict mode, TSM reports 0 invalid items and 0 changed operations, meaning every setting matches the operation schema.
- Every price formula compiles in TSM's own CustomString compiler, with all of its price sources checked.

## Pricing rule: your realm first

Every price starts from one base value. It uses **your realm's** numbers first and only falls back to the region:

```
min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg)
```

1. **Realm market value** (`dbmarket`) when your realm has a price.
2. Otherwise **realm historical** (`dbhistorical`).
3. Otherwise **80% of the region market value** (`0.8*dbregionmarketavg`). The 20% discount means an item with no realm price at all isn't listed at the full region price.
4. Always **capped at 2× the region market value**. A thin realm market can be skewed by one overpriced listing. The cap stops that listing from setting your price.

Pets also use a capped realm historical as a floor helper: `min(dbhistorical, 2*dbregionmarketavg)`.

> **Why the formulas are written out in full (custom sources):** TSM export strings have a slot for custom sources, but this TSM version's import (`GroupImport:Commit`) rebuilds that list from custom sources **already on your profile**. On a profile that doesn't have them, imported custom sources are silently dropped. This was confirmed by running TSM's own import code. So the shipped operations don't depend on custom sources. If you want the short names for `/tsm price` testing, add them by hand under **/tsm → Settings → Custom Sources**:
>
> - `schizzlebase` = `min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg)`
> - `schizzlehist` = `min(dbhistorical, 2*dbregionmarketavg)`

## Group → operation map

| Group | Auctioning | Shopping | Crafting | Sniper | Vendoring |
|---|---|---|---|---|---|
| **Schizzle's TSM** (root, inherited by everything not listed below) | Schizzle Normal | Schizzle Buy | Schizzle Craft | Schizzle Snipe | none |
| Raw and bulk materials: herbs, ore, bars, stone, leather, cloth, bolts, dust/essences, raw gems, pigments, inks, fish, cooking ingredients, keystones, Parts and Shared Reagents | **Schizzle Bulk Mats** | (root) | (root) | (root) | none |
| Crafted gear: armor, weapons, jewelry, goggles, cloaks, bags, off-hands, trinkets, wands, tools | **Schizzle Gear** | (root) | (root) | (root) | **Schizzle Vendor Gear** |
| **Battle Pets** (all pet subgroups except High Value) and the profession **Companion Pets** groups | **Schizzle Battle Pets** | **Schizzle Buy Pets** | (root) | (root) | none |
| **Battle Pets > High Value**, and the **Mounts** groups (Engineering, Jewelcrafting, Tailoring) | **Schizzle High Value** | (inherits Buy Pets / root) | (root) | (root) | none |

Everything else uses the root operations. That includes potions, flasks, elixirs, cut gems, glyphs, enchant scrolls, cooked food, bandages, explosives, armor kits, spellthreads and other consumables. Full list of overridden groups:

<details><summary><b>Schizzle Bulk Mats</b>: 57 groups</summary>

Alchemy > Shared Reagents, Alchemy > Transmutes & Elementals, Archaeology > Keystones, Blacksmithing > Parts, Blacksmithing > Shared Reagents, Cooking > Clams & Shellfish, Cooking > Eggs, Cooking > Ironpaw & Specialty Ingredients, Cooking > Meat, Cooking > Other Ingredients, Cooking > Pandaria Farm Produce, Enchanting > Dust & Essences - Burning Crusade, Enchanting > Dust & Essences - Cataclysm, Enchanting > Dust & Essences - Classic, Enchanting > Dust & Essences - Pandaria, Enchanting > Dust & Essences - Wrath, Enchanting > Shared Reagents, Engineering > Parts, Engineering > Shared Reagents, Fishing > Fish - Burning Crusade, Fishing > Fish - Cataclysm, Fishing > Fish - Classic, Fishing > Fish - Pandaria, Fishing > Fish - Wrath, Herbalism > Elementals, Herbalism > Herb Fragments (5.4), Herbalism > Herbs - Burning Crusade, Herbalism > Herbs - Cataclysm, Herbalism > Herbs - Classic, Herbalism > Herbs - Pandaria, Herbalism > Herbs - Wrath, Inscription > Inks, Inscription > Pigments, Inscription > Shared Reagents, Jewelcrafting > Parts, Jewelcrafting > Raw Gems - Burning Crusade, Jewelcrafting > Raw Gems - Cataclysm, Jewelcrafting > Raw Gems - Classic, Jewelcrafting > Raw Gems - Pandaria, Jewelcrafting > Raw Gems - Wrath, Jewelcrafting > Shared Reagents, Leatherworking > Shared Reagents, Mining > Bars, Mining > Elementals, Mining > Ore, Mining > Smelting Supplies, Mining > Stone, Skinning > Leather & Hides - Burning Crusade, Skinning > Leather & Hides - Cataclysm, Skinning > Leather & Hides - Classic, Skinning > Leather & Hides - Pandaria, Skinning > Leather & Hides - Wrath, Tailoring > Bolts, Tailoring > Raw Cloth, Tailoring > Shared Reagents, Tailoring > Specialty Cloth & Silk, Tailoring > Thread & Cloth Reagents

</details>

<details><summary><b>Schizzle Gear</b> + Vendoring **Schizzle Vendor Gear**: 54 groups</summary>

Alchemy > Stones & Trinkets, Blacksmithing > Armor - Mail - Burning Crusade, Blacksmithing > Armor - Mail - Classic, Blacksmithing > Armor - Plate - Burning Crusade, Blacksmithing > Armor - Plate - Cataclysm, Blacksmithing > Armor - Plate - Classic, Blacksmithing > Armor - Plate - Pandaria, Blacksmithing > Armor - Plate - Wrath, Blacksmithing > Armor - Shields, Blacksmithing > Tools, Blacksmithing > Weapons - Burning Crusade, Blacksmithing > Weapons - Cataclysm, Blacksmithing > Weapons - Classic, Blacksmithing > Weapons - Pandaria, Blacksmithing > Weapons - Wrath, Enchanting > Wands, Engineering > Bags, Engineering > Goggles & Gear - Burning Crusade, Engineering > Goggles & Gear - Classic, Engineering > Goggles & Gear - Pandaria, Engineering > Goggles & Gear - Wrath, Engineering > Guns & Bows, Inscription > Cards & Trinkets, Inscription > Off-hands & Staves, Inscription > Tools, Jewelcrafting > Jewelry - Burning Crusade, Jewelcrafting > Jewelry - Cataclysm, Jewelcrafting > Jewelry - Classic, Jewelcrafting > Jewelry - Pandaria, Jewelcrafting > Jewelry - Wrath, Jewelcrafting > Tools, Leatherworking > Armor - Leather - Burning Crusade, Leatherworking > Armor - Leather - Cataclysm, Leatherworking > Armor - Leather - Classic, Leatherworking > Armor - Leather - Pandaria, Leatherworking > Armor - Leather - Wrath, Leatherworking > Armor - Mail - Burning Crusade, Leatherworking > Armor - Mail - Cataclysm, Leatherworking > Armor - Mail - Classic, Leatherworking > Armor - Mail - Pandaria, Leatherworking > Armor - Mail - Wrath, Leatherworking > Armor - Misc, Leatherworking > Bags, Leatherworking > Cloaks, Mining > Tools, Skinning > Tools, Tailoring > Armor - Cloth - Burning Crusade, Tailoring > Armor - Cloth - Cataclysm, Tailoring > Armor - Cloth - Classic, Tailoring > Armor - Cloth - Pandaria, Tailoring > Armor - Cloth - Wrath, Tailoring > Armor - Misc, Tailoring > Bags, Tailoring > Cloaks

</details>

<details><summary><b>Schizzle Battle Pets</b> + Shopping **Schizzle Buy Pets**: 5 groups</summary>

Battle Pets, Enchanting > Companion Pets, Engineering > Companion Pets, Inscription > Companion Pets, Jewelcrafting > Companion Pets

</details>

<details><summary><b>Schizzle High Value</b>: 4 groups</summary>

Battle Pets > High Value, Engineering > Mounts, Jewelcrafting > Mounts, Tailoring > Mounts

</details>


## Operation settings

All Auctioning operations share: undercut 0c, bid 100%, **When below minimum: Post at minimum price**, **When above maximum: post at maximum**, cancel undercut on, cancel-to-repost on.

### Schizzle Normal

| Setting | Value |
|---|---|
| Minimum price | `max(1.05*vendorsell, 0.85*min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg), crafting)` |
| Normal price | `max(1.05*vendorsell, 1.1*min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg), 1.2*crafting)` |
| Maximum price | `max(1.05*vendorsell, 2*min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg), 1.5*crafting)` |
| (same, written with the optional custom sources) | min `max(1.05*vendorsell, 0.85*schizzlebase, crafting)` · normal `max(1.05*vendorsell, 1.1*schizzlebase, 1.2*crafting)` · max `max(1.05*vendorsell, 2*schizzlebase, 1.5*crafting)` |
| Post cap | 5 |
| Duration | 24h |
| Undercut | 0c (your client has the last-in-first-out AH, where TSM only allows 0c or ≥1s) |
| Bid percent | 100% |
| When below minimum | **Post at minimum price** (`priceReset = minPrice`) |
| When above maximum | Post at maximum price |
| Keep quantity / max expires / ignore low duration | 0 / 0 (no limit) / off |
| Cancel undercut auctions / cancel to repost higher | on / on, repost threshold 1g |

### Schizzle Bulk Mats

| Setting | Value |
|---|---|
| Minimum price | `max(1.05*vendorsell, 0.8*min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg), crafting)` |
| Normal price | `max(1.05*vendorsell, min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg))` |
| Maximum price | `max(1.05*vendorsell, 1.5*min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg))` |
| (same, written with the optional custom sources) | min `max(1.05*vendorsell, 0.8*schizzlebase, crafting)` · normal `max(1.05*vendorsell, schizzlebase)` · max `max(1.05*vendorsell, 1.5*schizzlebase)` |
| Post cap | 1000 |
| Duration | 24h |
| Undercut | 0c (your client has the last-in-first-out AH, where TSM only allows 0c or ≥1s) |
| Bid percent | 100% |
| When below minimum | **Post at minimum price** (`priceReset = minPrice`) |
| When above maximum | Post at maximum price |
| Keep quantity / max expires / ignore low duration | 0 / 0 (no limit) / off |
| Cancel undercut auctions / cancel to repost higher | on / on, repost threshold 10s |

### Schizzle Gear

| Setting | Value |
|---|---|
| Minimum price | `max(1.05*vendorsell, 0.8*min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg))` |
| Normal price | `max(1.25*vendorsell, min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg))` |
| Maximum price | `max(2*vendorsell, 2*min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg))` |
| (same, written with the optional custom sources) | min `max(1.05*vendorsell, 0.8*schizzlebase)` · normal `max(1.25*vendorsell, schizzlebase)` · max `max(2*vendorsell, 2*schizzlebase)` |
| Post cap | 1 |
| Duration | 48h |
| Undercut | 0c (your client has the last-in-first-out AH, where TSM only allows 0c or ≥1s) |
| Bid percent | 100% |
| When below minimum | **Post at minimum price** (`priceReset = minPrice`) |
| When above maximum | Post at maximum price |
| Keep quantity / max expires / ignore low duration | 0 / 0 (no limit) / off |
| Cancel undercut auctions / cancel to repost higher | on / on, repost threshold 1g |

### Schizzle Battle Pets

| Setting | Value |
|---|---|
| Minimum price | `max(50g, 0.75*min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg), 0.6*min(dbhistorical, 2*dbregionmarketavg))` |
| Normal price | `max(100g, 1.25*min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg))` |
| Maximum price | `max(200g, 3*min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg))` |
| (same, written with the optional custom sources) | min `max(50g, 0.75*schizzlebase, 0.6*schizzlehist)` · normal `max(100g, 1.25*schizzlebase)` · max `max(200g, 3*schizzlebase)` |
| Post cap | 1 |
| Duration | 48h |
| Undercut | 0c (your client has the last-in-first-out AH, where TSM only allows 0c or ≥1s) |
| Bid percent | 100% |
| When below minimum | **Post at minimum price** (`priceReset = minPrice`) |
| When above maximum | Post at maximum price |
| Keep quantity / max expires / ignore low duration | 0 / 0 (no limit) / off |
| Cancel undercut auctions / cancel to repost higher | on / on, repost threshold 10g |

### Schizzle High Value

| Setting | Value |
|---|---|
| Minimum price | `max(500g, 0.85*min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg), 0.7*min(dbhistorical, 2*dbregionmarketavg))` |
| Normal price | `max(1000g, 1.25*min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg))` |
| Maximum price | `max(2000g, 3*min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg))` |
| (same, written with the optional custom sources) | min `max(500g, 0.85*schizzlebase, 0.7*schizzlehist)` · normal `max(1000g, 1.25*schizzlebase)` · max `max(2000g, 3*schizzlebase)` |
| Post cap | 1 |
| Duration | 48h |
| Undercut | 0c (your client has the last-in-first-out AH, where TSM only allows 0c or ≥1s) |
| Bid percent | 100% |
| When below minimum | **Post at minimum price** (`priceReset = minPrice`) |
| When above maximum | Post at maximum price |
| Keep quantity / max expires / ignore low duration | 0 / 0 (no limit) / off |
| Cancel undercut auctions / cancel to repost higher | on / on, repost threshold 50g |


**What each one is for:**

- **Schizzle Normal (crafted consumables).** Prices never go below craft cost (`crafting`) or 5% over vendor price. Normal price is 10% above the realm base or 20% above craft cost. 24h listings, 5 at a time.
- **Schizzle Bulk Mats (raw materials).** It lists at the realm base, with a floor at 80% of it, up to 1,000 per post. The 80% floor stops you from dumping mats far below the market.
- **Schizzle Gear.** One of each, 48h listings. It never posts below 5% over vendor price. Unsold gear goes to the vendor (see Vendoring).
- **Schizzle Battle Pets.** One per species, 48h listings. Hard floors are 50g, 100g and 200g because caged pets have no vendor price. Pets with no price data at all still post at 50g min / 100g normal / 200g max.
- **Schizzle High Value.** Like Battle Pets, but with a 500g floor, a tighter minimum (85% of base) and a 50g cancel threshold.

### Shopping: Schizzle Buy

| Setting | Value |
|---|---|
| restockQuantity | `0` |
| maxPrice | `0.9*min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg)` |
| showAboveMaxPrice | on |
| restockSources | alts=off, auctions=on, bank=on, guild=off |

### Shopping: Schizzle Buy Pets

| Setting | Value |
|---|---|
| restockQuantity | `0` |
| maxPrice | `0.7*min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg)` |
| showAboveMaxPrice | on |
| restockSources | alts=off, auctions=on, bank=on, guild=off |

### Crafting: Schizzle Craft

| Setting | Value |
|---|---|
| minRestock | `1` |
| maxRestock | `5` |
| minProfit | `max(1g, 0.1*min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg))` |
| craftPriceMethod | (blank = use global craft value) |

### Sniper: Schizzle Snipe

| Setting | Value |
|---|---|
| belowPrice | `max(0.95*vendorsell, ifgte(dbregionsalerate, 0.1, 0.65*min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg), 0))` |

### Vendoring: Schizzle Vendor Gear

| Setting | Value |
|---|---|
| sellAfterExpired | `3` |
| sellSoulbound | off |
| keepQty | `0` |
| restockQty | `0` |
| restockSources | alts=off, ah=off, bank=off, guild=off, alts_ah=off, mail=off |
| enableBuy | off |
| enableSell | on |
| vsMarketValue | `min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg)` |
| vsMaxMarketValue | `1.25*vendorsell` |
| vsDestroyValue | `destroy` |
| vsMaxDestroyValue | `1.25*vendorsell` |


- **Schizzle Buy / Buy Pets (Shopping).** Shows auctions at or below 90% (mats and goods) or 70% (pets) of the realm base. Higher listings are still shown.
- **Schizzle Craft (Crafting).** Only queues crafts that profit at least 10% of the item's value, minimum 1g. Restock range is 1–5. Leave "craft value" blank so it uses your global craft value setting (see below).
- **Schizzle Snipe (Sniper).** Always catches vendor flips (95% of vendor price). For items that sell at a region rate of 0.1 or higher, it also catches listings at or below 65% of the realm base. Slow sellers, including most pets, are only sniped below vendor price.
- **Schizzle Vendor Gear (Vendoring).** Only on gear groups. It sells to the vendor after 3 expired listings, and only when the AH value is under 1.25× the vendor price **and** disenchanting is worth less than 1.25× the vendor price. Buying and soulbound selling are off.
- **Warehousing:** no operation is shipped. Your existing #Default stays in place.

## Mailing (set up by hand)

TSM doesn't include Mailing operations in export strings (`IMPORT_EXPORT_IGNORED_OPERATION_TYPES`), so add it manually if you use a crafter or bank alt:

1. **/tsm → Operations → Mailing → Create**, name it `Schizzle Mail Mats`.
2. **Target:** your crafting character. **Keep quantity:** 0. **Max quantity:** off. **Restock:** off.
3. Attach it to the bulk-material groups you craft with (e.g. **Mining > Ore**, **Herbalism**, **Tailoring > Raw Cloth**), then use **Mailing → Send** on the alts.

## Recommended global settings (not importable)

Under **/tsm → Settings → Crafting**, switch these to realm-first so Crafting and Normal profit math agrees with the Auctioning prices:

| Setting | Recommended value |
|---|---|
| Default material cost method | `min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), crafting, vendorbuy, convert(dbmarket))` |
| Default craft value method | `0.95*min(first(dbmarket, dbhistorical, 0.8*dbregionmarketavg), 2*dbregionmarketavg)` |

Both compile in TSM's CustomString compiler.

## How to import

1. **Back up first.** Copy `WTF/Account/<account>/SavedVariables/TradeSkillMaster.lua` somewhere safe.
2. **If you already have a group called `Schizzle's TSM`** (from the v2 all-professions or all-pets strings), delete it, or rename it to `Schizzle's TSM old`. Otherwise TSM imports the new tree as **Schizzle's TSM 1**.
3. On GitHub, open `schizzles-tsm-everything-with-operations.txt` and click **Copy raw file**. Then `/tsm` → **Groups** → **Import Group**, and paste.
4. In the import dialog, leave all three checkboxes on (they're on by default):
   - **Move N already grouped items?** pulls the items out of any groups you already have them in (for example this repo's v1 **Trade Goods** or **Pets** groups).
   - **Include operations?** creates the operations.
   - **Replace N existing operations?** only appears if you import a second time.

   The operations are all named `Schizzle …`, so they won't clash with operations you already have (including TSM's `#Default`).
5. **Check it:** open **Schizzle's TSM > Mining > Bars**. It should show Auctioning **Schizzle Bulk Mats**. **Battle Pets > High Value** should show **Schizzle High Value**. Then run a Post scan.
6. **Groups only, without operations:** use the v2 strings in `../groups/` instead. To add only the operations to your own groups: import `schizzles-tsm-operations-only.txt`, attach the operations to your groups, then delete the empty **Schizzle's TSM Operations** group. The operations stay.

Your existing operations aren't changed or deleted. They may follow different rules, for example **When below minimum = Don't post** or region-first pricing, which is why these operations are kept separate. Once you're happy with the new set, you can delete the old ones or keep them for other groups.

Test any formula with `/tsm price [item link] <formula>`.
