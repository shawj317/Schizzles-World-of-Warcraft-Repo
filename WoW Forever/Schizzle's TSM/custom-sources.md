# Schizzle's Forever TSM: custom price sources

Jon Shaw (Schizzle)'s eight price sources for WoW Forever's young economy. Make them **before** importing the groups: the group imports use these names, and TSM only links an operation to a custom source that already exists.

## How to add them
1. Type `/tsm` and open **Settings > Custom Sources**.
2. Click **Add a new custom source**, type the name exactly as shown (lower case, no spaces) and paste the formula.
3. Repeat for all eight, top to bottom (later ones use earlier ones).
4. Test a few in chat: type `/tsm price `, shift-click an item (Copper Ore, Copper Bar) and add the name, for example `/tsm price [Copper Ore] szvalue`. TSM prints the value, or says why there isn't one.

| Name | Formula | What it means |
|---|---|---|
| `szfloor` | `max(VendorSell * 1.25, 1c)` | the lowest price worth posting: 25% over vendor |
| `szseen` | `first(AtrValue, DBMinBuyout, DBRegionMarketAvg)` | the price you last saw on the AH (Auctionator scan), then TSM's own data once it exists |
| `szvalue` | `first(szseen, Crafting, VendorSell * 4)` | what an item is worth now; crafting cost, then 4x vendor if nobody has posted it |
| `szmat` | `first(AtrValue, DBMinBuyout, VendorBuy, VendorSell * 4)` | what a crafting material costs to buy |
| `szcraft` | `first(Crafting, szvalue)` | what a crafted item costs to make (or its value, if it isn't crafted) |
| `szmin` | `max(szfloor, Crafting * 1.1)` | auction minimum: never below vendor + 25%, or crafting cost + 10% for crafted items |
| `szmax` | `max(szvalue * 2, szfloor * 3)` | auction maximum: caps a reset or a typo |
| `szsnipe` | `max(szvalue * 0.6, szfloor)` | a bargain worth buying to resell |

The same formulas, one per line, for copying:

```
szfloor   max(VendorSell * 1.25, 1c)
szseen    first(AtrValue, DBMinBuyout, DBRegionMarketAvg)
szvalue   first(szseen, Crafting, VendorSell * 4)
szmat     first(AtrValue, DBMinBuyout, VendorBuy, VendorSell * 4)
szcraft   first(Crafting, szvalue)
szmin     max(szfloor, Crafting * 1.1)
szmax     max(szvalue * 2, szfloor * 3)
szsnipe   max(szvalue * 0.6, szfloor)
```

## Notes
- **`AtrValue` needs Auctionator.** Keep Auctionator installed and scan once a day; TSM v4.15 reads its prices as `AtrValue`. Without it, `szseen` falls back to TSM's `DBMinBuyout` (from TSM's own scans) and then the TSM Desktop App's region average.
- **`szmin` changed on Nov 5 2026.** The Nov 3 plan had `max(szfloor, szcraft * 1.1)`. For ore, gems and anything not crafted, `szcraft` falls back to `szvalue`, which made the minimum 10% above the normal price. TSM refuses to post an item whose normal price is below its minimum, so nothing would have posted. The new formula uses `Crafting` directly: it only applies to things you can craft, and TSM skips an unknown `Crafting` inside `max()`.
- Once TSM has a few weeks of Forever data, `szseen` can put `DBRegionMarketAvg` first for steadier numbers.
- Every formula was checked with TSM v4.15.2's own price-string parser (see [`tools/`](tools/)).
