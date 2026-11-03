# Schizzle's Warrior Leatrix Plus Setup

Leatrix Plus settings for the non-ElvUI Warrior kit in MoP Classic 5.5.x by Jon Shaw (Schizzle). Leatrix Plus is a big box of small quality-of-life switches. Here it only does the jobs no other kit addon does, like selling junk, repairing, blocking duels, bigger trainer and profession windows and a longer camera zoom. Anything another addon already covers (chat, minimap, tooltips, action bars, unit frames, moving frames) stays off, so two addons never change the same thing.

> **Heads-up:** Leatrix Plus has no profile import, so this is a click guide. Every option, label and default was checked against Leatrix Plus 5.1.57-mists, the official Mists of Pandaria Classic build from CurseForge (see [Source files](#source-files-source)). Leatrix Plus isn't on Wago, so get it from CurseForge. Leatrix Plus ships a separate download for each game version, and this guide is for the Mists one. On WoW Forever, use the Leatrix Plus download made for Forever once there is one; its option names are mostly the same, but check each box exists before following this list.

## Install (step by step)
1. Install **Leatrix Plus** (the Mists of Pandaria Classic file) from CurseForge and log in.
2. Type `/ltp` (or click its minimap button, which MinimapButtonButton collects).
3. Every Leatrix Plus box starts **unticked**. Tick only the boxes in the table below, page by page (the page names are down the left side).
4. Click **Reload** at the bottom right when you're done. Most options only take effect after a reload.

## Tick these
| Page | Box | What it does |
|---|---|---|
| Automation | **Automate gossip** | skips the chat window at many utility NPCs (hold Shift to stop it). Hold Alt to pick an NPC's only option at once. |
| Automation | **Accept summon** | accepts summons automatically unless you're in combat |
| Automation | **Accept resurrection** | accepts out-of-combat resurrections. Combat resurrections still ask, because "Exclude combat resurrection" is on by default in its cog. |
| Automation | **Release in PvP** | releases your spirit automatically in battlegrounds |
| Automation | **Sell junk automatically** | sells every grey item when you open a vendor (Baganator already greys junk out, so you can see what goes) |
| Automation | **Repair automatically** | repairs at any repair vendor. Click its cog and tick **Repair using guild funds if available** if your guild pays. |
| Social | **Block duels** | declines duel requests unless they come from a friend (guild members count as friends) |
| Social | **Block pet battle duels** | the same for pet battles |
| Social | **Party from friends** | accepts group invites from friends and guild members, unless you're queued for a battleground |
| Social | **Queue from friends** | accepts the Dungeon Finder queue when the party leader is a friend. Pick your role in the Dungeon Finder window once for this to work. |
| Interface | **Enhance dressup** | pan and zoom in the dressing room |
| Interface | **Enhance quest log** | adds options to the quest log, in its cog (for example **Show quest levels**). Questie keeps working. |
| Interface | **Enhance professions** | a larger professions window |
| Interface | **Enhance trainers** | a larger trainer window with a **Train All** button |
| Interface | **Show durability status** | a button on the character frame that shows your gear's durability when you hover over it, plus a percentage in chat when you die |
| Interface | **Show Wowhead links** | a Wowhead link in the quest log and the achievements window |
| System | **Max camera zoom** | lets you zoom out further |
| System | **Silence rested emotes** | silences emote sounds while you're resting (cities and inns) |
| System | **Keep audio synced** | game sound follows you when you switch headset or speakers in Windows. This sets the game's output device to the system default. |
| System | **Faster movie skip** | Escape cancels a cinematic without asking first |
| System | **Dismount me** | lets you set extra rules for when you're dismounted automatically, in its cog |

**Guild** on the Social page is already ticked, so guild members count as friends for the Social options. Leave it ticked.

## Leave these off
Each of these duplicates something another kit addon already does, so turning it on in Leatrix Plus too would make the two fight.

| Page | Box | Already done by |
|---|---|---|
| Automation | **Automate quests** | Questie (and you'll want to read the quest text) |
| Chat | **Use easy resizing**, **Hide chat buttons**, **Move editbox to top**, **Disable sticky chat**, **Use arrow keys in chat**, **Disable chat fade**, **Use class colors in chat**, **Increase chat history** | Prat 3.0 (buttons, edit box, history, class-coloured names) |
| Text | **Hide error messages**, **Hide portrait numbers** | BetterBlizzFrames |
| Text | **Hide keybind text**, **Hide macro text** | Bartender4 (its buttons have their own text settings) |
| Interface | **Enhance minimap** | SexyMap |
| Interface | **Enhance tooltip** | MoveAny places the tooltip; TSM, Pawn and Auctionator add their own lines to it |
| Interface | **Show cooldowns** | the WeakAuras HUD and its cooldown tray |
| Interface | **Show ready timer** | BigWigs, which already shows a dungeon finder ready timer |
| Frames | **Manage widget**, **Manage timer** | MoveAny (the kit uses one frame mover) |
| Frames | **Class colored frames** | BetterBlizzFrames, which prints a conflict warning in chat if this box is on |
| Frames | **Hide gryphons**, **Hide stance bar** | Bartender4, which hides the Blizzard bar art and places the stance bar |
| System | **Faster auto loot** | Speedy AutoLoot |
| System | **Expand vendor price** | TSM, whose tooltip already shows vendor prices |
| System | **Combat plates** | BetterBlizzPlates |

Everything not named in either table is left at its default (off).

## Source files (`source/`)
- `settings.lua`: each box in both tables, with its page, its key in Leatrix Plus's settings and its label.
- `verify.lua`: checks the guide against Leatrix Plus's own `Leatrix_Plus.lua`:
  - every key exists as a Leatrix Plus option with the label shown above, and the README names it;
  - every one of them starts unticked, while Guild and "Exclude combat resurrection" start ticked;
  - the guild funds option, `/ltp` and the Reload button are where the guide says;
  - the download is the Mists build (`Leatrix_Plus_Mists.toc`, Interface 50504).

```
cd source
lua verify.lua /path/to/Interface/AddOns
```

## Version history
- **v1 (Nov 2 2026):** first release.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
