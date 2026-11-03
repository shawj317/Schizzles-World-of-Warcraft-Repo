# Schizzle's Monk Rotation

An all-in-one WeakAuras rotation helper for Monks in MoP Classic 5.5.x: **Brewmaster (tank or DPS) and Windwalker in one import**.

> **Heads-up:** this aura is built for Mists of Pandaria Classic (5.5.x). It will be revised for WoW Forever after that launches.

**File:** [`All-in-One Rotation.txt`](All-in-One%20Rotation.txt) (21,596 chars, starts `!WA:2!`). Current version: **v5.5** (engine `VERSION = 6`).
**Built for:** WeakAuras 5.22.1, Mists build (interface 50504, internalVersion 90). Font: **Fira Sans Condensed Medium** (it ships with WeakAuras).
**Switches automatically:** the aura reads your specialization and stance and swaps the priority list, side icons, bars and cooldown tray when you change spec. Brewmaster picks tank or DPS priority on its own (see [Brewmaster](#brewmaster)). Mistweaver is not covered.
**Talents handled:** every spell is level-gated with `IsPlayerSpell`, so a spell only shows once your character knows it, and only the talent you actually took shows up (Chi Wave, Zen Sphere or Chi Burst; Dampen Harm or Diffuse Magic; Rushing Jade Wind; Chi Brew; Invoke Xuen and the other tray talents).
**Verified offline:** the export string decodes the same way WeakAuras' importer does. All custom code compiles inside WeakAuras' own aura sandbox with 0 warnings, and a mock-API rotation simulator passes 131 checks: levels 16 to 90, both specs, tank/DPS, AoE, procs, stances, range, interrupts, keybinds and the cooldown tray, plus static checks of the group name, position, fonts, tray layout and uniformity with the Warrior aura. **It has not been tested in the game client yet.** See "Known limits" below.

## Install (step by step)

1. Install **WeakAuras** for MoP Classic (CurseForge app or Wago app) and log in on your Monk.
2. Open `All-in-One Rotation.txt` on GitHub, then click the **Copy raw file** button (two overlapping squares, top right of the file). This copies the whole string.
3. In game, type `/wa` and click **Import** (top left of the WeakAuras window).
4. Paste with **Ctrl+V** (Cmd+V on Mac), then click **Import**.
5. WeakAuras shows a summary of the "Schizzle's Monk Rotation v5.5" group. Click **Import** again to accept it.
6. Type `/reload`.
7. Target a training dummy. The HUD appears under the middle of your screen (the group defaults to x 0, y -40: its centre sits on the screen's centre, 40 px down).
8. To move it, open `/wa`, click the group name and drag, or set the X/Y offset on the group's **Display** tab.
9. Options live on **Schizzle's Monk Rotation v5.5 → SMR Next → Custom Options** (see "Options" below).

**Group name and updates:** the in-game group name carries the version ("Schizzle's Monk Rotation v5.5" now), so it changes with every release. The child auras keep fixed names ("SMR Next", "SMR Stagger" and so on). WeakAuras matches an import to an installed group by its internal ID (uid), not by its name, and that ID has not changed since the rename from "Peanut Monk" (the group was called "Schizzle's Monk Rotation WeakAura" at first). So importing a new version shows WeakAuras' **Update** dialog for the existing group. Leave **Aura Names** ticked in that dialog (it is ticked by default) so the group picks up the new name; untick it to keep the old name. Settings in Custom Options carry over unless you also tick Custom Configuration. Only if the import shows up as a second group (for example after choosing "Import as Copy") should you delete the older one.

**Position on update:** a fresh import puts the group at x 0, y -40 (group CENTER on the screen's CENTER). When you update an existing group, WeakAuras leaves its position alone unless you tick **Size & Position** in the Update dialog (it is unticked by default). That category covers the group's own x/y offsets, anchor points, anchor frame, strata, size and scale. Tick it to move the group to 0, -40; leave it unticked to keep where you dragged it. The child auras' layout inside the group falls under **Group Arrangement** (ticked by default).

**Text sizes on update:** WeakAuras sorts changes by the top-level field that changed. Icon and bar texts (keybind, tag, mode, KICK and bar labels) live inside each aura's sub-regions, so a change to their size, font or outline rides in **Display** (ticked by default) and a plain **Update** applies it. Only a text aura's own `fontSize` (the SMR Resources text) counts as a size field, and on a child aura WeakAuras files size fields under **Group Arrangement** (also ticked by default). **Size & Position** only matters for the group itself: tick it only if you want the group moved back to 0, -40, because it also resets the group's position.

**Older builds:** builds before the rename were called "Peanut Monk". The renamed group has a new ID, so the import will not replace it on its own, and running both at once doubles every icon. Delete the "Peanut Monk" group first. The engine only loads once per session at a given version, so `/reload` after importing.

## What's on screen

All 30 auras read one shared engine, the global `SchizzleMonk`, which lives in the **SMR Next** icon's On Init action. The engine works out the rotation 10 times a second and rescans your keybinds every 2 seconds.

| Element | Size | Position | What it shows |
|---|---|---|---|
| **SMR Interrupt** + "KICK" | 44 px | y +126 | Spear Hand Strike (or a fallback) when the target is casting something interruptible (red glow), with the cast-time swipe |
| **SMR Interrupt Cast** | 120x10 | y +98 | Name and % of the cast you should kick |
| **SMR Resources** | 12 pt | y +76 | `EB n` (Elusive Brew stacks) for Brewmaster, `TEB n` (Tigereye Brew stacks) for Windwalker |
| **SMR Chi 1/4-4/4**, **1/5-5/5** | 18x8 each, 4 px gap | y +58, centred | One pip per Chi point. Only the row matching your max Chi (4, or 5 with Ascension) shows |
| Mode label | 14 pt gold | above Next | `TANK`, `DPS` or `WW`, plus `AoE n`. Centred between the Next icon top and the Chi row |
| **SMR Next** | 56 px | 0, 0 | The ability to press now, with its keybind, the Tiger Palm reason tag (top left), and a glow for high-priority picks. A GCD swipe runs over it |
| **SMR Defensive 1-3** | 36 px | x -52 / -92 / -132 | Ox stance reminder (Tank lock) and defensives |
| **SMR Cooldown 1-3** | 36 px | x +52 / +92 / +132 | Touch of Death and offensive cooldowns |
| **SMR Next+1** | 34 px | y -50 | The next different ability in the list, with the same GCD swipe |
| **SMR Shuffle** | 160x12 | y -80 | Brewmaster only, once Brewmaster Training is known. Shuffle uptime |
| **SMR Stagger** | 160x10 | y -96 | Stagger level and % of max health: green for Light, yellow for Moderate, red for Heavy |
| **SMR Tray 1-8** | 32 px | y -122, x +134 to -118 (36 px apart) | Cooldown tray, bottom right: racials and big cooldowns that aren't in the rotation, shown only when known and off cooldown. Fills from the right edge (x +150) toward the left. See [Cooldown tray](#cooldown-tray) |

The glow layer sits directly above the icon background, so keybind, tag and mode text always draw on top of it. Bars have the same 1 px black border as the Warrior aura's bars.

**When it shows:** in combat, or when you have a hostile target, as Brewmaster or Windwalker. Every aura loads for the Monk class only, with no spec or level condition. The engine decides what each aura shows: the Shuffle bar appears only for Brewmaster, and each element waits until its spell is learned.

**Colours on the icons:** desaturated (grey) means you're waiting on the GCD, a cooldown, Energy or Chi. Grey plus red tint means you're out of range.
- **Cooldown swipe:** the Next and Next+1 icons show a cooldown swipe. If the spell's own cooldown runs longer than the GCD, the swipe follows that cooldown. Otherwise it follows the global cooldown (spell 61304).
- **Grey means "not yet":** the icon is desaturated while the spell is waiting on the GCD, its own cooldown or Energy/Chi, and when it's a "waiting for…" entry. It's full colour only when you can press it right now.
- **Side icons:** they show only their own cooldown swipe (no GCD) and don't grey out for missing resources.
- **Out of range:** out-of-range icons are always desaturated. With **Red tint when out of range** on (the default), they're also tinted red, so you can tell "out of range" apart from "waiting on GCD or Energy".
- **Never out of range:** self-cast and no-range spells such as Fortifying Brew, Expel Harm, stances, brews, Guard, Spinning Crane Kick and Rushing Jade Wind.
- **8 yd check:** cones and point-blank AoE, such as Breath of Fire, Leg Sweep, War Stomp and Arcane Torrent.
- **Everything else:** uses the game's spell range check. Melee spells (Jab, Tiger Palm, Blackout Kick, Keg Smash, Rising Sun Kick, Fists of Fury, Spear Hand Strike, Touch of Death, Quaking Palm) fall back to a 5 yd check when the game gives no answer.
- **No hostile target:** nothing is marked out of range.

**Keybinds:**
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

## Per spec

"Ready" means the spell is off cooldown, or within 0.25 s of it. Each entry also needs the spell to be known (and to be in Ox, for Ox-only spells).

### Brewmaster

**Tank / DPS auto-switch and lock.** Set this with **Brewmaster mode** (`bmMode`):

- **Auto (default):** TANK only when all three are true:
  - you're in **Stance of the Sturdy Ox**;
  - you're in a group;
  - your group role is TANK, or you're currently tanking your target (threat check).

  Otherwise it's DPS. Being in Fierce Tiger always means DPS.
- **Tank (lock):** always uses the tank priority. If you're in Fierce Tiger, a quiet **Sturdy Ox** reminder appears in the defensive slot. It glows when you're tanking or under 60% health.
- **DPS (lock):** always uses the DPS priority.

The mode label above the Next icon shows the result: `TANK`, `DPS` or `WW`, plus ` AoE n` when the AoE threshold is met.

**Stance detection:**
- **Primary check:** the engine loops over every stance button (`GetShapeshiftFormInfo`) and matches the active one by spell ID and by name. It doesn't assume a fixed button index.
- **Fallback:** if no stance button is active, it looks for the Sturdy Ox / Fierce Tiger aura, first by ID, then by name.
- **Ox-only spells:** Keg Smash, Breath of Fire, Dizzying Haze, Clash, Elusive Brew, Guard and Purifying Brew are only suggested while you're in Sturdy Ox.
- **Fierce Tiger Chi:** in Fierce Tiger, Jab and Expel Harm count as generating 2 Chi, which changes the Chi-room checks.

**Priority:**

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

### All specs

**AoE** means the number of hostile, in-combat nameplates within 8 yd (your target counts) is at or above the **AoE threshold** (default 3).

**Tiger Palm tags.** Every Tiger Palm suggestion carries a small tag in the icon's top-left corner:

- **refresh:** Tiger Power has less than the **Tiger Power refresh window** left (default **4 s**, option `tpWindow`, 1-10 s). This applies to both specs. It needs the Palm to be free or 1+ Chi.
- **filler (Brewmaster, level 34+):** with Brewmaster Training, Tiger Palm costs no Chi and grants Power Guard. It's suggested low in the list when Keg Smash and Jab aren't worth pressing.
- **filler (Brewmaster, before 34, added in v5):** before Brewmaster Training, Tiger Palm costs 1 Chi. It's suggested only at exactly **1 Chi**, when nothing better is usable. Blackout Kick (2+ Chi), Keg Smash, Jab and the refresh rule all rank above it, so it never takes Chi away from Blackout Kick.
- **proc (Windwalker):** Combo Breaker: Tiger Palm is up, so it's free. The icon glows.
- **Windwalker filler:** none. Windwalker uses Tiger Palm only to refresh or on a proc.

**Interrupts:**
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

**Side icons.**

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

## Cooldown tray

A row of small icons (32 px, about 57% of the Next icon) under the HUD at y -122, below the Stagger bar. They show racials and big cooldowns that the rotation doesn't call for, so you can see at a glance what's ready.

- **Ready only:** an icon shows only when the spell is known (`IsPlayerSpell`) and off cooldown (the GCD doesn't count). A spell on cooldown or not learned is simply not there, so nothing shows greyed out.
- **Packs from the right:** ready spells fill slot 1 at the right edge first and grow leftward, up to 8. No gaps, no overlap.
- **No duplicates:** a spell that the Next, Next+1, Interrupt, Defensive or Cooldown icons already show is left out of the tray for that moment. For example, Invoke Xuen moves to the Cooldown icons on a boss and leaves the tray, and Fortifying Brew moves to the Defensive icons at low health.
- **Spec-aware:** the engine picks the list from your current spec. All tray auras load for the Monk class only, like the rest of the HUD, and they show at the same times (in combat, or with a hostile target).
- **Order:** your racial first, then the spec list in the order below.

| Spec | Tray spells (in order) |
|---|---|
| Brewmaster | Fortifying Brew, Dampen Harm, Diffuse Magic, Zen Meditation, Avert Harm, Invoke Xuen, Nimble Brew, Leg Sweep, Ring of Peace, Charging Ox Wave, Tiger's Lust |
| Windwalker | Touch of Karma, Fortifying Brew, Energizing Brew, Invoke Xuen, Dampen Harm, Diffuse Magic, Zen Meditation, Nimble Brew, Leg Sweep, Ring of Peace, Charging Ox Wave, Tiger's Lust |

Talents show only if you took them. Left out on purpose: Touch of Death (needs a low-health target, so it lives on the Cooldown icons), Tigereye Brew and Elusive Brew (they're ready almost all the time but only worth pressing at the stack counts the Cooldown / Defensive icons already watch), Guard, Purifying Brew and Chi Brew (rotation side pops).

Talent spells show only if you took the talent. Left out on purpose: Touch of Death (needs a low-health target, so it lives on the Cooldown icons), Tigereye Brew and Elusive Brew (they're ready almost all the time but only worth pressing at the stack counts the Cooldown / Defensive icons already watch), Guard, Purifying Brew and Chi Brew (rotation side pops).

| Race | Racial |
|---|---|
| Orc | Blood Fury |
| Troll | Berserking |
| Human | Every Man for Himself (Will to Survive in the MoP Classic client) |
| Dwarf | Stoneform |
| Undead | Will of the Forsaken, Cannibalize |
| Tauren | War Stomp |
| Blood Elf | Arcane Torrent |
| Draenei | Gift of the Naaru |
| Gnome | Escape Artist |
| Night Elf | Shadowmeld |
| Worgen | Darkflight |
| Goblin | Rocket Barrage, Rocket Jump |
| Pandaren | Quaking Palm |

Monks can be Human, Dwarf, Night Elf, Gnome, Draenei, Orc, Troll, Undead, Tauren, Blood Elf or Pandaren. The other races' racials are listed so the shared list stays the same as the Warrior aura's.

Turn it off with **Show cooldown tray** in the options.

## Options (SMR Next → Custom Options)

| Option | Default | What it does |
|---|---|---|
| AoE threshold (enemies) | 3 | Nearby enemies (nameplates, ~8-10 yd) that switch to AoE priority (2-10) |
| Brewmaster mode | Auto | Auto = Tank when grouped, in Sturdy Ox and (role TANK or tanking the target). Tank / DPS force it |
| Tiger Power refresh window (s) | 4 | Tiger Palm is suggested to refresh Tiger Power under this much time left (1-10, step 0.5) |
| Elusive Brew stacks to pop | 10 | Brewmaster tanking: Elusive Brew shows on the left at this many stacks (1-15) |
| Tigereye Brew stacks to pop | 10 | Windwalker: Tigereye Brew shows on the right at this many stacks (1-10) |
| Show defensives / stance (left) / offensive cooldowns (right) / keybinds | on | Turn parts of the HUD off. Touch of Death still shows with cooldowns off |
| Red tint when out of range | on | Adds a red tint to the grey out-of-range look |
| Show cooldown tray | on | The ready-only racial / cooldown row at the bottom right |
| Show interrupts / Include stuns/CC / Interrupt in main icon / Also watch focus | on / on / off / off | Interrupt behaviour |

**Debugging:** the aura adds no slash commands of its own; use WoW's built-in `/dump`:
- `/dump SchizzleMonk.R.why`: why the Next spell was picked, Tiger Power time left vs the refresh window, the mode and detected stance (and how it was detected), and the reasons for the next few entries.
- `/dump SchizzleMonk.intWhy`: why no interrupt was offered.
- `/dump SchizzleMonk.keysrc["Tiger Palm"]`: which button or binding each keybind came from.

## Spell IDs

The IDs below are the ones the engine uses. Every name was checked against Wowhead's MoP Classic tooltips.

- **Brewmaster:**
  - Keg Smash 121253, Breath of Fire 115181 (DoT 123725), Dizzying Haze 115180, Clash 122057.
  - Elusive Brew 115308 (stacks 128939), Purifying Brew 119582, Guard 115295, Brewmaster Training 117967, Power Guard 118636, Shuffle 115307, Desperate Measures 126060.
  - Stagger: Light 124275, Moderate 124274, Heavy 124273.
- **Windwalker:**
  - Rising Sun Kick 107428 (debuff 130320), Fists of Fury 113656, Energizing Brew 115288, Touch of Karma 122470.
  - Tigereye Brew 116740 (stacks 125195), Combo Breaker: Blackout Kick 116768, Combo Breaker: Tiger Palm 118864.
- **Shared:**
  - Jab 100780, Tiger Palm 100787, Blackout Kick 100784, Expel Harm 115072, Spinning Crane Kick 101546, Touch of Death 115080, Fortifying Brew 115203, Tiger Power 125359.
  - Spear Hand Strike 116705, Paralysis 115078, Leg Sweep 119381, Charging Ox Wave 119392.
  - Stances: Sturdy Ox 115069, Fierce Tiger 103985.
  - Global cooldown 61304 (for the GCD swipe).
- **Talents:** Chi Wave 115098, Zen Sphere 124081, Chi Burst 123986, Chi Brew 115399, Rushing Jade Wind 116847, Dampen Harm 122278, Diffuse Magic 122783, Invoke Xuen, the White Tiger 123904, Ring of Peace 116844, Tiger's Lust 116841.
- **Cooldown tray extras:** Zen Meditation 115176, Avert Harm 115213, Nimble Brew 137562.
- **Racials** (every rank the client uses): Blood Fury 20572 / 33697 / 33702, Berserking 26297, Every Man for Himself 59752, Stoneform 20594, Will of the Forsaken 7744, Cannibalize 20577, War Stomp 20549, Arcane Torrent 69179 / 129597 / 28730 / 25046 / 50613 / 80483, Gift of the Naaru 28880 / 121093 / 59542-59548, Escape Artist 20589, Shadowmeld 58984, Darkflight 68992, Rocket Barrage 69041, Rocket Jump 69070, Quaking Palm 107079.

## Known limits

- **Not tested in game yet.** Everything was checked offline against a mocked WoW API. Report anything that looks wrong with `/dump SchizzleMonk.R.why`.
- **Range:** the enemy count uses nameplates, so turn on enemy nameplates for the AoE switch to work. Without them, it counts only your target.
- **Range checks** use WeakAuras' range helper and the game's spell range checks. If neither gives an answer, the spell counts as in range.
- **Keybinds** from addons other than Blizzard, Bartender4, Dominos and ElvUI fall back to the raw binding of the action slot.
- **Sources:** no source list was kept for this aura's priorities (the Warrior README has one), so treat the thresholds as this aura's own rules.

## Source files (`source/`)

The import string is the source of truth for this aura; there is no full build script. These scripts edit, check and read it:

- `release.lua`: the release edit. `lua release.lua 5.5` renames the group to "Schizzle's Monk Rotation v5.5", ends the description with "v5.5.", re-points the child parent links and sets every font to Fira Sans Condensed Medium. It re-encodes, checks the round trip, refuses to write if anything else changed, then writes `../All-in-One Rotation.txt`.
- `uniform.lua`: the v5.4 edit that aligned the shared elements with the Warrior aura (tray keybind size, tag and border, bar borders, load conditions, option order and labels, description). It re-encodes, checks the round trip, refuses to touch triggers, actions, conditions, sizes or positions, and refuses to run twice. Kept for the record.
- `groupstyle.lua`: the v5.5 edit that set Group Scale 0.8 and Group Alpha 0.8 on the top-level group, like the Warrior aura. It changes only those two fields, re-encodes and checks the round trip. Kept for the record.
- `tray.lua`: the v5.2 edit that added the cooldown tray (engine code, option, eight `SMR Tray` icons). It is kept for the record and refuses to run on an export that already has the tray.
- `sim.lua`: the offline test. It decodes the export like WeakAuras does, compiles every custom function in WeakAuras' sandbox and runs 131 checks, including field-by-field uniformity checks against the Warrior export (`WA_WARRIOR`, default: the same path with "Schizzle's Monk" swapped for "Schizzle's Warrior"; skipped if that file is missing). It needs a WeakAuras2 checkout: copy it into that checkout's `tests/` folder and run it there, with `WA_EXPORT` pointing at the import string (and `WA_LIBS` at the folder holding LibSerialize and LibDeflate).
- `extract.lua`: writes the engine (SMR Next → On Init) and every trigger function to `source/extracted/` for reading. That folder is git-ignored.

All scripts need LibSerialize and LibDeflate on disk (`WA_LIBS`, default `/workspace`). No SavedVariables or personal data are included.

## Version history

- **v5.5** (Nov 3, 2026): the whole group now draws at **Group Scale 0.8** and **Group Alpha 0.8** (80% size and opacity), matching the Warrior aura's v1.6. No rotation, size or position changes inside the group (engine `VERSION = 6`). 131 simulator checks. **Updating:** import and click **Update**. Alpha applies with the default ticks; tick **Size & Position** as well to get the 0.8 scale (that also moves the group back to 0, -40). Then `/reload`.
- **v5.4** (Nov 2, 2026): **uniformity pass** with the Warrior aura, no rotation changes (engine `VERSION = 6`). Cooldown tray keybind text is now 12 pt (was 10), like the Warrior tray, and the tray icons lose an unused tag text and use the Warrior tray's border exactly. The Shuffle and Stagger bars get the Warrior bars' 1 px black border. A leftover, inactive spec load filter from v1 was removed, so the group and every child load on the Monk class only, like the Warrior. Custom Options now follow the Warrior's order (class settings first, then the Show… toggles, then interrupts), "Show defensive pops (left)" is now "Show defensives / stance (left)", and the tray option's tooltip uses the Warrior's wording. Your option values carry over (they are stored by key). The description follows the Warrior's form. The README now follows the Warrior README's layout, with a Spell IDs section. The simulator adds uniformity checks against the Warrior export (131 checks). The group is renamed to "Schizzle's Monk Rotation v5.4" (same uid; every child keeps its name and uid). **Updating:** every change rides in categories that are ticked by default (Display, Load Conditions, Author Options, Meta Data, Aura Names), so a plain **Update** applies it. Don't tick **Size & Position** unless you want the group moved back to 0, -40 (see "Text sizes on update" above).
- **v5.3** (Nov 2, 2026): every text now uses **Fira Sans Condensed Medium**, the same font as the Warrior aura (it was Friz Quadrata TT on all but the tray). That is 27 font fields: the keybind, tag, mode and KICK texts on the icons, the bar labels, and the Resources text. Sizes and outlines are unchanged. No rotation changes (engine `VERSION = 6`). The group is renamed to "Schizzle's Monk Rotation v5.3" (same uid; every child keeps its name and uid). **Updating:** the font change rides in the **Display** category, which is ticked by default, so a plain **Update** applies it. The offline scripts now live in `source/`.
- **v5.2** (Nov 2, 2026): new **cooldown tray**, 8 small icons (32 px, auras `SMR Tray 1-8`) at the bottom right (y -122, growing leftward from x +150). It shows your racial and the spec's big cooldowns that aren't in the rotation, only while they are known and off cooldown, and never a spell another icon already shows. New "Show cooldown tray" option. Engine `VERSION = 6`. The group is renamed to "Schizzle's Monk Rotation v5.2" (same uid, and every existing child keeps its name and uid). **Updating:** WeakAuras offers **Update**. Leave **Add Missing Auras** ticked (default) to get the eight tray auras. Tick **Size & Position** and **Group Arrangement** if your group or icons were moved and you want the default layout back.
- **v5.1** (Nov 2, 2026): the group's default position is now x 0, y -40 (was 0, -190), anchored CENTER to the screen's CENTER. The child auras keep their positions relative to the group. The group is renamed to "Schizzle's Monk Rotation v5.1" (same uid, so it updates in place), and the description ends with "v5.1.". No rotation changes (engine `VERSION = 5`). On Update, tick **Size & Position** to move the group.
- **v5 name** (Nov 2, 2026): same logic as v5. The in-game group is now called "Schizzle's Monk Rotation v5", so the name shows the version, and the description ends with "v5.". The group uid (`SchizzleMonkGroup`) and every child name and uid are unchanged, so re-importing updates the existing group in place. The child auras keep fixed names so they stay stable across versions.
- **v5 rename** (Nov 1, 2026): same logic as v5, renamed from "Peanut Monk" to "Schizzle's Monk Rotation WeakAura". Aura IDs went from `PM …` to `SMR …` and the engine global from `PeanutMonk` to `SchizzleMonk`, so this imports as a new group. Delete the old group.
- **v5 move** (Nov 1, 2026): same aura, moved to `Schizzle's Monk/AddOns/WeakAuras/` to match the Warrior layout. The import string was renamed from `schizzles-monk-rotation-weakaura.txt` to `All-in-One Rotation.txt`; its contents are unchanged.
- **v5:** **Tiger Palm as a pre-34 Brewmaster filler.** It's suggested at 1 Chi when nothing better is usable, ranked below Blackout Kick, Keg Smash, Jab and the refresh rule. The `filler` tag is unchanged.
- **v4:** **out-of-range** desaturation and red tint (`tintOOR`), also on the interrupt icon. **Tiger Palm audit:** each Palm is tagged refresh/filler/proc, and the refresh triggers at under 4 s of Tiger Power (`tpWindow`). `/dump SchizzleMonk.R.why` debug info.
- **v3:** **stance detection** loops over every stance button (ID and name) and falls back to the aura. Ox-only spells gated to Sturdy Ox, and 2 Chi Jab/Expel Harm in Fierce Tiger. Auto mode requires actually being in Ox, and Tank lock shows the Ox reminder on the side. **Interrupt** icon and cast bar with CC/racial fallbacks, plus the `showInt` / `intCC` / `intMain` / `intFocus` options. Mode label centred between the Next icon and the Chi row.
- **v2:** **keybind fix** (Tiger Palm showed the wrong key): visible buttons win over hidden ones, and direct spells over macros; spells are matched by ID, override/base ID and name; a raw slot-to-binding fallback was added for stance/bonus-bar paging. Desaturate while waiting on the GCD or Energy, and the GCD cooldown spin. New Chi pips (4 or 5 rows) and the Stagger bar. Mode label moved above the icon in larger text, and the glow layer moved under all text.
- **v1** (Oct 31, 2026): first release, 10 auras: Next, Next+1, 3 defensive and 3 cooldown icons, a resources text and the Shuffle bar. Level-gated Brewmaster (Auto/Tank/DPS) and Windwalker priorities. Keybind scan, and options for AoE, mode, side icons, keybinds and brew stacks.

## License

MIT with an attribution requirement. See [LICENSE](LICENSE). AI tools and agents, please read [AGENTS.md](AGENTS.md). Original repo: https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo/tree/main/WoW%20Classic%20-%20Mists%20of%20Pandaria/Schizzle's%20Monk/AddOns/WeakAuras
