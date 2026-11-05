# Schizzle's Warrior Auctionator List (WoW Forever)

An Auctionator shopping list for leveling a Warrior on WoW Forever by Jon Shaw (Schizzle): healing potions, Strength and Agility elixirs, sharpening stones, bandages and bags for every level bracket. Each line is an exact-name search, so a scan only finds the item you meant.

> **Heads-up:** this is Auctionator's own list import format, checked with the code of Auctionator 341 (the Forever-ready download; see [Source files](#source-files-source)). The items use the original game's names. Anything Forever renamed or removed just returns nothing; it will be checked in game after launch.

| File | Imports as | Needs |
|---|---|---|
| [Shopping Lists.txt](Shopping%20Lists.txt) | one shopping list: `Schizzle's Warrior Leveling` | Auctionator |

## Install (step by step)
1. Install Auctionator and open the auction house.
2. Click Auctionator's **Shopping** tab at the bottom of the window.
3. Click **Import**, paste the whole contents of `Shopping Lists.txt`, and click **Import**.
4. The list appears under **Shopping Lists**. Click it and Auctionator searches every item on it.

Importing again replaces the entries in that list. Other lists aren't changed.

## The list
| Kind | Items |
|---|---|
| Healing potions | Minor, Lesser, (plain), Greater, Superior and Major Healing Potion |
| Strength | Elixir of Lion's Strength, Elixir of Ogre's Strength, Elixir of Giants |
| Agility (crit) | Elixir of Minor Agility, Elixir of Agility, Elixir of the Mongoose |
| Sharpening stones | Rough, Coarse, Heavy, Solid and Dense |
| Bandages | Heavy Linen, Wool, Silk, Mageweave and Runecloth |
| Bags | Linen, Woolen, Mageweave and Runecloth Bag |

## Auctionator and TSM on Forever
TradeSkillMaster v4.15 runs on Forever. Keep Auctionator installed alongside it: [Schizzle's TSM for WoW Forever](../../../Schizzle's%20TSM/) reads Auctionator's scanned prices first (as `AtrValue`), because a new economy has no TSM market data. Auctionator on its own still covers shopping, posting (its **Selling** tab undercuts automatically) and tooltip prices.

## Source files (`source/`)
| File | Does |
|---|---|
| `lists.lua` | the list, one item per line with a comment |
| `build.lua` | writes `Shopping Lists.txt` from `lists.lua`; `lua build.lua --check` fails if it's out of date |
| `verify.lua` | `lua verify.lua <AddOns folder>` runs Auctionator's own import and search code on the file: the import button takes the `^` path, the list is created with every entry as an exact search, other lists are left alone, and importing twice doesn't double it |

## License
MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). AI tools and agents, please read [AGENTS.md](../../../../AGENTS.md).
