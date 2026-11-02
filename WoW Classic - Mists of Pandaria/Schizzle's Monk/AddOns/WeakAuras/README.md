# Schizzle's Monk Rotation WeakAura

A WeakAuras rotation helper for Monks in MoP Classic 5.5.x.

**File:** [`All-in-One Rotation.txt`](All-in-One%20Rotation.txt) (19,902 chars, starts `!WA:2!`). Current version: **v5** (engine `VERSION = 5`).
**Built for:** WeakAuras 5.22.1, Mists build (interface 50504, internalVersion 90).
**Covers:** Brewmaster (tank or DPS) and Windwalker. Every spell is level-gated with `IsPlayerSpell`, so a spell only shows once your character knows it.
**Verified offline:** the custom code compiles in WeakAuras' own sandbox with 0 warnings, and the mock-API rotation simulator passes all 87 cases (levels 16 to 90, both specs, tank/DPS, AoE, procs, stances, range, interrupts, keybinds). WeakAuras' final import cleanup can only run in the game client.

## What it does

The **Schizzle's Monk Rotation WeakAura** group has 22 auras. All of them read one shared engine, the global `SchizzleMonk`, which lives in the SMR Next icon's On Init action. The engine works out the next spell 10 times a second and rescans your keybinds every 2 seconds.

- **SMR Next** (56 px): the spell to press now. It shows the keybind (bottom right), the Tiger Palm reason tag (top left), the mode label above it, and a glow for high-priority picks.
- **SMR Next+1** (34 px, under Next): the next different spell in the list.
- **SMR Defensive 1-3** (36 px, left of Next): defensive cooldowns.
- **SMR Cooldown 1-3** (36 px, right of Next): Touch of Death and offensive cooldowns.
- **SMR Chi** pips: one small bar per Chi point. There's a 4-pip row and a 5-pip row (Ascension), and only the row matching your max Chi is shown.
- **SMR Resources** text: `EB n` (Elusive Brew stacks) for Brewmaster, `TEB n` (Tigereye Brew stacks) for Windwalker.
- **SMR Interrupt** (44 px, red border and glow, "KICK" label) plus the **SMR Interrupt Cast** bar (cast name and %).
- **SMR Shuffle** bar: Brewmaster, once Brewmaster Training is known.
- **SMR Stagger** bar: green for Light, yellow for Moderate, red for Heavy, with the level name and % of max health.

**When it shows:** in combat, or when you have a hostile target, as Brewmaster or Windwalker. It loads for the Monk class only.

## Import

1. Type `/wa` and click **Import**.
2. Open `All-in-One Rotation.txt` on GitHub, click the **Copy raw file** button, then paste the whole string into the Import box and click **Import**.
3. Accept the "Schizzle's Monk Rotation WeakAura" group.
4. Optional: move the whole HUD by dragging the group (default spot: screen centre, 190 px down).
5. Options live on **Schizzle's Monk Rotation WeakAura → SMR Next → Custom Options** (see the Options section below).

If you're replacing an older version, delete the old group first. Builds before the rename were called "Peanut Monk"; the renamed group has a new ID, so the import will not replace it on its own, and running both at once doubles every icon. The engine only loads once per session at a given version, so `/reload` after importing.

## Layout (offsets from the group centre)

| Element | Size | Position |
|---|---|---|
| Interrupt icon + "KICK" | 44 px | y +126 |
| Interrupt cast bar | 120x10 | y +98 |
| Resources text (EB/TEB) | 12 pt | y +76 |
| Chi pips | 18x8 each, 4 px gap, centred | y +58 |
| Mode label (`TANK` / `DPS` / `WW`, plus ` AoE n`) | 14 pt gold, thick outline | centred between the Next icon top and the Chi row |
| Next | 56 px | 0, 0 |
| Defensives 1-3 | 36 px | x -52 / -92 / -132 |
| Cooldowns 1-3 | 36 px | x +52 / +92 / +132 |
| Next+1 | 34 px | y -50 |
| Shuffle bar | 160x12 | y -80 |
| Stagger bar | 160x10 | y -96 |

The glow layer sits directly above the icon background, so keybind, tag and mode text always draw on top of it.

## Tank / DPS auto-switch and lock (Brewmaster)

Set this with **Brewmaster mode** (`bmMode`):

- **Auto (default):** TANK only when all three are true:
  - you're in **Stance of the Sturdy Ox**;
  - you're in a group;
  - your group role is TANK, or you're currently tanking your target (threat check).

  Otherwise it's DPS. Being in Fierce Tiger always means DPS.
- **Tank (lock):** always uses the tank priority. If you're in Fierce Tiger, a quiet **Sturdy Ox** reminder appears in the defensive slot. It glows when you're tanking or under 60% health.
- **DPS (lock):** always uses the DPS priority.

The mode label above the Next icon shows the result: `TANK`, `DPS` or `WW`, plus ` AoE n` when the AoE threshold is met.

## Stance detection

- **Primary check:** the engine loops over every stance button (`GetShapeshiftFormInfo`) and matches the active one by spell ID and by name. It doesn't assume a fixed button index.
- **Fallback:** if no stance button is active, it looks for the Sturdy Ox / Fierce Tiger aura, first by ID, then by name.
- **Ox-only spells:** Keg Smash, Breath of Fire, Dizzying Haze, Clash, Elusive Brew, Guard and Purifying Brew are only suggested while you're in Sturdy Ox.
- **Fierce Tiger Chi:** in Fierce Tiger, Jab and Expel Harm count as generating 2 Chi, which changes the Chi-room checks.

## GCD spin and desaturation

- **Cooldown swipe:** the Next and Next+1 icons show a cooldown swipe. If the spell's own cooldown runs longer than the GCD, the swipe follows that cooldown. Otherwise it follows the global cooldown (spell 61304).
- **Grey means "not yet":** the icon is desaturated while the spell is waiting on the GCD, its own cooldown or Energy/Chi, and when it's a "waiting for…" entry. It's full colour only when you can press it right now.
- **Side icons:** they show only their own cooldown swipe (no GCD) and don't grey out for missing resources.

## Out-of-range desaturation

- **What it looks like:** out-of-range icons are always desaturated. With **Red tint when out of range** on (the default), they're also tinted red, so you can tell "out of range" apart from "waiting on GCD or Energy".
- **Never out of range:** self-cast and no-range spells such as Fortifying Brew, Expel Harm, stances, brews, Guard, Spinning Crane Kick and Rushing Jade Wind.
- **8 yd check:** cones and point-blank AoE, such as Breath of Fire, Leg Sweep, War Stomp and Arcane Torrent.
- **Everything else:** uses the game's spell range check. Melee spells (Jab, Tiger Palm, Blackout Kick, Keg Smash, Rising Sun Kick, Fists of Fury, Spear Hand Strike, Touch of Death, Quaking Palm) fall back to a 5 yd check when the game gives no answer.
- **No hostile target:** nothing is marked out of range.

## Interrupts (with fallbacks)

- **What it watches:** casts and channels on your **target**, plus your **focus** if "Also watch focus casts" is on. It only reacts to casts that can be interrupted.
- **Order tried:** **Spear Hand Strike** first. If it's on cooldown or out of range and "Include stuns/CC as fallback" is on, it tries these in order:
  1. Paralysis
  2. Leg Sweep (5 yd)
  3. Charging Ox Wave (30 yd)
  4. Quaking Palm
  5. Arcane Torrent (8 yd)
  6. War Stomp (8 yd)

  The first one you know that's off cooldown and in range wins.
- **Display:** by default it uses the dedicated red **KICK** icon above the Chi row:
  - the swipe shows the enemy's cast time, and the cast bar below shows the cast name and %;
  - the icon greys out and tints red when you're out of range.

  With "Interrupt in main icon" on, the interrupt takes over the Next icon instead.
- **Debug:** if every option is blocked, the reasons are stored in `SchizzleMonk.intWhy` (check with `/dump SchizzleMonk.intWhy`).

### Keybind detection

- **What's scanned:**
  - the Blizzard bars: main bar, Bottom Left/Right, Right, Left, and MultiBar 5-7;
  - **Bartender4**, **Dominos** and **ElvUI** buttons;
  - a raw fallback that maps action slots to binding names for slots no visible button covers. This handles stance and bonus-bar paging.
- **Which key wins:** a button you can see beats a hidden one, and a spell placed directly on a button beats a macro.
- **How a spell is matched:** by spell ID, then its override or base ID, then its **name**. The name match catches rank and variant IDs.
- **Short key names:**

  | In-game key | Shown as |
  |---|---|
  | Shift / Ctrl / Alt / Meta | `S` / `C` / `A` / `M` (for example `CM4`, `A3`) |
  | Mouse wheel up / down | `WU` / `WD` |
  | Middle mouse | `M3` |
  | Mouse button N | `MN` |
  | Numpad | `N` |
  | Space | `Spc` |

## Tiger Palm rules

Every Tiger Palm suggestion carries a small tag in the icon's top-left corner:

- **refresh:** Tiger Power has less than the **Tiger Power refresh window** left (default **4 s**, option `tpWindow`, 1-10 s). This applies to both specs. It needs the Palm to be free or 1+ Chi.
- **filler (Brewmaster, level 34+):** with Brewmaster Training, Tiger Palm costs no Chi and grants Power Guard. It's suggested low in the list when Keg Smash and Jab aren't worth pressing.
- **filler (Brewmaster, before 34, added in v5):** before Brewmaster Training, Tiger Palm costs 1 Chi. It's suggested only at exactly **1 Chi**, when nothing better is usable. Blackout Kick (2+ Chi), Keg Smash, Jab and the refresh rule all rank above it, so it never takes Chi away from Blackout Kick.
- **proc (Windwalker):** Combo Breaker: Tiger Palm is up, so it's free. The icon glows.
- **Windwalker filler:** none. Windwalker uses Tiger Palm only to refresh or on a proc.

## Priority lists

"Ready" means the spell is off cooldown, or within 0.25 s of it. Each entry also needs the spell to be known (and to be in Ox, for Ox-only spells).

### Brewmaster

1. *Tank, Shuffle known, Shuffle < 1 s, Chi ≥ 2:* **Blackout Kick**
2. *Health < 35%, Energy ≥ 40:* **Expel Harm** (glow)
3. *Keg Smash ready, Energy ≥ 40, at least 2 Chi of room:* **Keg Smash** (glow)
4. *AoE, Chi ≥ 2, Breath of Fire DoT < 1 s* (when tanking: only if Shuffle > 6 s or Chi ≥ 4): **Breath of Fire**
5. *Tank, health < 90%, Energy ≥ 40, Chi room:* **Expel Harm**
6. *Tiger Power under the refresh window:* **Tiger Palm** `refresh`
7. *Chi ≥ 2:* **Blackout Kick**. In DPS mode (or before Shuffle), it's the Chi spender. When tanking, only if Shuffle < 6 s or Chi is near cap.
8. *AoE:* **Rushing Jade Wind** (Energy ≥ 40), then **Spinning Crane Kick** (Energy ≥ 40, Chi below max)
9. **Chi Wave / Zen Sphere / Chi Burst** (whichever talent you have) when ready
10. *Fierce Tiger, health < 90%:* **Expel Harm** (2 Chi)
11. *Energy ≥ 40, Chi room, and (Energy ≥ 70 or Keg Smash more than 2 s away):* **Jab**
12. *Brewmaster Training:* **Tiger Palm** `filler` (free, Power Guard)
13. *Before 34, exactly 1 Chi:* **Tiger Palm** `filler`
14. Otherwise: **Keg Smash** (waiting) or **Jab** (waiting for Energy), shown greyed out

### Windwalker

1. *Not in Fierce Tiger:* **Stance of the Fierce Tiger** (glow)
2. *Rising Sun Kick debuff < 3 s, Chi ≥ 2:* **Rising Sun Kick** (glow)
3. *Tiger Power under the refresh window:* **Tiger Palm** `refresh`
4. *AoE, Energy ≥ 40:* **Rushing Jade Wind**
5. *Chi ≥ 3, Energy at least 40 below max, Tiger Power > 4 s, Rising Sun Kick debuff > 4 s:* **Fists of Fury** (glow)
6. *Chi ≥ 2:* **Rising Sun Kick**
7. *Combo Breaker: Blackout Kick:* **Blackout Kick** (glow)
8. *Combo Breaker: Tiger Palm:* **Tiger Palm** `proc` (glow)
9. **Chi Wave / Zen Sphere / Chi Burst** when ready and not near the Energy cap
10. *AoE, Energy ≥ 40:* **Spinning Crane Kick**
11. *Health < 90%, Chi room for 2:* **Expel Harm**
12. *Energy ≥ 40, Chi below max:* **Jab**
13. *Chi ≥ 2:* **Blackout Kick**
14. Otherwise: **Jab** (waiting for Energy)

**AoE** means the number of hostile, in-combat nameplates within 8 yd (your target counts) is at or above the **AoE threshold** (default 3).

### Side icons

**Left (defensives, up to 3).**
- **Brewmaster:**
  - **Sturdy Ox** reminder, only in Tank lock while you're out of Ox.
  - **Purifying Brew** on Heavy Stagger, or when tanking on Moderate Stagger with Chi ≥ 3.
  - **Elusive Brew** when tanking with stacks ≥ the "Elusive Brew stacks to pop" option (default 10) and the brew not active.
  - **Guard** when tanking with Chi ≥ 2, Power Guard up (or before Training) and health < 95%.
- **Windwalker:** **Touch of Karma** under 50% health.
- **Both specs:**
  - **Fortifying Brew** under 40% (tank) or 35%.
  - **Dampen Harm** or **Diffuse Magic** under 50% when tanking, or under 35% otherwise.

**Right (offensive, up to 3).**
- **Touch of Death** when usable with Chi ≥ 3.
- In combat:
  - **Invoke Xuen** on a boss or elite, or in AoE;
  - Windwalker only: **Tigereye Brew** at the stack option (default 10), and **Energizing Brew** under 40% Energy;
  - **Chi Brew** with charges available and 2+ Chi of room.

## Options (SMR Next → Custom Options)

| Option | Key | Default | Notes |
|---|---|---|---|
| AoE threshold (enemies) | `aoe` | 3 | 2-10 |
| Brewmaster mode | `bmMode` | Auto | Auto / Tank / DPS |
| Show defensive pops (left) | `showDef` | on | |
| Show offensive cooldowns (right) | `showCDs` | on | Touch of Death still shows |
| Show keybinds | `showKeys` | on | |
| Red tint when out of range | `tintOOR` | on | Out-of-range icons are always desaturated |
| Show interrupts | `showInt` | on | |
| Include stuns/CC as fallback | `intCC` | on | |
| Interrupt in main icon | `intMain` | off | |
| Also watch focus casts | `intFocus` | off | |
| Tiger Power refresh window (s) | `tpWindow` | 4 | 1-10, step 0.5 |
| Elusive Brew stacks to pop | `ebStacks` | 10 | 1-15 |
| Tigereye Brew stacks to pop | `tebStacks` | 10 | 1-10 |

**Slash commands:** the aura adds none of its own. Use `/wa` for options. For debugging, use WoW's built-in `/dump`:
- `/dump SchizzleMonk.R.why`: why the Next spell was picked, Tiger Power time left vs the refresh window, the mode and detected stance (and how it was detected), and the reasons for the next few entries.
- `/dump SchizzleMonk.intWhy`: why no interrupt was offered.
- `/dump SchizzleMonk.keysrc["Tiger Palm"]`: which button or binding each keybind came from.

## Version history

- **v1 (Oct 31 2026):**
  - The first build: 10 auras. Next, Next+1, 3 defensive and 3 cooldown icons, a resources text and the Shuffle bar.
  - Level-gated Brewmaster (Auto/Tank/DPS) and Windwalker priorities.
  - Keybind scan, and options for AoE, mode, side icons, keybinds and brew stacks.
- **v2:**
  - **Keybind fix** (Tiger Palm showed the wrong key):
    - visible buttons win over hidden ones, and direct spells over macros;
    - spells are matched by ID, override/base ID and name;
    - a raw slot-to-binding fallback was added for stance/bonus-bar paging.
  - Desaturate while waiting on the GCD or Energy, and the GCD cooldown spin.
  - New Chi pips (4 or 5 rows) and the Stagger bar.
  - Mode label moved above the icon in larger text, and the glow layer moved under all text.
- **v3:**
  - **Stance detection** loops over every stance button (ID and name) and falls back to the aura.
  - Ox-only spells gated to Sturdy Ox, and 2 Chi Jab/Expel Harm in Fierce Tiger.
  - Auto mode requires actually being in Ox, and Tank lock shows the Ox reminder on the side.
  - **Interrupt** icon and cast bar with CC/racial fallbacks, plus the `showInt` / `intCC` / `intMain` / `intFocus` options.
  - Mode label centred between the Next icon and the Chi row.
- **v4:**
  - **Out-of-range** desaturation and red tint (`tintOOR`), also on the interrupt icon.
  - **Tiger Palm audit:** each Palm is tagged refresh/filler/proc, and the refresh triggers at under 4 s of Tiger Power (`tpWindow`).
  - `/dump SchizzleMonk.R.why` debug info.
- **v5 (current):** **Tiger Palm as a pre-34 Brewmaster filler.** It's suggested at 1 Chi when nothing better is usable, ranked below Blackout Kick, Keg Smash, Jab and the refresh rule. The `filler` tag is unchanged.
- **v5 move (Nov 1 2026):** same aura, moved to `Schizzle's Monk/AddOns/WeakAuras/` to match the Warrior layout. The import string was renamed from `schizzles-monk-rotation-weakaura.txt` to `All-in-One Rotation.txt`; its contents are unchanged.
- **v5 rename (Nov 1 2026):** same logic as v5, renamed from "Peanut Monk" to "Schizzle's Monk Rotation WeakAura". Aura IDs went from `PM …` to `SMR …` and the engine global from `PeanutMonk` to `SchizzleMonk`, so this imports as a new group. Delete the old group.

## Caveats

- Nameplates must be enabled for the AoE count. Without them, it counts only your target.
- Range checks use WeakAuras' range helper and the game's spell range checks. If neither gives an answer, the spell counts as in range.
- Keybinds from addons other than Blizzard, Bartender4, Dominos and ElvUI fall back to the raw binding of the action slot.

## License

MIT, with an attribution requirement. See [LICENSE](LICENSE). Original repo: https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo/tree/main/WoW%20Classic%20-%20Mists%20of%20Pandaria/Schizzle's%20Monk/AddOns/WeakAuras
