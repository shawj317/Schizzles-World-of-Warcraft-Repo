# Schizzle's Monk Plater Profile

A Plater nameplate profile (in game: *Schizzle's Monk Plater Profile*) and five mods for Brewmaster and Windwalker Monks in MoP Classic 5.5.x, by Jon Shaw (Schizzle). One profile covers both specs. The Stance-Aware Threat mod switches between tank and DPS colours by stance.

The profile's look works for any class. The threat, interrupt and Touch of Death mods are tuned for Monks. You need Plater on Mists of Pandaria Classic. The mods are separate imports, so each one can be turned off on its own.

| File | What it is |
|---|---|
| [Brewmaster and Windwalker Profile.txt](Brewmaster%20and%20Windwalker%20Profile.txt) | The full profile (look, colours, auras, threat colours) for both specs |
| [Mods/01 Stance-Aware Threat.txt](Mods/01%20Stance-Aware%20Threat.txt) | Schizzle's Stance-Aware Threat |
| [Mods/02 Target and Focus Highlight.txt](Mods/02%20Target%20and%20Focus%20Highlight.txt) | Schizzle's Target & Focus Highlight |
| [Mods/03 Interrupt Ready Glow.txt](Mods/03%20Interrupt%20Ready%20Glow.txt) | Schizzle's Interrupt Ready Glow |
| [Mods/04 Execute and Touch of Death.txt](Mods/04%20Execute%20and%20Touch%20of%20Death.txt) | Schizzle's Execute & Touch of Death |
| [Mods/05 Threat Percent.txt](Mods/05%20Threat%20Percent.txt) | Schizzle's Threat % |

## Import
1. **Profile:** type `/plater`. When the Plater window opens, open **Profiles**, choose **Import Profile**, paste the whole contents of `Brewmaster and Windwalker Profile.txt`, give it a name (for example *Schizzle's Monk Plater Profile*) and confirm. Plater switches to it and reloads the UI.
2. **Mods:** in `/plater`, open the **Modding** tab, click **Import**, paste one mod string from the `Mods/` folder, and click **Okay**. Repeat for each file. Each mod is enabled on import; you can turn it on or off with the checkbox in the mod list.
3. Mod settings are in **Modding → (mod) → Options**. Type `/reload` after you turn the Stance-Aware Threat mod off.

**Replacing the older build:** the profile and mods used to ship under an earlier name. The renamed mods import as new mods, so delete the five old mods in the Modding tab, or both sets will run at once.

Import the profile first. A profile import resets the UI, and the mods are kept separate so you can add or remove each one on its own.

## The look (profile)
- Flat dark bars: a flat texture on a near-black background, with a 1 px black border.
- Enemy bars are 120×14 out of combat and 136×18 in combat.
- Text is in the Expressway font with an outline. The name sits inside the left of the bar and health % inside the right. Health % shows out of combat too, with no decimals. Level text is hidden.
- Cast bars are 120×12 (136×16 in combat). The spell name sits inside the left, the timer on the right, and the cast target name is shown. The icon and an interrupt shield are shown.
- **Cast colours:**

  | Cast type | Colour |
  |---|---|
  | Interruptible | gold |
  | Channel | cyan |
  | **Not interruptible** | grey (with shield) |
  | Important | orange |
  | Interrupted | pink |
  | Finished | green |

- **Target:** white highlight, thin arrow indicators, and non-targets dimmed to 65% (only in combat). Focus gets a purple overlay.
- **Class colours on enemy players.** NPC reaction colours: hostile red, neutral yellow, friendly green.
- **Markers:** elite, rare, quest, world boss and raid icons are on. Quest mobs are tinted orange, and neutral quest mobs amber.
- **Auras (24×18, above the bar):**
  - Your own debuffs, the unit's buffs, dispellable buffs, and crowd control.
  - Border colour shows the type.
  - Enrage shows as the big **Buff Special** icon at the right of the bar.
  - Your Monk debuffs are tracked by ID: Dizzying Haze, Breath of Fire, Keg Smash, Rising Sun Kick, Disable, Paralysis, Leg Sweep and the other monk CC/debuffs.
- **Threat colours** (bar only, with aggro glow and flash):

  | Mode | Red | Green | Others |
  |---|---|---|---|
  | **Tank** (Ox) | lost aggro | you are tanking | orange: losing it; yellow: someone pulling from a tank; blue: another tank has it; dark red: not in combat |
  | **DPS** (Tiger / Serpent) | the mob is on **you** | safe | orange: about to pull; purple: the mob is not on a tank; solo: hostile red |

## The mods
| Mod | What it does | Main options |
|---|---|---|
| **Schizzle's Stance-Aware Threat** | Plater's own logic treats a Brewmaster as "tank" all the time. This mod switches threat colours by **stance** instead: Sturdy Ox gives tank colours, any other stance gives DPS colours. Plates recolour right away when you swap. | Sturdy Ox = Tank (on); Group Role TANK = Tank (off); Force Tank; Force DPS; Non-Monks: Leave Plater Alone (on); Print Mode Changes (off) |
| **Schizzle's Target & Focus Highlight** | White border on your target and purple border on your focus, plus a small **FOCUS** tag above the bar. Optional animated glow on your target. | Target Border Colour, Target Pixel Glow (off), Glow Colour, Highlight Focus, Focus Border Colour, Show FOCUS Tag |
| **Schizzle's Interrupt Ready Glow** | When a mob starts an **interruptible** cast and Spear Hand Strike is ready and in range, the cast bar gets a pixel glow. While your kick is on cooldown, interruptible casts turn brown, which means someone else has to kick. The glow appears the moment the kick comes off cooldown during the cast. The GCD is ignored. | Interrupt Spell ID (116705; the description lists other classes' kicks for alts), Require Range, Target/Focus Only, Glow Colour / Lines / Thickness, Tint While On Cooldown, On-Cooldown Colour, Flash Plate |
| **Schizzle's Execute & Touch of Death** | Health % text turns red at 20% or below. Mobs **Touch of Death can kill** (NPC health no higher than your max health, players at 10% or below) get a magenta glow and a **ToD** tag. By default this only shows while ToD is off cooldown and the mob is in combat. | Low Health %, Low Text Colour, Recolour Bar When Low (off, because it would hide threat colours), Bar Colour, ToD Indicator, Only When Ready, ToD Player %, Only In Combat, ToD Colour, ToD Tag |
| **Schizzle's Threat %** | A small threat % above the bar's left edge. In DPS mode it shows at 70% or more, and goes yellow to red as you near pulling. In tank mode it shows on mobs you are *not* securely tanking. Hidden when solo. | Only In Groups, DPS Warning %, Show In Tank Mode, Font Size, Safe / Danger colours |

Tag row above the bar: threat % on the left, ToD in the centre, FOCUS on the right. Auras sit just above that row.

## Tuning tips
- **Bar size:** `/plater` → Enemy NPC (or Enemy Player) → Health Bar Size / Cast Bar Size.
- **Dimming of non-targets:** General → Target → *Non Target Alpha* (0.65).
- **Threat colours:** Threat / Aggro tab, with separate Tank and DPS colours.
- **Tracked debuffs:** Buff Settings → Tracking. Add or remove spell IDs there.

## Caveats
- **Not tested in game** yet. The strings were built and checked offline:
  - every string decodes back to the source;
  - every hook compiles;
  - each mod passed 16 simulated scenarios against a mocked Plater sandbox;
  - every profile key exists in Plater's own defaults.
- A few spell IDs (mostly secondary monk CC) and the Touch of Death rules are from memory for MoP. Plater ignores an invalid ID without an error.
- Plater sometimes recomputes tank status on events. The Stance mod puts it back within 0.2 s, so you might see a single brief flicker.
- Importing the profile reloads the UI. Your other profiles are not touched.

## Version history
- **v1 (Nov 2026):** first release. Flat dark profile, stance-aware threat colours, and five mods: Stance-Aware Threat, Target & Focus Highlight, Interrupt Ready Glow, Execute & Touch of Death, Threat %.
- **v1 move (Nov 1 2026):** same content, moved to `Schizzle's Monk/AddOns/Plater/` to match the Warrior layout. Files renamed: `schizzles-plater-profile.txt` → `Brewmaster and Windwalker Profile.txt`, and `schizzles-plater-mods/schizzles-plater-mod-0N-….txt` → `Mods/0N ….txt`. The import strings are unchanged.
- **v1 rename (Nov 1 2026):** same content, renamed to "Schizzle's Monk Plater Profile" / "Schizzle's …". Author field is now "Schizzle (Jon)".

## License

MIT, with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle). Original repo: https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo/tree/main/WoW%20Classic%20-%20Mists%20of%20Pandaria/Schizzle's%20Monk/AddOns/Plater
