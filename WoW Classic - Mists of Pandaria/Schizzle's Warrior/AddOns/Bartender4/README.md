# Schizzle's Warrior Bartender4 Layout

A Bartender4 action bar layout and keybind set for Warriors in MoP Classic 5.5.x by Jon Shaw (Schizzle). It replaces the ElvUI action bars in the non-ElvUI kit. The layout is Jon's own in-game setup: three centred bars at the bottom, a few extra bars around them, Fira Sans Condensed Medium hotkeys in Warrior tan, and bars 4 and 5 hidden until you mouse over them.

> **Heads-up:** Bartender4 has no import box, so the layout is applied by the [Schizzle's Warrior Setup](../SchizzlesWarriorSetup/) helper addon. It is built for MoP Classic and written to carry over to WoW Forever (see [WoW Forever](#wow-forever)).

| File | What it is |
|---|---|
| [Profile.lua](Profile.lua) | the layout, in Bartender4's own profile keys |
| [Keybinds.lua](Keybinds.lua) | the keybind map |

## Install (step by step)
1. Turn **ElvUI off** (AddOns list on the character screen) and install Bartender4 and the [helper addon](../SchizzlesWarriorSetup/).
2. Log in and click **Yes** on the Schizzle's Warrior prompt, or type `/schizzle bars` and `/schizzle binds`.
3. Click **Reload** when asked.

The helper switches Bartender4 to a profile called **Schizzle's Warrior**, resets it to Bartender4's own defaults, then writes this layout on top. Your old profile is kept (`/bt4` > Profiles).

**Already ran the helper before v3?** Type `/schizzle bars`, then `/reload`, on each of those characters to get this layout.

## Layout
Positions are Bartender4's own (the bar's top-left corner from a point on the screen), at scale 0.9 with 3 px spacing. Every action bar uses Fira Sans Condensed Medium, Warrior-tan hotkeys, hidden macro names, and shows empty buttons, apart from bar 6.

| Bar | Where | Shows | Keys |
|---|---|---|---|
| Bar 1 (12 buttons) | bottom of the centre stack, 40 px up | always | 1 to = |
| Bar 2 (12) | middle of the stack | in combat only | Shift-Q ... Alt-Mouse 4 |
| Bar 3 (12) | top of the stack, about 117 px up | in combat only | Q E R F T G Y, mouse buttons |
| Bar 4 (8 buttons, 4 x 2) | above the stack, just left of centre, about 190 px up | **on mouseover** | your own |
| Bar 5 (12, 2 x 6) | right edge of the screen, around the middle | **on mouseover** | your own |
| Bar 6 (12, 6 x 2) | right of centre, a little above the middle of the screen | always | your own |
| Stance bar | left of centre above the stack, hotkeys shown | always | |
| Extra action button | right of the stack, artwork hidden | when there is one | |
| Micro menu | bottom right, 300 px in | on mouseover | |

- **Hotkey text:** 10 on bars 1 to 3, 12 on bars 4 to 6. Stack counts are 12 on bar 1 and 13 elsewhere.
- **Mouseover bars:** bars 4 and 5 are invisible until the cursor is over them, then fade back out (Bartender4's **Fade Out** option at 0% alpha, the same as the micro menu). The buttons still work while faded, including their keybinds.
- **Off:** bag bar (Baganator shows bags), pet bar, Blizzard art, and Bartender4's status tracking (XP and reputation) bar.
- **Out of range:** the whole button turns red.
- **Self-cast and focus-cast keys** follow Blizzard's settings (Esc > Interface > Combat), as in Bartender4's defaults. The Blizzard vehicle UI is used in vehicles.
- **Bars locked**, snapping on. Unlock with `/bt4` > **Lock** to move them.
- **Neighbours:** bar 5 sits on the right edge, well above the [Details!](../Details!/) windows. The micro menu sits under them. On a UI narrower than about 1435 px (such as 1365 × 768 at UI scale 1), the left Details! window covers the right end of bars 1–3 by up to about 35 px, and the extra action button lands under it. See the Details! README for the numbers.

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
The keys, module names and bar numbers are the same in Bartender4's Forever code. Bartender4's status tracking bar is off here, so the Blizzard XP bar is left to the game.

## Checks
In [SchizzlesWarriorSetup/source](../SchizzlesWarriorSetup/source/): `verify.lua` runs the helper's Bartender4 and keybind code. For Bartender4 it uses the real AceDB-3.0 with Bartender4's default layout and checks that stale values from an older run are cleared, Bartender4's defaults stay behind every bar, bars 4 and 5 fade out until moused over, the other bars don't, and the profile saved at logout is exactly `Profile.lua`. It also checks that every key here is one Bartender4's code uses and that the keybind map comes out exactly as above.

## Version history
- **v1 (Nov 2 2026):** first release.
- **v2 (Nov 2 2026):** the layout is now Jon's own in-game setup (bar positions, sizes, fonts, bars 2 and 3 in combat only, empty buttons shown), with bars 4 and 5 changed to show on mouseover. The XP bar setting is gone: that module doesn't exist on MoP Classic 5.5, so it never applied. Needs helper v3: type `/schizzle bars`, then `/reload`.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
