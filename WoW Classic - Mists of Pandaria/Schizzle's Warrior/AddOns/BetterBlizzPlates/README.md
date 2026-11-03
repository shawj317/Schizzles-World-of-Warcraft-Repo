# Schizzle's Warrior BetterBlizzPlates Profile

A BetterBlizzPlates profile for Warriors in MoP Classic 5.5.x by Jon Shaw (Schizzle). It styles the default Blizzard nameplates to match the rest of the kit: a dark look in the same font, class colours on enemy players, role-aware threat colours, castbars that track Pummel, an Execute indicator, and the same Warrior debuff list and glows as the [BetterBlizzFrames profile](../BetterBlizzFrames/). It is an alternative to the [Plater profiles](../Plater/). Use one or the other, not both.

> **Heads-up:** this profile is built for Mists of Pandaria Classic (5.5.x). BetterBlizzPlates also runs on WoW Forever, and the profile is written to carry over (see [WoW Forever](#wow-forever)). It will be checked in game on Forever after that launches.

| File | In-game name | Built for |
|---|---|---|
| [Warrior Profile.txt](Warrior%20Profile.txt) | **Schizzle's Warrior v2** (BetterBlizzPlates has no profile names, so this is the name used in this README) | BetterBlizzPlates by Bodify, v2.2.3c (Mists build, Interface 50504) |

The string works for all three specs. It goes with the [WeakAuras rotation](../WeakAuras/), [BetterBlizzFrames profile](../BetterBlizzFrames/) and [Details! profiles](../Details!/). BetterBlizzPlates doesn't need BetterBlizzFrames; they are separate add-ons that work side by side.

## Install (step by step)
1. **Disable Plater first** (in the AddOns list on the character screen). Plater and BetterBlizzPlates both take over the nameplates, so only one can be on.
2. Install BetterBlizzPlates and log in once. If it asks you to pick a starting setup (Classic or Retail), pick either; the import replaces it.
3. Type `/bbp`. The BetterBlizzPlates settings open.
4. In the list on the left, click **Import & Export** (under Better**Blizz**Plates).
5. In the **Full Profile** box at the top, paste the whole contents of `Warrior Profile.txt` (one line starting and ending with `!BBP`). Paste it once only; a double paste is rejected.
6. Click **Import**. BetterBlizzPlates prints that the import worked and asks to reload.
7. Click to reload, or type `/reload`. The new look applies after the reload.

**Updating from an older version:** do the same steps with the new `Warrior Profile.txt`. The whole profile is replaced, so there is nothing to tick or delete first.

The import replaces your BetterBlizzPlates settings with these ones; anything the profile doesn't set goes back to BetterBlizzPlates' defaults. It also replaces your BetterBlizzPlates **aura whitelist** with the Warrior list below.

**Only want the debuff list?** Paste the same string into the **Aura Whitelist** box on the same page instead. That imports just the whitelist and leaves your other settings alone.

**Font:** the profile uses **Fira Sans Condensed Medium**, which ships with WeakAuras (WeakAuras registers it with LibSharedMedia), the same as the BetterBlizzFrames, Plater and Details! pieces. If WeakAuras isn't installed, BetterBlizzPlates falls back to the default font; everything else works.

## What's on screen
- **Dark look:** flat "Minimalist" bar texture, a near-black solid background behind the health bar, black borders, and a **white border on your target**.
- **Class colours on enemy players.** Enemy NPCs keep Blizzard's red (hostile) and yellow (neutral) colours.
- **Size:** enemy health bars 136 wide and 14 tall. Realm names are hidden, and so are the level and the elite dragon.
- **Names on their own row.** The enemy's name sits centred above the bar, high enough to clear the health numbers (for example `240 100%`). Those numbers are Blizzard's, not BetterBlizzPlates': Blizzard draws them when the health options under Esc > Options > Nameplates are on. With the Legacy, Thin, Health Focus and Cast Focus nameplate styles they sit just above the bar on the right; with Classic, Modern or Block they sit inside the bar. The debuff icons sit above the name.
- **Fira Sans Condensed Medium** for names, castbar text and the other nameplate text.
- **Threat colours**, by role. BetterBlizzPlates treats you as a tank when you are in **Protection spec**, and as DPS in Arms or Fury. Threat colours show in dungeons, raids and the open world, on mobs that are in combat; mobs out of combat keep the normal colours. Battlegrounds and arenas use the normal colours.

  | You are | Green | Orange | Red | Blue |
  |---|---|---|---|---|
  | Tank (Protection) | you have threat | you are losing it | not on you | another tank (or a pet) has it |
  | DPS (Arms, Fury) | safe, it's on someone else | it is targeting you | it is hitting you | n/a |

  A **threat %** (your share of the mob's threat) shows to the right of the bar whenever you have any.
- **Castbars**, 12 tall, with a timer and the name of whoever interrupted a cast:
  - **gold** = interruptible cast, **cyan** = interruptible channel, **grey** = can't be interrupted;
  - **bronze** = Pummel won't be off cooldown before the cast ends;
  - **orange with a green spark** = Pummel comes back during the cast; the spark marks when, and the bar turns back to gold or cyan once Pummel is ready.
- **Execute indicator:** below 20% health, the health % (for example `18%`) shows on the left of the bar.

### Enemy debuffs
Enemy nameplates show:
- **every debuff you cast** ("Only mine"), and
- **the Warrior whitelist below**, from anyone (for example a second Warrior's Weakened Armor), except where it says *yours only*.

Other players' debuffs that aren't on the list are hidden. The list and glows are the same as in the BetterBlizzFrames profile.

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
- **Pandemic glow:** a glow near the end of the debuff, so you know to refresh it. It only shows on debuffs you cast (BetterBlizzPlates' "only mine" pandemic setting, on by default).
- The list is matched by **spell name**, so every rank and spell ID of a debuff counts.

To add or remove debuffs, open `/bbp` and edit the aura whitelist in the nameplate aura settings.

## What the profile doesn't change
- **Friendly nameplates and your personal resource bar.** Left at BetterBlizzPlates' defaults.
- **Nameplate spacing, scale and fade (Blizzard's nameplate CVars).** BetterBlizzPlates saves these from your game on first login and keeps them; the profile doesn't set them.
- **Buffs on enemies** (enrage, magic). Off, as in BetterBlizzPlates' defaults.
- **The WeakAuras rotation, the BetterBlizzFrames unit frames and the Details! windows.** Untouched. Nameplates sit in the game world, so they don't overlap the rotation aura at 0, -40 from the screen centre.

## WoW Forever
BetterBlizzPlates runs on WoW Forever with a separate set of files (`forever/` in its source). The import string and its decoder are shared, so the same string imports on both. Checked in the v2.2.3c source:
- Every setting in the profile is also read by the Forever code, except **solid background** (the bar background is still darkened there, on Forever's own texture) and the Mists-only **MoP update** flag. Forever ignores both.
- Forever has its own nameplate code, so sizes, colours and glows there haven't been checked yet.
- The whitelist also lists the pre-Mists debuff names Forever uses (Rend, Sunder Armor, Thunder Clap, Mortal Strike), so it doesn't need a separate list.

## Known limits
- **Not tested in game yet.** The string was built with BetterBlizzPlates' own export code and checked offline against its own import code (see [Source files](#source-files-source)).
- **Tank detection is by spec, not stance.** In Arms or Fury, Defensive Stance still counts as DPS for the threat colours.
- **Settings outside BetterBlizzPlates' default list stay as they were.** When it imports a full profile, BetterBlizzPlates resets only the settings in its default list. On a fresh install that doesn't matter. If you've been trying options, type `/bbp reset` first (it wipes BetterBlizzPlates' settings), log in once, then import.
- The import replaces your aura whitelist (see above). Use the Aura Whitelist box to export yours first if you want to keep it.
- The threat % also shows when you are solo, since BetterBlizzPlates has no group-only option for it.

## Source files (`source/`)
- `profile.lua`: the settings and the whitelist, as a plain Lua table.
- `common.lua`: loads BetterBlizzPlates' own libraries (LibDeflate, LibSerialize) and `shared/ImportExport.lua` from a BetterBlizzPlates checkout, and reads its default settings for Mists and Forever.
- `build.lua`: writes `Warrior Profile.txt` by calling BetterBlizzPlates' own `BBP.ExportProfile`, the same code as the Export button.
- `verify.lua`: checks the string with BetterBlizzPlates' own code:
  - `BBP.OldImportProfile` (the code behind the Import button) accepts it, it is marked as a Mists export, and it round-trips through export and import unchanged;
  - every setting is a real BetterBlizzPlates setting on Mists, with the same type as its default, colours are `{r, g, b}` tables and sizes are inside the settings sliders' ranges;
  - Pummel is in BetterBlizzPlates' interrupt list and the bar texture is one it registers;
  - every whitelist entry uses BetterBlizzPlates' whitelist format;
  - WeakAuras registers the font;
  - a simulated import and `/reload` leaves every setting at the profile value;
  - the enemy name is lifted clear of Blizzard's health numbers, using the offsets in BetterBlizzPlates' name and debuff code, and the debuff row keeps its gap above the name;
  - BetterBlizzPlates' own enemy debuff filter (copied from `classics/modules/auras.lua` when the check runs) shows and glows the right debuffs and hides the rest.

```
cd source
BBP_SRC=/path/to/BetterBlizzPlates lua build.lua
BBP_SRC=/path/to/BetterBlizzPlates WA_TYPES=/path/to/WeakAuras/Types.lua lua verify.lua
```

## Version history
- **v1 (Nov 2 2026):** first release. Dark look, enemy class colours, Fira Sans Condensed Medium, role-aware threat colours and threat %, castbars with Pummel tracking, Execute indicator at 20%, and enemy debuff filtering with the Warrior whitelist and glows.

- **v2 (Nov 3 2026):** the enemy name no longer overlaps the health numbers. BetterBlizzPlates centres the name just above the bar, and with the Legacy nameplate style Blizzard's health numbers (`240 100%`) sit in the same spot. The name is now 16 px higher, on its own row (`fakeNameYPos` 16), and the debuff icons move up by the same 16 px (`nameplateAurasYPos` 16) to keep their gap above the name.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
