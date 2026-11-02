# Schizzle's TSM: Pricing analysis (v2.2)

Part of [Schizzle's TSM](../README.md). This is the analysis behind the [v2.2 operations](../operations/README.md) and the data-driven **Battle Pets > High Value** group.

**Source:** the TSM desktop app's AuctionDB snapshot for a US Horde realm and the US region, taken 1 Nov 2026. Only AuctionDB market data (realm and region prices and sale rates) is used. No personal sales, character names or gold totals are published here.

## Realm vs region prices

Compared over the 5,175 grouped items that have both a realm market value (`dbmarket`) and a region market value (`dbregionmarketavg`):

| Statistic | Realm ÷ region |
|---|---|
| Median | 0.99 |
| 25th percentile | 0.49 |
| 75th percentile | 1.44 |
| Items cheaper on realm (< 1.0) | 52% |
| Items much cheaper on realm (< 0.8) | 37% |
| Items much dearer on realm (> 1.25) | 31% |

So your realm is **not** uniformly cheaper or dearer than the region. It depends on the category:

| Category | Median realm ÷ region | Median region sale rate | Notes |
|---|---|---|---|
| Inscription | 0.09 | 0.084 | Glyphs are far cheaper on the realm than region-wide. Region-based prices would overprice them about 10× |
| First Aid | 0.50 | 0.21 | |
| Archaeology | 0.86 | 0.032 | Keystones sell slowly |
| Jewelcrafting | 0.95 | 0.125 | |
| Engineering | 0.96 | 0.069 | |
| Alchemy | 0.97 | 0.139 | |
| Enchanting | 0.98 | 0.085 | |
| Cooking | 0.99 | 0.116 | |
| Tailoring | 1.00 | 0.073 | |
| Battle Pets | 1.00 | 0.057 | |
| Skinning | 1.01 | 0.219 | |
| Leatherworking | 1.06 | 0.073 | Gear has thin listings: median realm price is about 1,366g |
| Mining | 1.08 | 0.271 | About 6 sold per day region-wide (median) |
| Blacksmithing | 1.16 | 0.075 | Median realm price is about 1,150g |
| Fishing | 1.17 | 0.164 | |
| Herbalism | 1.22 | 0.271 | About 3.9 sold per day region-wide (median) |

**Conclusions used in the operations:**

1. **Price from the realm first** (`dbmarket`, then `dbhistorical`). Inscription alone shows why region-first is risky in both directions.
2. **Cap at 2× region market.** On thin items, one high listing can inflate the realm market. For example, Shadowgem showed 11.25g realm vs 1.07g region. The cap keeps that from becoming your floor.
3. **Fall back to 0.8× region** only when the realm has no data at all.
4. Bulk mats (Mining, Herbalism, Skinning) sell at a region rate of about 0.22–0.27. They justify a big post cap (1,000) and pricing at market. Gear-heavy professions sell at about 0.07 and pets at about 0.06, so gear and pets post one at a time for 48h.

## Battle pet prices and the High Value rule

Coverage: 321 of the 329 pet entries have a realm price.

| Percentile | Realm market value | Region sale rate |
|---|---|---|
| 10th | | 0.021 |
| 25th | 301g | 0.037 |
| 50th | 1,972g | 0.057 |
| 75th | 6,405g | 0.111 |
| 80th | 8,129g | |
| 85th | 11,040g | |
| 90th | 17,275g | 0.26 |
| 95th | 28,273g | |

**Rule (v2.2):** a pet goes into **High Value** when its **realm value ≥ 7,500g** (about the 78th percentile) **and** its **region sale rate ≥ 0.03** (about the 25th percentile of pets with sale data).

- **Realm value** is realm market value, else realm historical, capped at 2× region market. Pets with no realm price use 0.8× region market.
- TCG/promo pets (Bananas, Eye of the Legion, Gregarious Grell) have no other subgroup, so they also stay in High Value.
- The sale-rate test keeps out expensive pets that almost never sell (e.g. Crawling Claw at about 106,000g with no region sale data). The operations still price those pets from data in their normal subgroup.

| Threshold tested | Pets that qualify on data |
|---|---|
| 5,000g / 0.03 | 55 |
| **7,500g / 0.03 (chosen)** | **36** (+ TCG = 38 entries) |
| 10,000g / 0.03 | 26 |

Result: High Value went from 45 hand-picked entries to **38 data-picked entries** (26 species, 12 items). 11 entries stayed, 34 moved out to their home subgroup and 27 moved in. Each moved-in pet's table row in [battle-pets.md](battle-pets.md) shows its realm value, sale rate and home subgroup.

## Caveats

- The realm/region ratios come from one realm's AuctionDB snapshot. Your realm's numbers will differ, which is why the operations read your realm's own AuctionDB values first.
- AuctionDB values change daily. Re-check the High Value cut every few weeks; the counts will shift.
- The settings assume this client's auction house type (last-in-first-out, no stack sizes), as on the MoP Classic auction house.
