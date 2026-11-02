# Schizzle's Warrior Plater Profiles

Three Plater nameplate profiles for Warriors in MoP Classic 5.5.x, one per spec, by Jon Shaw (Schizzle):

| File | In-game profile name | Threat colours | Spec debuffs |
|---|---|---|---|
| [Arms Profile.txt](Arms%20Profile.txt) | **Schizzle's Warrior Arms** | DPS | Colossus Smash, Mortal Wounds |
| [Fury Profile.txt](Fury%20Profile.txt) | **Schizzle's Warrior Fury** | DPS | Colossus Smash |
| [Protection Profile.txt](Protection%20Profile.txt) | **Schizzle's Warrior Protection** | Tank (Protection spec or Defensive Stance) | Demoralizing Shout, Taunt |

All three share the same look and include the same five mods, so you only paste three strings. A mod built into every profile switches Plater to the matching profile whenever your spec changes (see [Spec switching](#spec-switching)). Import all three, even if you only play one spec today, so you're covered after a respec.

The mods are also in [Mods/](Mods/) as separate strings, in case you want one of them in a different profile.

## Import
1. Type `/plater`, open **Profiles**, choose **Import Profile**, and paste the whole contents of `Arms Profile.txt`.
2. In the name box type **exactly** `Schizzle's Warrior Arms` and confirm. Plater switches to the new profile and reloads the UI.
3. Repeat for `Fury Profile.txt` (name it `Schizzle's Warrior Fury`) and `Protection Profile.txt` (name it `Schizzle's Warrior Protection`).
4. That's it. After the last reload the spec switcher moves you to the profile for the spec you're in. When it switches, Plater asks whether to reload; click **Yes**.

The names matter: the switcher looks for these three profile names. If you'd rather use other names, change them in **Modding → Schizzle's Warrior Spec Switcher → Options** (do this in each of the three profiles, since every profile has its own copy of the mod settings).

**Font:** the profiles use **Fira Sans Condensed Medium**, which ships with WeakAuras. If WeakAuras isn't installed, Plater falls back to its default font; everything else works.

## Spec switching
Plater doesn't have spec profiles. This was checked in the Plater source (current GitHub version, which is also the MoP Classic build, `Interface-Mists: 50504`):
- It has no LibDualSpec, and its Profiles tab only creates, copies, imports and exports AceDB profiles. Nothing switches profiles on a spec change.
- Profiles are chosen per character, as in any AceDB addon.

In MoP you have two talent groups (dual spec). Each group holds one of your three specs, and you can change a group's spec at any time outside combat. A per-talent-group switcher, the way LibDualSpec works in other addons, would only know "group 1" and "group 2". It would pick the wrong profile after a respec. So these profiles switch by your **actual spec** (Arms, Fury or Protection) instead, with a small mod.

**Schizzle's Warrior Spec Switcher** (in all three profiles):
- Checks your spec at login and loading screens, on a dual-spec swap (`ACTIVE_TALENT_GROUP_CHANGED`), on a respec (`PLAYER_SPECIALIZATION_CHANGED`) and on talent changes.
- Arms → *Schizzle's Warrior Arms*, Fury → *Schizzle's Warrior Fury*, Protection → *Schizzle's Warrior Protection*.
- Uses Plater's own `PlaterAPI:SetProfile`, the same call as picking the profile by hand. Plater then asks whether to reload; Yes is recommended.
- Never switches in combat. It waits until combat ends.
- If the profile for your spec doesn't exist, it prints one chat line and does nothing.
- Only runs on Warriors, and only while one of these profiles is active. Your other profiles and other characters are left alone.
- At most one switch every 5 seconds, so it can't loop.

Options: **Enabled**, **Switch Automatically** (turn it off to get a chat reminder instead of a switch), and the three profile names.

To stop switching, untick the mod in **Modding**. Again, this is per profile, so do it in all three.

## The look (all three profiles)
- Flat dark bars: a flat texture on a near-black background with a 1 px black border.
- Enemy bars are 120×14 out of combat and 136×18 in combat.
- Text is Fira Sans Condensed Medium with an outline. The name sits inside the left of the bar and health % inside the right, with no decimals, shown out of combat too. Level text is hidden.
- Cast bars are 120×12 (136×16 in combat), with the spell name on the left, the timer on the right, and the cast target's name. The icon and an interrupt shield are shown.
- **Cast colours:**

  | Cast type | Colour |
  |---|---|
  | Interruptible | gold (glows when Pummel is ready, bronze while it's on cooldown; see the Pummel Ready mod) |
  | Channel | cyan |
  | **Not interruptible** | grey, with shield |
  | Important | orange |
  | Interrupted | pink |
  | Finished | green |

- **Target:** white highlight and thin arrows. Non-targets are dimmed to 65%, in combat only. Focus gets a purple overlay.
- **Enemy players** are class coloured. NPC reaction colours are hostile red, neutral yellow and friendly green.
- **Markers:** elite, rare, quest, world boss and raid icons are on. Quest mobs are tinted orange; neutral quest mobs are amber.
- **Auras** sit above the bar at 24×18, with the border colour showing the aura type:
  - your debuffs, the unit's buffs, dispellable buffs and crowd control;
  - Enrage as the big **Buff Special** icon at the right of the bar (handy for Shattering Throw and Enraged Regeneration decisions, and for knowing when to soothe).
- **Warrior debuffs tracked by spell ID** (from any source, so a druid's or another warrior's Weakened Armor counts):
  - **All specs:** Deep Wounds, Weakened Armor (Sunder Armor / Devastate), Weakened Blows (Thunder Clap), Hamstring, Piercing Howl, Staggering Shout, Shockwave, Storm Bolt, Charge Stun, Intimidating Shout and Disarm.
  - **Plus, per spec:** see the table at the top.
  - Rend isn't tracked because it was removed from Warriors in Mists.
- **Threat colours** (bar only, with aggro glow and flash). Every profile has both sets; the Threat Mode mod picks one.

  | Mode | Red | Green | Others |
  |---|---|---|---|
  | **Tank** (Protection) | **lost aggro** | you're tanking | orange: losing it; yellow: someone is pulling it off a tank; **blue: another tank has it (off-tank)**; dark red: not in combat |
  | **DPS** (Arms / Fury) | the mob is on **you** | safe | orange: about to pull; purple: the mob isn't on a tank; solo: hostile red |

## The mods (built into every profile)
| Mod | What it does | Main options |
|---|---|---|
| **Schizzle's Warrior Spec Switcher** | Switches to the profile for your current spec. See [Spec switching](#spec-switching). | Enabled, Switch Automatically, Arms / Fury / Protection profile names |
| **Schizzle's Warrior Threat Mode** | Picks tank or DPS threat colours. **Protection profile:** tank colours in Protection spec or Defensive Stance. **Arms/Fury profiles:** DPS colours, even if you drop into Defensive Stance to survive (turn on *Defensive Stance = Tank* if you off-tank as DPS). Plates recolour right away when it flips. | Protection Spec = Tank, Defensive Stance = Tank, Group Role TANK = Tank (off), Force Tank Colours, Force DPS Colours, Non-Warriors: Leave Plater Alone (on), Print Mode Changes (off) |
| **Schizzle's Warrior Pummel Ready** | When a mob starts an **interruptible** cast and Pummel is ready and in range, the cast bar gets a pixel glow. While Pummel is on cooldown, interruptible casts turn bronze, which means someone else has to kick. If you've talented **Disrupting Shout**, it counts as ready while Pummel is down. The GCD is ignored, and the glow appears as soon as an interrupt comes off cooldown mid-cast. | Interrupt Spell ID (6552), Backup Interrupt Spell ID (102060, empty to disable), Require Range, Target/Focus Only, Ready Glow Colour, Glow Lines / Thickness, Tint While Interrupt On Cooldown, On-Cooldown Cast Colour, Flash Plate On Kickable Cast (off) |
| **Schizzle's Warrior Execute** | At **20% health or below** (Execute range) the health % turns red, and if you know Execute the plate gets a red glow and an **EXE** tag. This is on in all three profiles, since Execute is baseline for every Warrior spec in Mists. | Execute Health % (20), Health % Text Colour, Recolour Bar In Execute Range (off, since it would hide threat colours), Execute Bar Colour, Execute Glow, Only With Rage For Execute (off), Execute Rage Cost (30), Only In Combat, Glow Colour, EXE Tag |
| **Schizzle's Warrior Threat %** | Small threat % above the left end of the bar, in groups. DPS mode: shows at 70% or more, going yellow to red as you near pulling. Tank mode: shows on mobs you aren't securely tanking. | Only In Groups, DPS Warning %, Show In Tank Mode, Font Size, Safe / Danger colours |

Above the bar: threat % on the left and EXE in the centre, with auras just above that row.

## Tuning tips
- **Bar size:** `/plater` → Enemy NPC (or Enemy Player) → Health Bar Size / Cast Bar Size.
- **Dimming of non-targets:** General → Target → *Non Target Alpha* (0.65).
- **Threat colours:** the Threat / Aggro tab, with separate Tank and DPS colours.
- **Tracked debuffs:** Buff Settings → Tracking. Add or remove spell IDs there.
- **Making a change in all three profiles:** each profile is separate, so after changing one, use Profiles → Copy, or repeat the change in the other two.

## Caveats
- **Not tested in game yet.** The strings were built and checked offline:
  - every string decodes back to its source (Plater's AceSerializer + LibDeflate format) and round-trips;
  - every profile key exists in Plater's defaults with the right type;
  - every mod hook compiles and avoids the functions Plater's mod sandbox blocks;
  - the mods embedded in each profile match the stand-alone strings exactly;
  - 19 simulated scenarios passed against a mocked Plater/WoW sandbox, 9 of them for the spec switcher (login, dual-spec swap, respec, combat wait, missing profile, custom names, throttle).
- Spell IDs are MoP IDs checked against a spell name table, but not on the live 5.5 client. Plater ignores an ID it doesn't know without an error.
- Switching uses Plater's profile change, which asks to reload. If you click No, most settings apply right away, but a reload is safer.
- Plater sometimes recomputes tank status on events. The Threat Mode mod puts it back within 0.2 s, so you might see one brief flicker.
- Importing a profile reloads the UI. Your other Plater profiles aren't touched.

## Rebuilding
`source/` has the Lua 5.1 build and test scripts: `profile.lua` (settings), `mods/` (mod code), `build.lua`, `validate.lua`, `verify.lua` and `sim.lua`. They need a Plater checkout and LibDeflate. Point `PLATER_DIR` and `LIBDEFLATE` at them, then from `source/` run `lua validate.lua && lua build.lua .. && lua verify.lua ..`.

## Version history
- **v1 (Nov 1 2026):** first release. Three spec profiles with a built-in spec switcher, Warrior threat mode, Pummel Ready, Execute and Threat %.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE).
