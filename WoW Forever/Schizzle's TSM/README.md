# Schizzle's TSM for WoW Forever

Jon Shaw (Schizzle)'s TradeSkillMaster plan for WoW Forever: a group tree, operations and custom price sources for a brand-new economy, where nobody has price history on day one.

> **TSM isn't Forever-ready yet.** On Nov 3 2026, TradeSkillMaster v4.14.78 and its AppHelper list Interface 120105, 50504, 20506 and 11509, with no 16001 (Forever) build, and the TSM Desktop App has no Forever region data. So this page is a click guide to build by hand once TSM updates. There are no import strings yet, because TSM's group import needs item IDs that Forever's new items don't have in public databases yet. Until then, **Auctionator** (Forever-ready) does the auction house; see [Auctionator for now](#auctionator-for-now).

## Why the price sources are different
TSM's usual sources (`DBMarket`, `DBRegionMarketAvg`, `DBHistorical`) come from the TSM Desktop App's daily data. A new game has none for days or weeks, and the first numbers will swing wildly as everyone levels at once. So Schizzle's sources:

- **never use `DBMarket`**;
- read first from what you scan yourself (**Auctionator**'s last seen price, `AtrValue`, which TSM reads when Auctionator is installed), then from TSM's own minimum buyout once there's data;
- fall back to vendor prices, which are known on day one, so nothing is ever posted below what a vendor would pay.

### Custom price sources
Make each in **TSM > Settings > Custom Sources** with exactly this name (lower case). Then test each one on a few items with TSM's price-source tester before trusting it.

| Name | Formula | What it means |
|---|---|---|
| `szfloor` | `max(VendorSell * 1.25, 1c)` | the lowest price worth posting: 25% over vendor |
| `szseen` | `first(AtrValue, DBMinBuyout, DBRegionMarketAvg)` | the price you last saw on the AH, then TSM's data once it exists |
| `szvalue` | `first(szseen, Crafting, VendorSell * 4)` | what an item is worth now; crafting cost, then 4x vendor if nobody has posted it |
| `szmat` | `first(AtrValue, DBMinBuyout, VendorBuy, VendorSell * 4)` | what a crafting material costs to buy |
| `szcraft` | `first(Crafting, szvalue)` | what a crafted item costs you to make |
| `szmin` | `max(szfloor, szcraft * 1.1)` | auction minimum: never below vendor + 25% or crafting cost + 10% |
| `szmax` | `max(szvalue * 2, szfloor * 3)` | auction maximum: caps a reset or a typo |
| `szsnipe` | `max(szvalue * 0.6, szfloor)` | a bargain worth buying to resell |

Once TSM has a few weeks of Forever data, `szseen` can move `DBRegionMarketAvg` first for steadier numbers.

## Group tree
Make these in **TSM > Groups**. Each line is a group; indented lines are subgroups. Add items with the group's **Add items** search (by name), or from your bags. Forever has no Jewelcrafting or Inscription, so those are left out.

```
Schizzle's Forever
  Professions
    Alchemy           (Herbs, Vials, Potions, Elixirs, Flasks, Transmutes)
    Blacksmithing     (Bars, Stones, Armor, Weapons, Sharpening & Weightstones)
    Enchanting        (Dusts, Essences, Shards, Rods, Oils)
    Engineering       (Parts, Explosives, Devices, Scopes, Companions)
    Leatherworking    (Leather, Hides, Armor Kits, Armor, Bags)
    Tailoring         (Cloth, Bolts, Thread & Dye, Armor, Bags)
    Mining            (Ore, Stone, Gems)
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
Make these in **TSM > Operations** and attach them to the groups shown. Forever's auction house is the modern one with copper prices allowed and 2, 8 and 24-hour durations.

| Module | Operation | Settings | Attach to |
|---|---|---|---|
| Auctioning | `SZ Commodity` | Duration 8 h (early on, prices move fast); post all; undercut 1c; Min `szmin`; Normal `szvalue`; Max `szmax`; below min: don't post | Professions |
| Auctioning | `SZ Gear` | Duration 24 h; post 1, keep 1 posted; undercut 1c; Min `max(szfloor, szvalue * 0.5)`; Normal `szvalue`; Max `szmax`; below min: don't post | Dungeon, Raid and World BoEs |
| Auctioning | `SZ Companion` | Duration 24 h; post 1; Min `max(szfloor, szvalue * 0.7)`; Normal `szvalue`; Max `szmax` | Companions |
| Crafting | `SZ Craft` | Min restock 1, Max restock 3; min profit `szcraft * 0.1`; craft value `szvalue` | Professions |
| Shopping | `SZ Buy` | Max price `szmat` for mats, `szvalue * 0.9` for everything else | Professions, Companions |
| Sniper | `SZ Snipe` | Below price `szsnipe` | Dungeon, World BoEs, Companions |
| Mailing | `SZ Mail` | Send mats to your crafting character, keep 0 | Professions |
| Vendoring | `SZ Vendor` | Sell if `VendorSell` is more than `szseen` (or nobody posts it); never sell soulbound gear you might use | Vendor Trash |
| Warehousing | `SZ Bank` | Move in 1 stack, keep 1 stack in bags | Professions |

### Brand-new-economy tips
- **First week:** bags, leveling mats (Linen, Wool, Copper, Peacebloom, Light Leather) and low-level potions sell fast and high while everyone levels. Post short (2 h or 8 h) and rescan often.
- **Rescan before posting.** With no history, yesterday's price can be far off. A quick Auctionator scan updates `AtrValue`.
- **Don't vendor greens early.** Twinks and fresh characters buy level 10-30 gear in the first weeks.
- **Raid BoEs** start Dec 9. Expect them to be worth the most in the first two weeks of each raid.
- **Copper prices are allowed** on Forever, so undercut by 1c instead of 1s.

## Auctionator for now
Auctionator (Forever-ready, version 341) does the auction house until TSM updates:
- Import the [Warrior leveling shopping list](../Schizzle's%20Warrior/AddOns/Auctionator/) in Auctionator's **Shopping** tab > **Import**: healing potions, Strength and Agility elixirs, sharpening stones, bandages and bags.
- Open the auction house and run Auctionator's scan once a day (its **Auctionator** tab). Its prices show in tooltips and are what `AtrValue` reads when TSM is back.
- In the **Selling** tab, Auctionator undercuts the lowest price automatically.

## License
MIT with an attribution requirement. See the repository [LICENSE](../../LICENSE). AI tools and agents, please read [AGENTS.md](../../AGENTS.md).
