# Schizzle's TSM for WoW Forever

Jon Shaw (Schizzle)'s TradeSkillMaster setup for WoW Forever: import strings, operations and custom price sources for a brand-new economy, where nobody has price history on day one.

> **TSM works on Forever.** TradeSkillMaster v4.15 (checked with v4.15.2 and AppHelper v4.15, which list Interface 16001) runs on Forever. The TSM Desktop App has no Forever price data yet, so the price sources below lean on Auctionator scans and vendor prices.
>
> **Mining and Blacksmithing ship first**, as ready-to-import groups with operations attached (Jon's Warrior runs both). The other professions and the BoE groups in the [group tree](#group-tree) are still a plan to build by hand; import strings for them are to be decided.

## Files
| File | What it is |
|---|---|
| [custom-sources.md](custom-sources.md) | The 8 `sz` price sources, ready to copy, and how to add them |
| [groups/mining.txt](groups/mining.txt) | Import string: **Schizzle's Forever Mining**, 36 items (Ore 12, Stone 5, Gems Low 5, Mid 4, High 7, Decor 3) with operations |
| [groups/blacksmithing.txt](groups/blacksmithing.txt) | Import string: **Schizzle's Forever Blacksmithing**, 425 items (Bars 17, Stones 5, Sharpening & Weightstones 11, Parts 17, Decor 3, Armor 189, Weapons 90, Plans 93) with operations |
| [groups/operations.md](groups/operations.md) | Every operation's settings, where each is attached, and SZ Mail (made by hand) |
| [groups/items.md](groups/items.md) | Every item in each group, by name and ID; Forever-only items marked |
| [groups/starter-economy.md](groups/starter-economy.md) | What sells in the first weeks, and Forever's new ores, bars and decor |
| `groups/*-items-only.txt` | Backup strings: the same groups and items, no operations |
| [tools/](tools/) | The scripts that build and check the strings from Forever's client data |

Only items in Forever's own client data (build 1.60.1.70790) are included: no Mists of Pandaria items, no Season of Discovery leftovers, nothing bind-on-pickup, and no vendor mats (Coal, fluxes). The strings were checked with TSM v4.15.2's own import code: both load with no errors, no invalid items and no settings reset.

## Import, in this order
1. **Install Auctionator** as well (Forever-ready). TSM reads its scans as `AtrValue`, which the price sources use first.
2. **Custom sources.** In TSM: **Settings > Custom Sources > Add a new custom source**, once for each of the 8 in [custom-sources.md](custom-sources.md), with the exact lower-case names. TSM drops custom sources from group imports, so they must exist first. Test one with `/tsm price [Copper Ore] szvalue`.
3. **Groups, with their operations.** Open `/tsm` > **Groups**, click the **Import group** icon above the group list, and paste the whole of [groups/mining.txt](groups/mining.txt) (open the file and copy everything). In the summary, keep **Include operations?** ticked and click **Import**. Then do the same with [groups/blacksmithing.txt](groups/blacksmithing.txt). If the summary offers **Replace … existing operations (and custom sources)?**, leave it unticked so your own copies stay as they are; both strings carry the same seven operations, so nothing is lost. If TSM asks to **Move already grouped items?**, tick it only if you want these groups to take over items you've already grouped.
4. **SZ Mail by hand**, only if alts gather for the Warrior. TSM leaves Mailing out of imports; see [operations.md](groups/operations.md#sz-mail-make-by-hand).

If a full string ever fails, import the matching `*-items-only.txt` the same way and attach the operations from [operations.md](groups/operations.md) yourself.

## Why the price sources are different
TSM's usual sources (`DBMarket`, `DBRegionMarketAvg`, `DBHistorical`) come from the TSM Desktop App's daily data. A new game has none for days or weeks, and the first numbers will swing wildly as everyone levels at once. So Schizzle's sources:

- **never use `DBMarket`**;
- read first from what you scan yourself (**Auctionator**'s last seen price, `AtrValue`), then from TSM's own minimum buyout once there's data;
- fall back to vendor prices, which are known on day one, so nothing is ever posted below what a vendor would pay.

### Custom price sources
Full list, copy block and steps: [custom-sources.md](custom-sources.md).

| Name | Formula | What it means |
|---|---|---|
| `szfloor` | `max(VendorSell * 1.25, 1c)` | the lowest price worth posting: 25% over vendor |
| `szseen` | `first(AtrValue, DBMinBuyout, DBRegionMarketAvg)` | the price you last saw on the AH, then TSM's data once it exists |
| `szvalue` | `first(szseen, Crafting, VendorSell * 4)` | what an item is worth now; crafting cost, then 4x vendor if nobody has posted it |
| `szmat` | `first(AtrValue, DBMinBuyout, VendorBuy, VendorSell * 4)` | what a crafting material costs to buy |
| `szcraft` | `first(Crafting, szvalue)` | what a crafted item costs you to make |
| `szmin` | `max(szfloor, Crafting * 1.1)` | auction minimum: never below vendor + 25%, or crafting cost + 10% for things you craft |
| `szmax` | `max(szvalue * 2, szfloor * 3)` | auction maximum: caps a reset or a typo |
| `szsnipe` | `max(szvalue * 0.6, szfloor)` | a bargain worth buying to resell |

**Changed Nov 5 2026:** `szmin` used to be `max(szfloor, szcraft * 1.1)`. For anything not crafted, that made the minimum 10% above the item's own value, so TSM would never post it. It now uses `Crafting` directly, which TSM skips for items nobody crafts.

Once TSM has a few weeks of Forever data, `szseen` can move `DBRegionMarketAvg` first for steadier numbers.

## Group tree
Mining and Blacksmithing are imported (above). The rest is the plan for later: make these in **TSM > Groups**, adding items with the group's search or from your bags. Forever has no Jewelcrafting or Inscription, so those are left out.

```
Schizzle's Forever Mining          (imported: Ore, Stone, Gems by bracket, Decor)
Schizzle's Forever Blacksmithing   (imported: Bars, Stones, Sharpening & Weightstones, Parts, Decor, Armor, Weapons, Plans)
Schizzle's Forever                 (to do)
  Professions
    Alchemy           (Herbs, Vials, Potions, Elixirs, Flasks, Transmutes)
    Enchanting        (Dusts, Essences, Shards, Rods, Oils)
    Engineering       (Parts, Explosives, Devices, Scopes, Companions)
    Leatherworking    (Leather, Hides, Armor Kits, Armor, Bags)
    Tailoring         (Cloth, Bolts, Thread & Dye, Armor, Bags)
    Herbalism         (Herbs by bracket)
    Skinning          (Leather, Hides, Scales)
    Cooking           (Meat & Fish, Spices, Food by bracket)
    Fishing           (Raw Fish, Oily Blackmouth & Firefin, Lures)
    First Aid         (Cloth, Bandages, Anti-Venom)
    Poisons           (Vials, Dust & Essence reagents)
    Recipes           (one subgroup per profession: Patterns, Plans, Schematics, Formulas)
  Dungeon BoEs
    10-20             (Ragefire Chasm, Wailing Caverns, The Deadmines, Shadowfang Keep, Blackfathom Deeps, The Stockade)
    20-30             (Gnomeregan, Razorfen Kraul, Scarlet Monastery)
    30-40             (Razorfen Downs, Scarlet Monastery, Uldaman)
    40-50             (Zul'Farrak, Maraudon, Sunken Temple)
    50-60             (Blackrock Depths, Dire Maul, Blackrock Spire, Scholomance, Stratholme)
    Forever dungeons  (Hall of Thanes, Ruins of Lordaeron, Excavation Site: Wetlands, City of Dalaran and the other new ones)
  Raid BoEs           (empty until raids open on Dec 9)
    Onyxia's Lair
    Hyjal Summit
    Barrow Deeps
  World BoEs
    Greens by bracket (10-20 ... 50-60)
    Blues & Epics
  Companions          (pets that are items)
    Vendor            (resold off-faction or out of reach)
    Crafted           (Engineering and the like)
    Drops
  Vendor Trash        (greys and whites with no AH value)
```

### Battle pets
Forever has no Pet Cages (item 82800 isn't in the game), so pets can't be caged and sold the Retail way. Only companions that are still items before you learn them can be traded, which is what the **Companions** group is for. Once learned, a pet can't be sold.

## Operations
The Mining and Blacksmithing imports bring their operations with them; every setting is in [operations.md](groups/operations.md). In short:

| Module | Operation | Settings | Attached to |
|---|---|---|---|
| Auctioning | `SZ Commodity` | 8 h; post all; undercut 0c; Min `szmin`; Normal `max(szvalue, szmin)`; Max `szmax`; below min: don't post | Ores, stones, gems, bars, parts, sharpening stones |
| Auctioning | `SZ Gear` | 24 h; post 1; undercut 0c; Min `max(szfloor, szvalue * 0.5)`; Normal `szvalue`; Max `szmax` | Armor, Weapons, Plans, Decor |
| Crafting | `SZ Craft` | Restock 1 to 3; min profit `szcraft * 0.1`; craft value `szvalue` | Both groups |
| Shopping | `SZ Buy` / `SZ Buy Gear` | Max price `szmat` (mats) / `szvalue * 0.9` (gear) | Mats / Armor, Weapons, Plans, Decor |
| Sniper | `SZ Snipe` | Below price `szsnipe` | Both groups |
| Warehousing | `SZ Bank` | Move all; keep 20 in bags | Both groups |
| Mailing | `SZ Mail` | Made by hand: send to the Warrior, keep 0 | Gathering alts |

**Undercut is 0c, not 1c.** TSM v4.15 saves any undercut under 1 silver as 0c on Forever (as on MoP Classic and Retail), so it posts at the lowest price rather than below it. A 1c undercut can't be set. Details: [operations.md](groups/operations.md#why-the-undercut-is-0c-not-1c).

For the professions still to come, the plan is the same pattern: `SZ Commodity` for mats and consumables, `SZ Gear` (24 h, post 1) for BoEs, an `SZ Companion` (24 h, post 1, Min `max(szfloor, szvalue * 0.7)`) for Companions, and an `SZ Vendor` (sell if `VendorSell` beats `szseen`) for Vendor Trash.

### Brand-new-economy tips
Mining and Blacksmithing specifics are in [starter-economy.md](groups/starter-economy.md).
- **First week:** bags, leveling mats (Linen, Wool, Copper, Peacebloom, Light Leather) and low-level potions sell fast and high while everyone levels. Post short and rescan often.
- **Rescan before posting.** With no history, yesterday's price can be far off. A quick Auctionator scan updates `AtrValue`.
- **Don't vendor greens early.** Twinks and fresh characters buy level 10-30 gear in the first weeks.
- **Raid BoEs** start Dec 9. Expect them to be worth the most in the first two weeks of each raid.

## Auctionator alongside TSM
Auctionator (Forever-ready, version 341) stays installed: its scans feed `AtrValue`.
- Import the [Warrior leveling shopping list](../Schizzle's%20Warrior/AddOns/Auctionator/) in Auctionator's **Shopping** tab > **Import**: healing potions, Strength and Agility elixirs, sharpening stones, bandages and bags.
- Open the auction house and run Auctionator's scan once a day (its **Auctionator** tab). Its prices show in tooltips and are what `AtrValue` reads.

## License
MIT with an attribution requirement. See the repository [LICENSE](../../LICENSE). AI tools and agents, please read [AGENTS.md](../../AGENTS.md).
