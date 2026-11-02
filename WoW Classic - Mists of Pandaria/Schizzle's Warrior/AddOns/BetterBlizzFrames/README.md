# Schizzle's Warrior BetterBlizzFrames Profile

A BetterBlizzFrames profile for Warriors in MoP Classic 5.5.x by Jon Shaw (Schizzle). It gives the default Blizzard unit frames (player, target, focus, party) a dark, class-coloured look in the same font as the rest of the kit, and filters target and focus debuffs down to the Warrior ones that matter, with glows.

> **Heads-up:** this profile is built for Mists of Pandaria Classic (5.5.x). BetterBlizzFrames also runs on WoW Forever, and the profile is written to carry over (see [WoW Forever](#wow-forever)). It will be checked in game on Forever after that launches.

| File | In-game name | Built for |
|---|---|---|
| [Warrior Profile.txt](Warrior%20Profile.txt) | **Schizzle's Warrior v1.1** (BetterBlizzFrames has no profile names, so this is the name used in this README) | BetterBlizzFrames by Bodify, v2.2.0d (Mists build, Interface 50504) |

The string works for all three specs. It goes with the [WeakAuras rotation](../WeakAuras/), [Plater profiles](../Plater/) and [Details! profiles](../Details!/) and doesn't move or overlap any of them.

## Install (step by step)
1. **Turn off ElvUI's unit frames first** (or disable ElvUI). ElvUI replaces the Blizzard frames that BetterBlizzFrames styles, so the two can't both own them.
2. Install BetterBlizzFrames and log in once.
3. Type `/bbf`. The BetterBlizzFrames settings open.
4. In the list on the left, click **Import & Export** (under Better**Blizz**Frames).
5. In the **Full Profile** box at the top, paste the whole contents of `Warrior Profile.txt` (one line starting and ending with `!BBF`). Paste it once only; a double paste is rejected.
6. Click **Import**. BetterBlizzFrames prints that the import worked and asks to reload.
7. Click to reload, or type `/reload`. The new look applies after the reload.

The import replaces your BetterBlizzFrames settings with these ones; anything the profile doesn't set goes back to BetterBlizzFrames' defaults. It also replaces your BetterBlizzFrames **aura whitelist** with the Warrior list below.

**Only want the debuff list?** Paste the same string into the **Aura Whitelist** box on the same page instead. That imports just the whitelist and leaves your other settings alone.

**Font:** the profile uses **Fira Sans Condensed Medium**, which ships with WeakAuras (WeakAuras registers it with LibSharedMedia), the same as the Plater and Details! pieces. If WeakAuras isn't installed, BetterBlizzFrames falls back to the default font; everything else works.

## What's on screen
- **Dark mode** on the unit frames, castbars, aura borders, action bars and minimap border (BetterBlizzFrames' Dark Mode at its default shade).
- **Class-coloured health bars** on player, target, focus and party, and **class-coloured names**.
- **Realm names hidden** on names, and no coloured name background on target and focus.
- **Numbers shortened** (245k instead of 245000).
- **Fira Sans Condensed Medium** for names (size 11), health and power numbers (size 10), party names and party status text (size 10), and castbar text.
- **Combat indicator** on player, target and focus: crossed swords while the unit is in combat, and nothing at all while it isn't. The red pulsing player frame glow is hidden, since the indicator covers it.
- **Castbars:**
  - **Party castbars** on, with the spell icon and a timer.
  - Target and focus castbars show a **timer**.
  - An **interrupt icon** next to the target and focus castbars shows whether Pummel is ready.
- **Less clutter:** no "Zzz" rest animation or rest glow, no PvP icon or prestige badge, no guide icon, no level text at max level, no debuffs on the target-of-target and focus-of-target frames, no title on the party frames.

### Target and focus debuffs
"Enable Aura Settings" is on, so BetterBlizzFrames filters the debuffs on the target and focus frames. They show:
- **every debuff you cast** ("Only mine"), and
- **the Warrior whitelist below**, from anyone (for example a second Warrior's Weakened Armor), except where it says *yours only*.

Other players' debuffs that aren't on the list are hidden. Buffs on the target and focus are not filtered.

| Debuff | Glow | Notes |
|---|---|---|
| Colossus Smash | **red important glow**, enlarged icon | yours only (the armor bypass only helps the Warrior who cast it) |
| Demoralizing Shout | **gold important glow** | from anyone |
| Deep Wounds | pandemic | yours only |
| Weakened Armor (Sunder Armor, Devastate) | pandemic | from anyone |
| Weakened Blows (Thunder Clap) | pandemic | from anyone |
| Hamstring | pandemic | from anyone |
| Piercing Howl, Mortal Wounds, Physical Vulnerability | none | shown from anyone |
| Rend, Sunder Armor, Thunder Clap, Mortal Strike | as above | listed for WoW Forever; Rend was removed from Warriors in Mists |

- **Important glow:** a coloured glow around the icon for as long as the debuff is up.
- **Pandemic glow:** a red glow when about 5 seconds are left, so you know to refresh it. It only shows on debuffs you cast (BetterBlizzFrames' "Only Pandemic Mine", on by default). Debuffs about to fall off sort first.
- The list is keyed by **spell name**, so every rank and spell ID of a debuff counts.

To add or remove debuffs, open `/bbf` → **Buffs & Debuffs** (or type `/bbf wl <spell name or ID>` to add one).

## What the profile doesn't change
- **Frame positions and sizes.** BetterBlizzFrames doesn't move the player, target, focus or party frames, the player castbar or the buff frame here; they stay where Blizzard (or you) put them. That keeps them clear of the rotation aura at 0, -40 from the screen centre, its cooldown tray, and the two Details! windows in the bottom right.
- **Nameplates.** Plater or BetterBlizzPlates owns them (see the [BetterBlizzPlates profile](../BetterBlizzPlates/)). BetterBlizzFrames has no nameplate or nameplate-castbar options of its own on MoP; the one nameplate-related option (dark mode on the class resource shown on nameplates) is set to **off** in the string.
- **Your own buffs and debuffs** (top right) stay as Blizzard shows them. Buff filtering for the player is off.
- **Action bar fonts, bar textures, chat filters, the minimap and Masque.** All left at BetterBlizzFrames' defaults.
- **BetterBlizzFrames' own settings-window font** (a cosmetic option for the `/bbf` window). Not set.

## WoW Forever
BetterBlizzFrames runs on WoW Forever with a separate set of files (`forever/` in its source, picked when the game reports Interface 16xxx). The import string and its decoder are shared between Mists and Forever, so the same string imports on both. Checked in the v2.2.0d source:
- Every setting in the profile is also read by the Forever code, except **Sort Pandemic Auras**, which Forever doesn't have. Forever ignores it.
- Forever's default Dark Mode shade is a little darker (0.2 vs 0.3 on Mists). The profile keeps the default, so each game uses its own.
- Forever has its own aura code. It reads the same whitelist entries (important, pandemic, only mine), but the aura layout and glow styles there are different and haven't been checked yet.
- The whitelist also lists the pre-Mists debuff names Forever uses (Rend, Sunder Armor, Thunder Clap, Mortal Strike), so it doesn't need a separate list.

## Known limits
- **Not tested in game yet.** The string was built with BetterBlizzFrames' own export code and checked offline against its own import code (see [Source files](#source-files-source)).
- **Settings outside BetterBlizzFrames' default list stay as they were.** When it imports a full profile, BetterBlizzFrames resets only the settings in its default list. Options that aren't on that list (most "Hide …" boxes, for example) keep their current value unless the profile sets them. On a fresh install that doesn't matter. If you've been trying options, type `/bbf reset` first (it wipes BetterBlizzFrames' settings and reloads), then import.
- The import replaces your aura whitelist (see above). Use the Aura Whitelist box to export yours first if you want to keep it.
- "Blizzard Default Filter" for target and focus debuffs is forced off by BetterBlizzFrames on MoP, so it isn't used.

## Source files (`source/`)
- `profile.lua`: the settings and the whitelist, as a plain Lua table.
- `common.lua`: loads BetterBlizzFrames' own libraries (LibDeflate, LibSerialize-BB) and `shared/ImportExport.lua` from a BetterBlizzFrames checkout, and reads its default settings for Mists and Forever.
- `build.lua`: writes `Warrior Profile.txt` by calling BetterBlizzFrames' own `BBF.ExportProfile`, the same code as the Export button.
- `verify.lua`: checks the string with BetterBlizzFrames' own code:
  - `BBF.OldImportProfile` (the code behind the Import button) accepts it, and it round-trips through export and import unchanged;
  - every setting is a real BetterBlizzFrames setting on Mists, with the same type as its default, and nameplate options are off;
  - every whitelist entry uses BetterBlizzFrames' current whitelist format;
  - WeakAuras registers the font;
  - a simulated import and `/reload` leaves every setting at the profile value;
  - BetterBlizzFrames' own target/focus debuff filter (copied from `classics/modules/auras.lua` when the check runs) shows and glows the right debuffs and hides the rest;
  - BetterBlizzFrames' own combat indicator code (copied from `classics/modules/combat.lua`) shows the crossed swords in combat and hides the icon out of combat on player, target and focus.

```
cd source
BBF_SRC=/path/to/BetterBlizzFrames lua build.lua
BBF_SRC=/path/to/BetterBlizzFrames WA_TYPES=/path/to/WeakAuras/Types.lua lua verify.lua
```

## Version history
- **v1.1 (Nov 2 2026):** the combat indicator now shows only in combat. Out of combat it used to show a Sap icon; that is now turned off (`combatIndicatorShowSap = false`).
- **v1 (Nov 2 2026):** first release. Dark mode, class colours, Fira Sans Condensed Medium, combat indicator, party castbars, clutter hiding, and target/focus debuff filtering with a Warrior whitelist and glows.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
