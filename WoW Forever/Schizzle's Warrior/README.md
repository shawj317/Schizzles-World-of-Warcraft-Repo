# Schizzle's Warrior (WoW Forever)

Jon Shaw (Schizzle)'s Warrior interface for WoW Forever. It's the MoP Classic [non-ElvUI interface kit](../../WoW%20Classic%20-%20Mists%20of%20Pandaria/Schizzle's%20Warrior/#non-elvui-interface-kit) carried over to Forever, with a Forever edition of the helper addon that does the setup in one click.

> **Heads-up:** built before Forever's launch on Nov 4 2026 and checked offline against the Forever downloads of each addon. Everything will be checked in game after launch.

| Folder / file | What it is | Format |
|---|---|---|
| [AddOns/SchizzlesWarriorSetup](AddOns/SchizzlesWarriorSetup/) | **Schizzle's Warrior Setup F2.0**: click **Yes** once (or `/schizzle all`) for the console variables, Warrior keybinds, Bartender4, Prat 3.0, SexyMap, Questie, GatherMate2, TomTom and Details!, plus the built-in **XP & Rep Tray**; `/schizzle auras` imports the Musca pack | helper addon |
| [AddOns/Musca Auras](AddOns/Musca%20Auras/) | **Schizzle's Warrior Essentials v1.0**: a visual helper for Musca Auras with proc alerts and sounds, a numbered priority lane per talent tree, rage colours, buffs, target debuffs, stance cooldowns and swing timers | Musca Auras import |
| [AddOns/Auctionator](AddOns/Auctionator/) | a leveling Warrior shopping list: potions, elixirs, sharpening stones, bandages, bags | Auctionator list import |
| [Warrior Guide.md](Warrior%20Guide.md) | the visual helper and how it sits with the Cooldown Manager, priorities per spec, Forever's talent changes, key levels and class quests, spells by level, macros | guide |

## Install order
1. Copy the Forever-ready addons into `_forever_\Interface\AddOns\` ([Addon Compatibility](../Addon%20Compatibility.md)). Keep ElvUI and Plater off.
2. Install the helper addon and click **Yes**. That's the console variables, keybinds, seven addons and the tray done.
3. Install Musca Auras 1.14.0, type `/schizzle auras`, click **Import** and `/reload`. Then `/schizzle cdm` turns off Blizzard's Cooldown Manager, which would sit in the same spot ([Warrior Guide](Warrior%20Guide.md#the-visual-helper-schizzles-warrior-essentials-musca-auras)).
4. From the MoP kit, import the BetterBlizzFrames, Baganator and BigWigs strings and follow the MoveAny, Leatrix Plus, GTFO, RareScanner and BetterFishing click guides; they use downloads that also run on Forever. Skip the MoP Pawn scales (they weigh MoP stats).
5. Import the [Auctionator list](AddOns/Auctionator/).

## What's different from the MoP kit
| | MoP Classic | WoW Forever |
|---|---|---|
| Rotation | WeakAuras All-in-One Rotation | [Schizzle's Warrior Essentials](AddOns/Musca%20Auras/) for Musca Auras: proc alerts, priority lanes and rage colours. A visual helper; Forever hides combat data from addons, so it can't run the MoP aura's logic |
| XP & Rep Tray | WeakAuras import | built into the helper, same size and spot |
| Details! | paste the import string | the helper imports it |
| Console variables | set by hand | the helper sets them |
| Auction house | TSM (with Auctionator lists) | Auctionator until TSM has a Forever build ([Schizzle's TSM](../Schizzle's%20TSM/)) |

The screen layout is the same: the centre stays clear for cooldowns, the two Details! windows sit in the bottom-right corner on top of the tray, the action bars run along the bottom and the minimap is top right.

## License
MIT with an attribution requirement. See the repository [LICENSE](../../LICENSE). AI tools and agents, please read [AGENTS.md](../../AGENTS.md).
