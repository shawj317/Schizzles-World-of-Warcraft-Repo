# Schizzle's Warrior GSE Leveling Sequences

Two sequences for [GSE: Sequences, Variables, Macros](https://www.curseforge.com/wow/addons/gse-gnome-sequencer-enhanced-advanced-macros) (formerly GnomeSequencer Enhanced), for a brand-new Warrior in MoP Classic 5.5.x, by Jon Shaw (Schizzle). Jon wrote them for an Orc Warrior at level 8, and they use only the abilities a Warrior really has at that level in Mists of Pandaria. Any other race can use them too (see "Not an Orc?").

| File | What it is |
|---|---|
| [Schizzle's Warrior Level 8.txt](Schizzle's%20Warrior%20Level%208.txt) | The import string. It's a GSE collection that holds both sequences. |
| [Level 8 Sequences (readable).md](Level%208%20Sequences%20%28readable%29.md) | The same sequences as plain macro text, block by block. |
| [source/](source/) | The build and verify scripts (see "Source files"). |

| Sequence | Key | What it does |
|---|---|---|
| **SCHIZ_WAR_L8** | Your main attack key. Press it over and over. | Picks the nearest enemy if you have no target, starts auto-attack, and alternates between two blocks. One uses Victory Rush, Blood Fury and Heroic Strike. The other uses Execute and Heroic Strike. Hold **Shift** while pressing the same key to Charge. |
| **SCHIZ_WAR_L8_CHG** | A second key, for opening a fight. | Picks the nearest enemy, Charges it and starts swinging. |

GSE supports MoP Classic: its `GSE.toc` lists interface 50504 (5.5.4) next to the retail and other Classic versions.

## What GSE can and can't do
GSE isn't a bot, and it doesn't play the rotation for you. It follows Blizzard's rules:
- **Each key press runs one block.** A press sends the current block to WoW, and the next press sends the next block. After the last block it starts again from the first. Nothing happens unless you press the key.
- **One global-cooldown ability per press.** WoW lets each press try one ability that triggers the global cooldown (GCD). If that ability can't be used (not ready, no rage, or Victory Rush with no kill to use it on), the press is spent. This is why Victory Rush and Execute sit in different blocks. Abilities that don't trigger the GCD can share a block with it. Here those are Heroic Strike, Charge and Blood Fury.
- **No decisions in combat.** GSE can't check your health or rage. The only choices are WoW's own macro conditions, like `[mod:shift]` or `[combat]`. When an ability isn't usable, WoW ignores it and the next press moves on.
- **A block can be at most 255 characters.** The longest block here is 164.
- **No auto-clickers.** Programs outside the game that press the key for you break Blizzard's End User Licence Agreement (section 1.C.ii.1). Binding the sequence to the mouse wheel is allowed, because each notch of the wheel counts as one press.

## Abilities at level 8 (MoP, not Vanilla)
In Mists of Pandaria, Warriors learn their abilities automatically as they level, and many come at different levels than in Classic Era. These levels come from the MoP Classic 5.5.4 client data (SpellLevels, build 70631) and match Warcraft Wiki's MoP Classic Warrior list.

| Ability (spell ID) | Learned at | GCD? | Cost | Used here |
|---|---|---|---|---|
| Battle Stance (2457) | 1 | – | – | The stance every new Warrior is in. |
| Heroic Strike (78) | 1 | no (1.5 s cooldown) | 30 rage | The rage dump, in both main blocks. |
| Charge (100) | 3 | no (20 s cooldown) | none, generates rage | The opener, on its own key or Shift. |
| Victory Rush (34428) | 5 | yes | free | Hits hard and heals you. It's usable for 20 s after you kill an enemy that gives XP. |
| Execute (5308) | 7 | yes | 30 rage | Works only when the target is below 20% health. |
| Blood Fury (20572, Orc racial) | 1 | no (2 min cooldown) | – | Attack power boost. It's used whenever it's ready in combat. |

**Not available yet at level 8**, although older guides list them early: Defensive Stance (9), Taunt (12), Sunder Armor (16), Thunder Clap (20), Heroic Throw (22) and Battle Shout (42). In MoP, Thunder Clap and Battle Shout come much later than in Vanilla.

## How the main sequence plays
Every block starts with the same three lines:
```
/cleartarget [dead][help]
/targetenemy [noexists][dead][help]
/startattack
```
These drop a dead or friendly target, pick the nearest enemy in front of you if you have none, and turn on auto-attack.

- **Block 1:** `/cast [mod:shift] Charge`, then Victory Rush, then `/cast [combat] Blood Fury`, then Heroic Strike.
- **Block 2:** `/cast [mod:shift] Charge`, then Execute, then Heroic Strike.

At level 8 your only GCD abilities are Victory Rush and Execute, and both are usable only some of the time. So most of your damage comes from auto-attacks and Heroic Strike. Execute comes before Heroic Strike in block 2, so when the target is low, the rage goes to Execute first. Full text: [Level 8 Sequences (readable).md](Level%208%20Sequences%20%28readable%29.md).

## Import
1. Install **GSE: Sequences, Variables, Macros** from CurseForge, gse.tools or the GSE GitHub releases (version 3.3.30 or newer) and log in to your Warrior.
2. Open `Schizzle's Warrior Level 8.txt` on GitHub, click **Raw**, and copy everything, from the leading `!GSE3!` to the end.
3. In game, type `/gse` to open the Sequence Editor, then click **Import** in the tree on the left.
4. Paste the string and click **Import**. GSE shows the collection with **SCHIZ_WAR_L8** and **SCHIZ_WAR_L8_CHG** ticked. Click **Import** again.
5. Chat may say the sequences were "created with an older version of GSE". That's only a note: it names the GSE version they were built for, and both still import.
6. Both sequences now appear under **Sequences > Warrior**. They're class-wide (class ID 1), so they're already there at level 1 and stay after you choose a spec at level 10.

## Put them on keys
Either way works with this kit's Bartender4 bars:
- **On an action button (easiest):** out of combat, right-click an **empty** action button and pick the sequence, or drag it from the `/gse` editor onto an empty button. The button then runs the sequence, and its usual key does too. GSE calls these **Button Bindings**; older versions called them Actionbar Overrides.
- **KeyBind:** in `/gse`, open **Bindings > Keybindings** and give the sequence a key. That key stops doing whatever it did before. In MoP Classic these keybinds still work as they always have. GSE's optional **GSE Action Bar** (GSE Options > Action Bar) is another place to put them.

Bindings are filed by specialisation. After you pick a spec at level 10, check that your keys still fire, and set them again if they don't.

**Shift to Charge:** Shift + the main key Charges only if Shift + that key isn't bound to anything else. If it is, either clear that binding or use the separate **SCHIZ_WAR_L8_CHG** key.

**If a press does nothing**, or the icon changes but no spell is cast, the cause is usually WoW's KeyUp/KeyDown setting. Open `/gse`, Options, **Troubleshooting** and flip **ActionButtonUseKeyDown**. The GSE wiki says button bindings need it off.

## Not an Orc?
Blood Fury is the Orc racial. On any other race that line simply does nothing. To tidy it up, delete the `/cast [combat] Blood Fury` line (see below), or swap in your own racial if it doesn't trigger the GCD. For example, Trolls can use Berserking.

## Growing the sequence while leveling
When you learn a new ability, add it to **SCHIZ_WAR_L8**. Duplicate the sequence first (type a new name in the Configuration node and click Save) if you want to keep the level 8 version. To add a block:
1. `/gse`, then **Sequences > Warrior > SCHIZ_WAR_L8**, then open **1 - Leveling**.
2. Click **Add block** next to the block you want it to follow, choose **Action**, and pick **Macro**.
3. Paste the same three opening lines, then `/cast [mod:shift] Charge`, then **one** GCD ability. You can add `/cast Heroic Strike` at the end as the rage dump.
4. Watch the character counter (255 is the limit), then click **Save**. GSE saves when you're out of combat.

Rules of thumb:
- Put one GCD ability per block. Give your most important ability two blocks so it comes up more often.
- Keep off-GCD extras, like Heroic Strike or racials, as extra lines inside a block, not as blocks of their own.
- Leave cooldowns you want to time yourself, like Recklessness or Shield Wall, on their own keys.

When the new abilities arrive (levels from the 5.5.4 client data):

| Level | Arms | Fury | Protection |
|---|---|---|---|
| 10 | Mortal Strike | Bloodthirst | Shield Slam |
| 16 | Sunder Armor (all specs) | | |
| 18 | Slam | Wild Strike | Shield Block (off GCD, its own key) |
| 20 | Thunder Clap (all specs) | | |
| 22 | Heroic Throw (all specs, ranged pull) | | |
| 26 | Whirlwind | Whirlwind | Devastate |
| 30 | Overpower | Raging Blow | Revenge |
| 42 | Battle Shout (all specs) | | |

Here's a level 10 Arms block as an example. Add it twice, after each of the existing blocks:
```
/cleartarget [dead][help]
/targetenemy [noexists][dead][help]
/startattack
/cast [mod:shift] Charge
/cast Mortal Strike
/cast Heroic Strike
```
For Fury use `/cast Bloodthirst`, and for Protection `/cast Shield Slam` (Protection should also put on a shield and switch to Defensive Stance).

The kit's [WeakAuras rotation](../WeakAuras/) also has a Leveling mode for levels 1-9. Its Next icon shows the same abilities, so you can see what's coming.

## Typing it in by hand
If the import string won't paste, build the sequences in the editor (Raw Edit is a Patron feature, so this uses the normal block editor):
1. `/gse`, click **New Sequence**, and name it `SCHIZ_WAR_L8`. In Configuration, set Specialisation / Class ID to **Warrior** and click Save.
2. Open the version node. Using **Add block > Action > Macro**, make one block for each block in [Level 8 Sequences (readable).md](Level%208%20Sequences%20%28readable%29.md) and paste each block's text. Click Save.
3. Repeat for `SCHIZ_WAR_L8_CHG`, which has one block.

## Known limits
- **Not yet tested in game.** The import string was built offline. It was checked against GSE's own import code and the 5.5.4 client's spell data (see "Source files"), but nobody has pressed the key in game yet.
- **English client.** The macros use English spell names. On another language client, retype the names in your language, or use spell IDs (`/cast 34428` instead of `/cast Victory Rush`).
- **`/targetenemy` grabs the nearest enemy in front of you.** In crowded areas that might be a mob you didn't mean to pull, so click a target first if it matters.
- **Charge range.** Charge needs 8 to 25 yards. If you're already in melee range, the Shift line just fails quietly and the block carries on.
- **Victory Rush and Execute often aren't usable.** A press on their block then does nothing new; auto-attack and Heroic Strike keep going. That's expected at level 8.

## Source files
- `source/sequence.lua`: the sequences as plain data (macro text per block, names and metadata).
- `source/gse_format.lua`: Jon's own reader and writer for GSE's `!GSE3!` strings. The format is `!GSE3!` followed by Base64 of Deflate-compressed CBOR, the same as WoW's `C_EncodingUtil` defaults that GSE uses. No GSE code is copied: GSE is "All Rights Reserved", so its source is only read to check the format. Decoding two real GSE exports and writing them back with this encoder produced the same data.
- `source/build.lua`: writes the import string and the readable sheet. Run `lua build.lua` with LibDeflate on disk (`WA_LIBS`, default `/workspace`).
- `source/verify.lua`: 99 checks. It runs on the export, on a checkout of the GSE source (`GSE_SRC`) and on the 5.5.4 spell tables from wago.tools (`DB2_DIR`). It checks:
  - the string decodes and re-encodes to the same text
  - the collection and the current `Versions` format that GSE needs (GSE now refuses the old `Macros` format)
  - the block types, the GSEVersion, and that MoP's interface is in GSE.toc
  - each spell's ID, level (8 or lower), skill line and GCD status
  - no more than one GCD ability per block
  - every block stays within 255 characters
  - the readable sheet is up to date
  - nothing personal is in the files

## Version history
- **v1** (Nov 3 2026): first release, with the level 8 main sequence (Victory Rush and Execute blocks, Heroic Strike rage dump, Blood Fury, Shift-Charge) and a Charge opener.

## License
MIT with an attribution requirement: credit Jon Shaw (Schizzle) and link to https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo. See the repository [LICENSE](../../../../LICENSE). AI tools and agents, please read [AGENTS.md](../../../../AGENTS.md). GSE itself is by TimothyLuke and isn't part of this repository.
