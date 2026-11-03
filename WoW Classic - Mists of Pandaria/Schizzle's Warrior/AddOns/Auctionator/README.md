# Schizzle's Warrior Auctionator Lists

Two Auctionator shopping lists for the non-ElvUI Warrior kit in MoP Classic 5.5.x by Jon Shaw (Schizzle): everything an Arms or Fury raid night needs, and the same for Protection. Each line is an exact-name search, so a scan only finds the item you meant (no "Recipe: ..." or similar names). Auctionator runs alongside [Schizzle's TSM](../../../Schizzle's%20TSM/), which does the posting and cancelling.

> **Heads-up:** this is Auctionator's own list import format, checked with Auctionator's own import and search code (see [Source files](#source-files-source)). Auctionator is one download for every game version, including WoW Forever. The items are Mists of Pandaria items; on Forever, swap in that version's consumables once it's live.

| File | Imports as | Needs |
|---|---|---|
| [Shopping Lists.txt](Shopping%20Lists.txt) | two shopping lists: `Schizzle's Warrior DPS` and `Schizzle's Warrior Tank` | Auctionator |

## Install (step by step)
1. Install Auctionator and open the auction house. If TSM's auction window opens, use TSM's button at the top of that window to switch to the Blizzard auction window, where Auctionator's tabs are.
2. Click Auctionator's **Shopping** tab at the bottom of the window.
3. Click **Import**, paste the whole contents of `Shopping Lists.txt` (two lines), and click **Import**.
4. Both lists appear under **Shopping Lists**. Click one and Auctionator searches every item on it.

Importing again replaces the entries in those two lists. Other lists aren't changed.

## The lists
| Schizzle's Warrior DPS (Arms, Fury) | Schizzle's Warrior Tank (Protection) |
|---|---|
| Flask of Winter's Bite (+1000 Strength) | Flask of the Earth (Stamina, for big hits) |
| Potion of Mogu Power (+4000 Strength) | Flask of Winter's Bite (Strength, everything else) |
| Black Pepper Ribs and Shrimp (+300 Strength food) | Potion of Mogu Power (the usual pick) |
| Bold Primordial Ruby (red and prismatic sockets) | Potion of the Mountains (+12000 armour) |
| Inscribed Vermilion Onyx (yellow sockets) | Chun Tian Spring Rolls (+450 Stamina food) |
| Etched Imperial Amethyst (blue sockets) | Black Pepper Ribs and Shrimp (+300 Strength food) |
| Living Steel Belt Buckle (extra belt socket) | Solid River's Heart (blue socket, Stamina) |
| | Living Steel Belt Buckle (extra belt socket) |

The picks follow Wowhead's MoP Classic Arms and Protection Warrior consumables guides. To add an item, select the list, type the item's name in the search box, and click **Add to List**.

## Auctionator and TSM together
They both work at the auction house, so each gets a job:

| Job | Who does it | Why |
|---|---|---|
| Posting, cancelling, mailing | **TSM** | its operations price from your realm's market value and never post under your minimum |
| Shopping lists and quick searches | **Auctionator** | its lists are quicker for buying the same consumables every week |
| Price lines in item tooltips | **TSM** | one set of prices, so the tooltip doesn't show two different "market values" |

To keep them from getting in each other's way:
1. In **Options > AddOns > Auctionator > Tooltips**, untick **Show auction house value of items in tooltips** and **Show vendor sell prices in item tooltips** (TSM's tooltip shows both), and untick the disenchant line if it's on.
2. In Auctionator's **Basic Options**, leave **Run autoscan when Auction House is opened** unticked. TSM's AuctionDB data already covers market prices, and a full scan from each addon on every visit just slows the auction house down.
3. Don't post with Auctionator's **Selling** tab and TSM's posting scan on the same items: their prices are worked out differently, so they'd undercut each other.

## Source files (`source/`)
- `lists.lua`: the two lists, as a plain Lua table, with a note for each item.
- `build.lua`: writes `Shopping Lists.txt` (`List Name^"item"^"item"`, one list per line; `--check` tells you if it's out of date).
- `verify.lua`: runs Auctionator's own `Source/Shopping/ImportExport.lua` and search parser (`Source/Search/Advanced.lua`):
  - the Import button sends a string with `^` to the list import, and the file has no `*` that would send it to the old format;
  - both lists are created with every entry, and each entry parses as an exact search for the item's name;
  - Auctionator's "import finished" event fires for both, so the Shopping tab shows them;
  - other lists aren't touched, and importing twice doesn't double the entries.

```
cd source
lua build.lua
lua verify.lua /path/to/Interface/AddOns
```

## Version history
- **v1 (Nov 2 2026):** first release.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
