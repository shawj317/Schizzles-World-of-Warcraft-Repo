# Schizzle's Warrior Bartender4 Layout

A Bartender4 action bar layout and keybind set for Warriors in MoP Classic 5.5.x by Jon Shaw (Schizzle). It replaces the ElvUI action bars in the non-ElvUI kit: three centred bars at the bottom, two side blocks, Fira Sans Condensed Medium hotkeys in Warrior tan, and nothing near the [WeakAuras rotation](../WeakAuras/) or the [Details! windows](../Details!/).

> **Heads-up:** Bartender4 has no import box, so the layout is applied by the [Schizzle's Warrior Setup](../SchizzlesWarriorSetup/) helper addon. It is built for MoP Classic and written to carry over to WoW Forever (see [WoW Forever](#wow-forever)).

| File | What it is |
|---|---|
| [Profile.lua](Profile.lua) | the layout, in Bartender4's own profile keys |
| [Keybinds.lua](Keybinds.lua) | the keybind map |

## Install (step by step)
1. Turn **ElvUI off** (AddOns list on the character screen) and install Bartender4 and the [helper addon](../SchizzlesWarriorSetup/).
2. Log in and click **Yes** on the Schizzle's Warrior prompt, or type `/schizzle bars` and `/schizzle binds`.
3. Click **Reload** when asked.

The helper makes a new Bartender4 profile, **Schizzle's Warrior**, runs Bartender4's own **Blizzard** preset on it, then lays this layout over the top. Your old profile is kept (`/bt4` > Profiles).

## Layout
All positions are from the bottom centre of the screen, in UI units. Bars are at scale 0.9 with 3 px spacing.

| Bar | Where | Keys |
|---|---|---|
| Bar 1 (12 buttons) | bottom of the centre stack | 1 to = |
| Bar 2 (12) | middle of the stack | Shift-Q ... Alt-Mouse 4 |
| Bar 3 (12) | top of the stack, top edge 124 px up | Q E R F T G Y, mouse buttons |
| Bar 4 (6 x 2) | left of the stack | your own |
| Bar 5 (6 x 2) | right of the stack | your own |
| Bar 6 (6 x 2) | above bar 4 | your own |
| Stance bar | above bar 6, hotkeys hidden | |
| Extra action button | right of the stack, artwork hidden | |
| Micro menu | bottom right, fades out until you hover it | |
| XP bar | thin strip under bar 1 | |

- **Off:** bag bar (Baganator shows bags), pet bar, Blizzard art, reputation bar.
- **Empty buttons are hidden**, so a bar you don't fill takes no space.
- **Clear areas:** nothing sits in the WeakAuras area (170 px either side of the screen centre, from 220 px below to 120 px above it; the tray's bottom is about 168 px up from the bottom of the screen) or above the Details! stack (bottom right, 4 px in; see the [Details! README](../Details!/) for the two spots where bar 5 and the micro menu come close).
- **Hotkeys** in Fira Sans Condensed Medium 12, Warrior tan; stack counts 13, white; macro names hidden.
- **Out of range:** the whole button turns red.
- **Self-cast and focus-cast keys** follow Blizzard's settings (Esc > Interface > Combat), as in Bartender4's defaults.
- **Bars locked**, snapping on. Unlock with `/bt4` > **Lock** to move them.

## Keybinds
See the table in the [helper addon README](../SchizzlesWarriorSetup/#keybinds). Short version: bar 3 is Q, E, R, F, T, G, Y, Mouse 3, Mouse 4, Ctrl-Mouse 3, Ctrl-Mouse 4, Alt-Mouse 3; bar 2 is the same with Shift, then Ctrl-Q, Ctrl-E, Alt-Mouse 4; A and D strafe. They are saved account-wide, so every character gets them.

### Coming from ElvUI
- Your **spells stay put**: ElvUI and Bartender4 use the same action pages for bars 1 to 6.
- Bars 1, 3, 4, 5 and 6 used Blizzard's binding slots in ElvUI too, so those keys carry over. **ElvUI bar 2 had its own binding slots, which go dead without ElvUI**; `/schizzle binds` puts the Shift keys on Bartender4 bar 2.
- Change a key later with `/kb`: hover a button, press the key, then click **Okay**.

### Stances
- **MoP Classic:** bar 1 doesn't swap by stance for Warriors (Bartender4 and ElvUI agree). Nothing to do.
- **WoW Forever:** bar 1 swaps to the Battle, Defensive and Berserker stance pages (7, 8, 9), as ElvUI did there. They start empty: go into each stance once and drag your abilities onto bar 1. Turn swapping off in `/bt4` > Bar 1 > **State Configuration** if you'd rather not.

## WoW Forever
The keys, module names and bar numbers are the same in Bartender4's Forever code. The XP bar position is for MoP Classic's 1024-wide XP bar; if it looks off on Forever, move it with `/bt4` unlocked.

## Checks
In [SchizzlesWarriorSetup/source](../SchizzlesWarriorSetup/source/): `verify.lua` runs the helper's Bartender4 and keybind code and checks every key here is one Bartender4's code uses, and that the keybind map comes out exactly as above.

## Version history
- **v1 (Nov 2 2026):** first release.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
