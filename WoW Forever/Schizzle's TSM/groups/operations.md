# Schizzle's Forever TSM: operations

The operations Jon Shaw (Schizzle)'s Mining and Blacksmithing imports bring with them, and where each one is attached. [`mining.txt`](mining.txt) and [`blacksmithing.txt`](blacksmithing.txt) carry every operation below except **SZ Mail**: TSM leaves Mailing out of group imports and exports, so that one is made by hand ([below](#sz-mail-make-by-hand)). Both strings hold the same seven operations, so whichever is imported second finds them already there.

Make the [custom sources](../custom-sources.md) first. The operations use them by name.

## Attached where
| Group | Auctioning | Crafting | Shopping | Sniper | Warehousing |
|---|---|---|---|---|---|
| Schizzle's Forever Mining (Ore, Stone, Gems) | SZ Commodity | SZ Craft | SZ Buy | SZ Snipe | SZ Bank |
| Mining > Decor | **SZ Gear** | SZ Craft | **SZ Buy Gear** | SZ Snipe | SZ Bank |
| Schizzle's Forever Blacksmithing (Bars, Stones, Sharpening & Weightstones, Parts) | SZ Commodity | SZ Craft | SZ Buy | SZ Snipe | SZ Bank |
| Blacksmithing > Armor, Weapons, Plans, Decor | **SZ Gear** | SZ Craft | **SZ Buy Gear** | SZ Snipe | SZ Bank |

Subgroups not in bold inherit from the top group.

## Settings
| Module | Operation | Settings |
|---|---|---|
| Auctioning | `SZ Commodity` | Duration: the middle one (8 h on Forever); post cap 50000 (post everything in your bags); keep 0; max expires 0 (off); undercut 0c (see below); Min `szmin`; Normal `max(szvalue, szmin)`; Max `szmax`; below min: don't post (`none`); above max: post at max; cancel undercut on; cancel to repost higher on, threshold 5s |
| Auctioning | `SZ Gear` | Duration: the longest (24 h); post cap 1; keep 0; undercut 0c; Min `max(szfloor, szvalue * 0.5)`; Normal `szvalue`; Max `szmax`; below min: don't post; above max: post at max; cancel undercut on; cancel to repost higher on, threshold 50s |
| Crafting | `SZ Craft` | Min restock 1, max restock 3; min profit `szcraft * 0.1`; craft value `szvalue` |
| Shopping | `SZ Buy` | Max price `szmat`; show items above max price on; no restock |
| Shopping | `SZ Buy Gear` | Max price `szvalue * 0.9`; show items above max price on; no restock |
| Sniper | `SZ Snipe` | Below price `szsnipe` |
| Warehousing | `SZ Bank` | Move quantity 0 (all); keep 20 in bags (one stack of most mats); keep 0 in bank; no restock |

### Why the undercut is 0c, not 1c
Jon's plan said "undercut 1c". TSM v4.15 can't store that on Forever. TSM runs Forever's auction house the modern way (as on MoP Classic and Retail, not the Vanilla and TBC Classic way), and on those clients any undercut under 1 silver is saved as **0c**: TSM posts at the current lowest price instead of below it. A 1c undercut typed in by hand turns back into 0c when TSM loads the operation, so the import ships 0c. (This comes from TSM's own code, `AuctioningOperation.lua` in v4.15.2.) Matching the lowest price also stops everyone shaving the price down copper by copper.

### Why Normal is `max(szvalue, szmin)`
TSM won't post an item whose normal price is below its minimum. A crafted item nobody has posted yet has `szvalue` = its crafting cost, and `szmin` = crafting cost + 10%, so plain `szvalue` would block it. `max(szvalue, szmin)` posts it at the minimum instead.

## SZ Mail (make by hand)
1. `/tsm` > **Operations** > **Mailing** > **Create New**, name it `SZ Mail`.
2. Target: the Blacksmith (Jon's Warrior) by character name.
3. **Keep this amount** 0; **Set max quantity** off; **Restock target to max quantity** off.
4. Attach it to **Schizzle's Forever Mining** on the gathering alts only (gatherers mail ore, stone and gems to the Warrior), and to **Blacksmithing > Bars** if an alt smelts.
5. At a mailbox, open TSM's **Groups** tab, tick the groups and click **Mail Selected Groups** (hold Ctrl for a dry run first).

If the Warrior does all the mining himself, skip SZ Mail.
