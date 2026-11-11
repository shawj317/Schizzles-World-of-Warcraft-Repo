# SkillLedger

Small World of Warcraft: Forever addon for **Jon Shaw (Schizzle)**. It records professions, bags, bank and auction prices, then shows the cheapest way to level each profession from the current rank to the trained cap. A Python script turns the SavedVariables file into an Excel workbook.

Interface **16001**, the same TOC version as the other Forever addons. The addon folder must be named `SkillLedger`.

## Install

The zip has two folders. Only one of them goes in the game.

1. Copy the `SkillLedger` folder (the one that contains `SkillLedger.toc`) to `World of Warcraft\_forever_\Interface\AddOns\SkillLedger`. WoW loads a folder only when the toc is directly inside it.
2. Leave `tools\` on your desktop. **`tools\` does not go into `Interface\AddOns`.** It is the Excel converter, not an addon. Putting it in AddOns can stop the real addon from loading.
3. `/reload`. The chat line `SkillLedger loaded. Type /skillledger.` means the slash commands are registered.
4. `/skillledger` opens the window. `/sl` does the same when no other addon has claimed it. Escape does not close the window. Close is a button, or `/skillledger hide`.

The window starts left of centre so it stays out of the rotation HUD. On the auction house, SkillLedger is a bottom tab after Browse, Bids, Auctions and any tabs other addons already added. The scan button is on that tab's page, not over Search.

## Commands

| Command | What it does |
|---|---|
| `/skillledger` | show or hide the window. This one is registered even if another addon owns `/sl`. |
| `/sl` | the same, when `/sl` is still free |
| `/skillledger plan` | snapshot bags and reputation, print the plan, open the window |
| `/skillledger scan` | auction scan while the auction house is open. The scan button itself is on the SkillLedger auction-house tab. |
| `/skillledger bags` | snapshot bags, including the reagent bag and keyring when the client has them |
| `/skillledger bank` | snapshot the bank. The bank has to be open. The last snapshot is kept, with the time. |
| `/skillledger help` | list the commands |

Nothing runs on `OnUpdate`. Bag and reputation events only mark the data dirty and take one snapshot after a short pause. The plan is calculated when you ask for it.

TradeSkillMaster and Auctionator are optional. If a reagent has no SkillLedger scan price, the plan may use `first(DBMinBuyout, AtrValue)` or Auctionator's last price. The sheet marks that source. Neither addon is required.

## What it records

Account-wide `SkillLedgerDB`, with a section per character:

- Professions and secondary skills: name, rank, max rank. It tries `GetProfessions` / `GetProfessionInfo`, then the older skill-line API, and ignores a call that is missing.
- Bags on a short delay, and the bank only while the bank is open.
- Auction prices: one full scan when the client allows `C_AuctionHouse.ReplicateItems` or `QueryAuctionItems` with get-all. Otherwise it queries the reagent names, slowly, and only while a scan is running. Each item keeps the minimum buyout per unit, the quantity at that price, and the time.
- Faction standings, from `GetFactionInfo` (headers expanded, then collapsed again) or `C_Reputation` if that is what the client has.
- Merchant-window prices, when a vendor is open. The copper amount is what the client displayed, already discounted. The NPC id is matched to the bundled faction list when the id is known.

## The plan

For each known profession, from the current rank to the trained cap (and never past 300):

- A recipe costs the auction price, the vendor price, or nothing for reagents already in bags or the bank. Stock is used up as the path consumes it.
- Expected crafts follow the classic curve: 100% through yellow, then `(grey - skill) / (grey - yellow)`, which is 50% at the green midpoint. Expected crafts for one point are `1 / chance`. That is the curve described against classic clients; a flat "yellow is 1.5, green is 3 to 4" is the rough average of those bands, and the tail of green is worse, so the plan leaves a recipe when another one is cheaper.
- A reagent with no auction price and no usable vendor is named. The plan prefers a fully priced recipe when one exists.
- If crafting an intermediate (a bar, a bolt, a vial's contents) is cheaper than buying it, the plan buys the raw materials and says so. If buying is cheaper, it says that too.
- Each profession is priced against your full stock. The shopping list adds every profession's needs together and subtracts that stock once, so the same linen is not free for both First Aid and Tailoring.

### Vendor reputation

The discount is the one WoW has used since patch 2.3, which is also the WoW Classic curve:

| Standing | Discount |
|---|---|
| Neutral, and below | none. Unfriendly and worse will not sell |
| Friendly | 5% |
| Honored | 10% |
| Revered | 15% |
| Exalted | 20% |

The client truncates: `floor(catalog * (20 - steps) / 20)`. Friendly on a 20c vial is 19c. Friendly on a 10c thread is 9c, not 10c, because 9.5 is truncated. A 25c drink at Friendly is 23c.

The faction is the one Wowhead lists on the NPC who sells the item. A Horde character is not priced at an Alliance vendor. When several usable factions sell it, the cheapest standing wins. If that standing has not been saved yet, the price is Neutral and the sheet says the standing was assumed.

A price captured from the merchant window replaces the formula while the standing for that faction is unchanged, because that number came from the client. If the standing later moves, the capture is stale and the catalog price is discounted again.

Not applied: the pre-2.3 flat 10% from Honored only, the Cataclysm goblin racial, and any PvP-rank discount. Forever's server binary is not in the client tables. If a fresh merchant price disagrees with this table, the merchant price is the one the plan uses.

## Excel

Log out, or `/reload`, so WoW writes `WTF\Account\<ACCOUNT>\SavedVariables\SkillLedger.lua`. Then run `export.bat` from the `tools` folder (the folder you did not put in AddOns):

```bat
export.bat "C:\World of Warcraft\_forever_\WTF\Account\ACCOUNT\SavedVariables\SkillLedger.lua"
```

Or `py -3 export.py` with the same path. If the path is omitted, the script looks under `World of Warcraft\_forever_\WTF\Account` and uses the newest `SkillLedger.lua`.

`py -3 -m pip install openpyxl` once, for the workbook. Without openpyxl, or with `--csv`, it writes one CSV per sheet.

Sheets: Professions, Inventory, AH Prices, Leveling Plan (one block per profession), Shopping List, and Vendors. Header rows are frozen. Money is gold, silver and copper. Vendors lists every saved standing and its discount, every captured merchant price, and the vendor price the plan actually used.

## Coverage

Built from Forever client **1.60.1.70790** (wago.tools, product wowf) for reagents and products, Wowhead Classic for learn-at ranks and vendor prices, and Classic Era SkillLineAbility **1.15.9.70576** where Wowhead's skill page did not list the spell. Wowhead and Classic Era agree on yellow and grey (1,534 of 1,536 compared spells). Forever's own trivial ranks are shifted on a few hundred shared spells, often by 25 points, while the learn-at field was cleared to 1. Those shared spells use the Wowhead / Classic Era curve. Spells that exist only on Forever use Forever's ranks, and most of those start at yellow because no learn-at rank was published.

| Profession | Skill-up recipes | Notes |
|---|---|---|
| Alchemy | 195 | Healing potions are not here. In this Forever build those spells are empty stubs. |
| Blacksmithing | 473 | |
| Enchanting | 261 | Enchants cost their reagents. The item you enchant is not consumed. |
| Engineering | 268 | |
| Leatherworking | 541 | |
| Tailoring | 432 | |
| Cooking | 131 | |
| First Aid | 31 | Includes Forever's healing-potion line (Peacebloom, spices and a vial) and a few Forever-only items such as First Aid Kit. |
| Mining | 11 | Smelts that grant Mining points. Smelt Steel, Mithril and Thorium have yellow = grey in both client tables, so they are priced as crafts but not used for points. |
| Herbalism, Skinning, Fishing | 2, 2, 1 | Gathering. Points come from nodes, not from a craft shopping list. |

About 930 Forever-only recipes have no published learn-at rank, so the plan starts them at yellow and can miss an orange stretch. 144 recipes are kept only so an intermediate can be crafted or bought; they do not grant points in the published color window.

103 reagents have a Wowhead vendor price. `ItemSparse.BuyPrice` is not used: it is filled in for ore and cloth that no vendor sells. Vendor stock is treated as unlimited. A limited vendor would still show the catalog price. Recipe scrolls and trainer fees are not in the total.

The sample character in `tools/sample/SkillLedger.lua` is not a real character. It is there so the converter can be checked.

## Files

| Path | What it is |
|---|---|
| `SkillLedger/` in the zip, or `AddOns/SkillLedger` in the repo | the addon. This is the only folder that goes in `Interface\AddOns`. |
| `tools/` | converter and tests. Does not go in `Interface\AddOns`. |

## License

MIT, with the repository attribution requirement. Credit **Jon Shaw (Schizzle)** and https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo.
