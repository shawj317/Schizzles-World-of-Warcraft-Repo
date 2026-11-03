# Schizzle's Warrior Setup (helper addon)

A small addon by Jon Shaw (Schizzle) that applies the Schizzle's Warrior settings for the add-ons that have no import box of their own: **Bartender4**, **Prat 3.0**, **SexyMap**, **Questie**, **GatherMate2** and **TomTom**. It also sets the **Warrior keybinds** for every character. It works on MoP Classic (Interface 50504) and is marked for WoW Forever (Interface 16001).

> **Heads-up:** built and checked offline against each add-on's own code (see [Checks](#checks)). It will be checked in game on WoW Forever after that launches on Nov 4 2026.

It does nothing until you say yes. Each add-on gets a new profile called **Schizzle's Warrior**; your old profiles stay where they are, so you can switch back in that add-on's profile options.

## Install (step by step)
1. Copy the inner `SchizzlesWarriorSetup` folder (the one with the `.toc` file) into `World of Warcraft\_classic_\Interface\AddOns\`.
2. Install the add-ons you want it to set up (any you skip are skipped, not broken). **Turn ElvUI off**; Bartender4 takes over the action bars.
3. Log in. A prompt asks **"Set up Schizzle's Warrior on this character?"** Click **Yes**.
4. It prints one line per add-on in chat, then asks to reload. Click **Reload**.

Each character asks once. On a new character, click **Yes** again (the keybinds are already there; the add-on profiles need choosing per character). Clicked **No**? Type `/schizzle all` any time.

In combat it does nothing and asks you to leave combat first.

## Commands
| Command | Does |
|---|---|
| `/schizzle` | lists the commands and which add-ons are loaded |
| `/schizzle all` | everything below, then asks to reload |
| `/schizzle binds` | the Warrior keybinds (account-wide) |
| `/schizzle bars` | Bartender4: Blizzard preset, then the Schizzle's Warrior layout |
| `/schizzle chat` | Prat 3.0 |
| `/schizzle map` | SexyMap |
| `/schizzle quests` | Questie |
| `/schizzle gather` | GatherMate2 |
| `/schizzle tomtom` | TomTom |

Run any of them again to put that add-on back to the Schizzle's Warrior settings.

## Keybinds
Saved as **account-wide** bindings, so every character gets them. Bar 1 keeps its normal keys (1 to =).

| Bar 3 (Bartender4 bar 3) | Key | | Bar 2 (Bartender4 bar 2) | Key |
|---|---|---|---|---|
| button 1 | Q | | button 1 | Shift-Q |
| button 2 | E | | button 2 | Shift-E |
| button 3 | R | | button 3 | Shift-R |
| button 4 | F | | button 4 | Shift-F |
| button 5 | T | | button 5 | Shift-T |
| button 6 | G | | button 6 | Shift-G |
| button 7 | Y | | button 7 | Shift-Y |
| button 8 | Mouse 3 (wheel click) | | button 8 | Shift-Mouse 3 |
| button 9 | Mouse 4 | | button 9 | Shift-Mouse 4 |
| button 10 | Ctrl-Mouse 3 | | button 10 | Ctrl-Q |
| button 11 | Ctrl-Mouse 4 | | button 11 | Ctrl-E |
| button 12 | Alt-Mouse 3 | | button 12 | Alt-Mouse 4 |

**Movement:** A = strafe left, D = strafe right. Turning is on the arrow keys and the mouse.

Blizzard binds these keys replace: Q/E (strafe, now on A/D), A/D (turn), R (reply to whisper), F (assist target), Y (achievements). The helper also clears any other key that was on the same bar 2 and bar 3 buttons, so each button has exactly the key above.

**Character-specific keybinds:** if a character has **Character Specific Keybindings** ticked (Esc > Key Bindings), the helper says so in chat. Untick it on that character so the account-wide set is used.

### Coming from ElvUI
- ElvUI and Bartender4 use the same action pages, so **your spells stay where they were** on bars 1 to 6.
- ElvUI's bar 1 and bars 3 to 6 used Blizzard's binding slots, which Bartender4 also uses, so their keys carry over. **ElvUI bar 2 used its own binding slots, which stop working when ElvUI is off.** `/schizzle binds` puts those keys on Bartender4 bar 2.
- **Stance bars:** on MoP Classic, neither ElvUI nor Bartender4 swaps bar 1 by stance for Warriors, so nothing changes. On WoW Forever, Bartender4 swaps bar 1 to its Battle, Defensive and Berserker pages (7, 8 and 9), the same as ElvUI did there. Those pages start empty: drag your abilities onto bar 1 once in each stance.
- Want to change a key later? Type `/kb` (Bartender4's keybind mode), hover a button and press the key.

## What each add-on gets
See each add-on's README: [Bartender4](../Bartender4/), [Prat 3.0](../Prat%203.0/), [SexyMap](../SexyMap/), [Questie](../Questie/), [GatherMate2](../GatherMate2/), [TomTom](../TomTom/).

## How it applies settings
- **Bartender4:** switches to a new "Schizzle's Warrior" profile, runs Bartender4's own **Blizzard preset** (the same as the Presets button in its options), then lays the Schizzle's Warrior settings over it.
- **Prat, Questie, GatherMate2, TomTom:** writes a "Schizzle's Warrior" profile into that add-on's saved settings and points this character at it. The add-on loads it on the reload.
- **SexyMap:** writes SexyMap's **global profile** (its "use a global profile" option) and points this character at it. Other characters already on SexyMap's global profile get it too.
- **Keybinds:** sets the keys and saves the account-wide binding set.

## Checks
`source/verify.lua` runs the helper's real code offline in Lua 5.1 (the game's Lua):
- `Data.lua` matches the per-addon `Profile.lua` / `Keybinds.lua` files;
- the keybind code, run against the stock Blizzard binds plus stale ones, leaves exactly the key map above, keeps bar 1, and saves the account-wide set;
- after the profile writes, the add-ons' own **AceDB-3.0** (from their downloads) loads the character onto "Schizzle's Warrior" with every value from the source files, and old profiles are left alone;
- Bartender4 gets a new profile, its Blizzard preset, the overlay on every module, then a refresh;
- SexyMap points the character at the new global profile, and that profile holds exactly the values in SexyMap's `Profile.lua` (map size and spot, border, button visibility, font sizes, movers), with no character names or realms in it;
- every setting key used appears in that add-on's own code.

```
cd source
lua build.lua                  # rebuilds ../SchizzlesWarriorSetup/Data.lua
lua verify.lua /path/to/Interface/AddOns
```

## Version history
- **v2 (Nov 2 2026):** the SexyMap settings are now Jon's own in-game setup: a bigger map in the top-right corner, a tooltip-style bronze border, smaller text and the add-on buttons shown on the map. See the [SexyMap README](../SexyMap/) for the full list. A character that already ran the helper keeps its old map until `/schizzle map` is typed again.
- **v1 (Nov 2 2026):** first release.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
