# Schizzle's Warrior Setup for WoW Forever (helper addon)

A small addon by Jon Shaw (Schizzle) that sets up the Schizzle's Warrior interface on **WoW Forever** (Interface 16001) in one click. It's the Forever edition of the [MoP Classic helper](../../../../WoW%20Classic%20-%20Mists%20of%20Pandaria/Schizzle's%20Warrior/AddOns/SchizzlesWarriorSetup/) with four additions:

- **Console variables** (the game's own settings, see below), including Blizzard's **Cooldown Manager**.
- **Schizzle's Warrior Essentials**, the [Musca Auras pack](../Musca%20Auras/) (proc alerts, priority lanes, rage colours), imported with `/schizzle auras`, so there's no string to paste.
- **Details!** gets the Schizzle's Warrior meter profile imported for you, so there's no import string to paste.
- **XP & Rep Tray** built in: the MoP kit's WeakAuras tray (XP, watched reputation and guild reputation bars in the bottom-right corner), redrawn as plain addon code because WeakAuras has no Forever build.

It also registers **Fira Sans Condensed Medium** with LibSharedMedia, so every addon in the kit can pick the font.

> **Heads-up:** built and checked offline before Forever's launch on Nov 4 2026 (see [Checks](#checks)). It will be checked in game after launch.

Nothing changes until you say yes. Each addon gets a new profile called **Schizzle's Warrior**; old profiles stay, so you can switch back in that addon's profile options.

## Install (step by step)
1. Copy the inner `SchizzlesWarriorSetup` folder (the one with the `.toc` file) into `World of Warcraft\_forever_\Interface\AddOns\`.
2. Install the addons you want it to set up: Bartender4, Prat 3.0, SexyMap, Questie, GatherMate2, TomTom and Details!. Any you skip are skipped, not broken.
3. Log in. A prompt asks **"Set up Schizzle's Warrior on this character?"** Click **Yes**.
4. It prints one line per piece in chat, then asks to reload. Click **Reload** (or type `/reload` if the button does nothing).

Each character asks once. It goes by class: a Warrior gets everything; any other class gets the general UI only (console variables, chat, minimap, Questie, GatherMate2, TomTom, Details! and the tray), with the account-wide keybinds, the Bartender4 bars and `/schizzle auras` left out. Clicked **No**? Type `/schizzle all` any time. In combat it does nothing and asks you to leave combat first.

## Commands
| Command | Does |
|---|---|
| `/schizzle` | lists the commands and which addons are loaded |
| `/schizzle all` | everything below, then asks to reload |
| `/schizzle cvars` | the console variables below |
| `/schizzle binds` | the Warrior keybinds (account-wide) |
| `/schizzle bars` | Bartender4: the Schizzle's Warrior layout, on a fresh profile |
| `/schizzle chat` | Prat 3.0 |
| `/schizzle map` | SexyMap |
| `/schizzle quests` | Questie |
| `/schizzle gather` | GatherMate2 |
| `/schizzle tomtom` | TomTom |
| `/schizzle details` | imports the Schizzle's Warrior Details! profile and switches to it |
| `/schizzle tray` | shows or hides the XP & Rep Tray |
| `/schizzle auras` | opens Musca Auras' import window with [Schizzle's Warrior Essentials](../Musca%20Auras/) in it: click **Import**, then `/reload`. Needs Musca Auras 1.14.0; not part of `all` |
| `/schizzle cdm` | turns Blizzard's Cooldown Manager off or back on |

Run any of them again to put that addon back to the Schizzle's Warrior settings.

## Console variables
Each one is set only if Forever has it; any it doesn't know are listed in chat as skipped.

| Variable | Value | Why |
|---|---|---|
| `autoLootDefault` | 1 | auto loot on (Speedy AutoLoot makes it instant) |
| `ActionButtonUseKeyDown` | 1 | abilities fire when the key goes down |
| `cameraDistanceMaxZoomFactor` | 2.6 | furthest camera zoom |
| `nameplateShowEnemies` | 1 | enemy nameplates on |
| `showTargetOfTarget` | 1 | target-of-target frame |
| `UberTooltips` | 1 | full spell tooltips |
| `cooldownViewerEnabled` | 1 | Blizzard's Cooldown Manager on |

The Cooldown Manager is found under **Options > Gameplay > Advanced Options**. With the Musca pack it shows the same cooldowns in the same spot: `/schizzle cdm` turns it off, or the [Warrior Guide](../../Warrior%20Guide.md#the-cooldown-manager-alongside-the-pack) explains how to keep it for buffs only, out of the pack's way.

## XP & Rep Tray
Three thin bars in the bottom-right corner, under the Details! meters, the same as the MoP WeakAuras tray:

| Bar | Shows | Colours |
|---|---|---|
| XP (top) | level, rested %, XP and %, and XP waiting in completed quests | blue XP, with completed-quest XP in green and rested XP in purple in front of it |
| Watched reputation | faction, standing, value | the standing's colour (friendships too) |
| Guild reputation | guild standing, only in a guild, if Forever has guild reputation on and it isn't already the watched faction | the standing's colour |

- 500 x 10 px bars, 2 px apart, 4 px from the right and bottom edges, so 500 x 34 px with all three. A hidden bar collapses upwards. The XP bar hides at the level cap (60) or with XP turned off.
- Hover a bar for a tooltip with the full numbers.
- Text is Fira Sans Condensed Medium, size 9, with a 1 px dark shadow.
- It reads only values Forever lets addons see, and skips an update rather than erroring if a value comes back hidden.
- `/schizzle tray` turns it off and on (saved for the whole account).

## Keybinds and addon profiles
The same as the MoP kit: the Bar 2 and Bar 3 keys (Q, E, R, F, T, G, Y, mouse buttons and their Shift versions), A/D strafe, Bartender4's bar layout, Prat chat, the square SexyMap minimap, Questie, GatherMate2 and TomTom. The [MoP helper README](../../../../WoW%20Classic%20-%20Mists%20of%20Pandaria/Schizzle's%20Warrior/AddOns/SchizzlesWarriorSetup/#keybinds) has the full key table and what each addon gets.

**Stance bars:** on Forever, Bartender4 swaps bar 1 to its Battle, Defensive and Berserker pages (7, 8 and 9). Those pages start empty: drag your abilities onto bar 1 once in each stance.

## Your own copy (local settings)
The addon in this repo has no character names in it. It isn't needed: the first-login prompt already goes by class. To make it ask only on one character, or to turn the tray off by default, add a second, private addon next to it. Don't commit it.

`Interface\AddOns\SchizzlesWarriorSetup_Local\SchizzlesWarriorSetup_Local.toc`:
```
## Interface: 16001
## Title: Schizzle's Warrior Setup (local settings)
Local.lua
```
`Local.lua`:
```lua
SchizzlesWarriorSetupLocal = {
	character = "YourWarrior", -- only this character gets the first-login prompt
	autoApply = false,         -- true applies everything on first login without asking
	tray = true,               -- the XP & Rep Tray's starting state
}
```
Other characters can still type `/schizzle all`.

## Checks
Run from `source/` with Lua 5.1 (the game's Lua):
- `lua build.lua --check` makes sure `Data.lua` matches the per-addon source files in the MoP kit, `source/CVars.lua` and the Musca pack's import file. `lua build.lua` rebuilds it.
- `lua sim.lua` runs the helper, the first-login prompt, every piece and the tray against a stand-in for the Forever API: the console variables (including one Forever doesn't have), the Details! import (no auto-run code), a missing addon, the tray's three bars at level 20 and at the cap, completed-quest and rested XP, a hidden (secret) value, guild reputation on, off and already watched, the tray toggle, `/schizzle auras` (no Musca Auras, plain WeakAuras, in combat, the exact pack string, left out of `all`), `/schizzle cdm` on and off and on a client without it, the local settings for another character, and a non-Warrior (keybinds and the pack skipped, still asked for the general UI). 37 checks.
- `lua verify.lua <folder with the WoW Forever addon downloads>` is the MoP check, run on the Forever downloads: keybinds against the stock binds, Bartender4, Prat, SexyMap, Questie, GatherMate2 and TomTom profiles through each addon's own AceDB-3.0, and every setting key found in that addon's own code. It passed on Bartender4 4.18.4, Prat 3.9.115, SexyMap v12.1.4, Questie 12.5.0, GatherMate2 1.52.4 and TomTom v4.4.0 (Nov 3 2026).

Every Blizzard function and event the addon calls is in the `forever` branch of Gethe's wow-ui-source (build 70755).

## Font
Fira Sans Condensed Medium is copyright The Mozilla Foundation and Telefonica S.A., under the SIL Open Font License 1.1 (`Media/FiraSansCondensed-OFL.txt`).

## Version history
- **F2.5** (Nov 4 2026): Schizzle's Warrior Essentials v1.13 — Track Minerals reminder (Mining).
- **F2.4** (Nov 4 2026): Schizzle's Warrior Essentials v1.12 — C_Spell hotkeys; Main Rend Forever self-timer; Musca scanner in build gate.
- **F2.3** (Nov 4 2026): Schizzle's Warrior Essentials v1.11 — pack unloads in classic capitals; keeps v1.10 init fix.
- **F2.2** (Nov 4 2026): Schizzle's Warrior Essentials v1.10 — fix Main init custom double-function() import errors; keep v1.9 Rend/queue behaviour.
- **F2.1** (Nov 4 2026): Schizzle's Warrior Essentials v1.9 — Main Rend aura2-primary (fix Forever always-grey); HS/Cleave queue glow only on the queued ability.
- **F2.0** (Nov 4 2026): Schizzle's Warrior Essentials v1.8 — Main Rend only desaturates while your Rend is on the target.
- **F1.9** (Nov 4 2026): Schizzle's Warrior Essentials v1.7 — Main Rend rage/queue/timer states; Target Rend tracker removed.
- **F1.8** (Nov 4 2026): Schizzle's Warrior Essentials v1.6 — Main Rend desaturate-when-present, usable Action Button highlight, Autocast queue sparkle.
- **F1.7** (Nov 4 2026): Schizzle's Warrior Essentials v1.5 — Main labels read real action-bar keybinds; Rend flashes (Proc blink) when remaining < 4s.
- **F1.6** (Nov 4 2026): Schizzle's Warrior Essentials v1.4 — queued HS/Cleave Pixel glow + MH swing swirl on Main priority icons (no standalone Procs auras).
- **F1.5** (Nov 4 2026): Schizzle's Warrior Essentials v1.3 — remove Next Swing row; Heroic Strike/Cleave in Procs with Battle Shout Pixel glow + main-hand swing radial; Battle Shout remaining-time text.
- **F1.4** (Nov 4 2026): Schizzle's Warrior Essentials v1.2 — group default 0,-55; rage bar 100 px wide.
- **F1.3** (Nov 4 2026): Schizzle's Warrior Essentials v1.1 (glow + NEXT SWING on queued Heroic Strike / Cleave); SexyMap regional unique-name key writes plain "First Last" as well as "First Last-PvE".
- **F1.2** (Nov 4 2026): class-aware. Keybinds, Bartender4 bars and the aura pack only run on a Warrior; other classes get the general UI. `/schizzle cdm` waits for combat to end.
- **F1.1** (Nov 3 2026): `/schizzle auras` imports Schizzle's Warrior Essentials into Musca Auras; `/schizzle cdm` toggles the Cooldown Manager.
- **F1** (Nov 3 2026): first Forever edition. Console variables, Cooldown Manager on, Details! import, the built-in XP & Rep Tray, local settings file.

## License
MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). AI tools and agents, please read [AGENTS.md](../../../../AGENTS.md).
