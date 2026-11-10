# WoW Forever addon compatibility (Nov 3 2026)

Which addons in the Schizzle's Warrior kit say they support WoW Forever, checked by Jon Shaw (Schizzle)'s setup the day before launch. "Forever-ready" means the download's `.toc` lists **Interface 16001** (Forever's interface number) or ships a `_Camelot.toc` (Forever's internal name). That's what the author claims; everything is checked in game after launch.

Forever is build 1.60.1.70755 and installs to `World of Warcraft\_forever_\`, so addons go in `_forever_\Interface\AddOns\`, separate from Classic's `_classic_` folder.

## Forever-ready
| Addon | Version | How it supports Forever | Kit job |
|---|---|---|---|
| Schizzle's Warrior Setup | F1.2 | Interface 16001 | one-click setup, XP & Rep Tray |
| Wayfarer | 1.3.4 | Interface 16001, `AllowLoadGameType: camelot, forever` | zone quest route. Not checked in game yet |
| Musca Auras | 1.14.0 | Interface 16001 (a WeakAuras fork; the folder is called `WeakAuras`) | [Schizzle's Warrior Essentials](Schizzle's%20Warrior/AddOns/Musca%20Auras/): proc alerts, priority lanes, rage colours |
| Bartender4 | 4.18.4 | 16001 in its main TOC | action bars, stance bar |
| BetterBlizzFrames | v2.2.0e | `_Camelot.toc` | unit frames, cast bar |
| BetterBlizzMarkers | v1.1.4 | 16001 | raid markers |
| BetterPersonalResourceDisplay | 2.3.0 | 16001 | personal resource bar |
| Prat 3.0 | 3.9.115 | `_Camelot.toc` | chat |
| SexyMap | v12.1.4 | 16001 | minimap |
| Questie | 12.5.0 | `_Camelot.toc` | quest helper |
| RXPGuides (RestedXP) | v4.11.30 | 16001 | leveling routes |
| GatherMate2 | 1.52.4 | 16001 | herb and ore nodes |
| HandyNotes | v1.6.32 | 16001 | map notes |
| TomTom | v4.4.0 | 16001 | waypoint arrow |
| Details! (and its plugins) | 20261015.15339.172 | `_Camelot.toc` | damage and threat meters |
| BigWigs | v427.8 | 16001 | boss timers |
| GTFO | 6.12.2 | `_Camelot.toc` | "get out of the fire" alerts |
| Baganator + Syndicator | 839 / 289 | 16001 | bags |
| Auctionator | 341 | 16001, Forever-only files | auction house scans; TSM reads them as `AtrValue` |
| TradeSkillMaster + TSM AppHelper | v4.15.2 / v4.15 | 16001 (also 120105, 50504, 20506, 11509) | auction house, crafting and mail; see [Schizzle's TSM for Forever](Schizzle's%20TSM/) |
| Pawn | 2.14.1 (Forever) | Forever download | gear upgrade arrows |
| MoveAny | v1.14.1 (Forever) | Forever download, `_Camelot.toc` | moves Blizzard windows |
| Leatrix Plus | 1.60.25 (Forever) | Forever download | quality-of-life switches |
| RareScanner | 1.60.1 (Forever) | Forever download | rare alerts |
| Speedy AutoLoot | 124 | 16001 | instant looting |
| BetterFishing | 66 | 16001 | double-click fishing |
| Platynator | 537 | 16001 | nameplates |
| MinimapButtonButton | 1.24.14 | `_Camelot.toc` | gathers minimap buttons |
| Altoholic + DataStore | 1.60.005 / 2026.10.14 | Forever download / 16001 | alts' bags, gold and professions |
| WowSimsExporter | v3.2.6 | 16001 | gear export for sims |
| BugSack + !BugGrabber | v12.1.9 / v12.1.1 | 16001 | Lua error catcher |
| BugTabs | 1.4.9 | 16001 | Lua error tabs |

## Not Forever-ready yet
| Addon | What it lists | What to do |
|---|---|---|
| **WeakAuras** | no Forever download | Use Musca Auras instead (above): it's a WeakAuras fork for Forever and runs [Schizzle's Warrior Essentials](Schizzle's%20Warrior/AddOns/Musca%20Auras/). The MoP WeakAuras imports don't carry over, and the XP tray is built into Schizzle's Warrior Setup. ForeverAuras is another fork; it can't import the Musca pack, so install only one of them. |
| **WagoAppCompanion** | Retail, Cata and TBC only | Leave it off on Forever. |
| **LittleWigs** | no Forever download | BigWigs works; dungeon timers wait for LittleWigs. |

## Desktop apps
- **TSM Desktop App:** has no Forever region data yet, so TSM's `DBMarket`-style prices don't exist yet even though TSM v4.15 runs on Forever. Schizzle's TSM price sources don't rely on them.
- **Wago App:** its companion addon doesn't support Forever and doesn't sync Musca Auras. Nothing to do for Forever yet.
- **CurseForge app:** CurseForge lists Forever files under game version 1.60.1. If the app shows Forever as a separate install, point it at the `_forever_` folder to keep these updated; otherwise update by hand from each project's Files tab.

## Not part of this check
ElvUI, Plater and BetterBlizzPlates are left as they are. GSE is All Rights Reserved and isn't redistributed here.

## License
MIT with an attribution requirement. See the repository [LICENSE](../LICENSE). AI tools and agents, please read [AGENTS.md](../AGENTS.md).
