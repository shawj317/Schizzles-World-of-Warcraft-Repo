# Schizzle's Warrior Details! Profiles

Three Details! damage meter profiles for Warriors in MoP Classic 5.5.x, one per spec, by Jon Shaw (Schizzle), plus a small Auto Run Code snippet that switches between them when the spec changes.

| File | In-game profile name | Window 1 | Window 2 |
|---|---|---|---|
| [Arms Profile.txt](Arms%20Profile.txt) | **Schizzle's Warrior Arms** | Damage Done | Damage Taken |
| [Fury Profile.txt](Fury%20Profile.txt) | **Schizzle's Warrior Fury** | Damage Done | Damage Taken |
| [Protection Profile.txt](Protection%20Profile.txt) | **Schizzle's Warrior Protection** | Damage Done | Damage Taken |
| [Spec Switch Code.lua](Spec%20Switch%20Code.lua) | – | switches between the three profiles by spec | |

The Arms and Fury strings are identical: the layout and displays are the same, and Details! takes the profile's name from what's typed at import. They are shipped as two files so each spec has its own profile to tweak.

The look matches [Schizzle's Monk Details! Profile](../../../Schizzle's%20Monk/AddOns/Details!/) (v2.2) and the Warrior [Plater profiles](../Plater/).

## What you get (all three profiles)
- **Two windows, both 250 × 141**, side by side in the bottom-right corner. Window 2 sits in the corner, 4 px from the right edge of the screen, and window 1 sits directly to its left at the same height, with no gap. They're snapped together. Their bottom edge is **38 px up**, right on top of the [XP & Rep Tray](../WeakAuras/#xp--rep-tray-separate-import) (a separate WeakAuras import: three 500 px bars, 34 px tall in total, 4 px from the bottom edge). Including the 20 px title bars, the pair covers 500 × 161 px, and with the tray under it the whole corner block is 500 × 195 px, the same as before the tray.
- **Locked:** both windows start locked, so they can't be dragged or resized by accident, and dragging the title bar doesn't stretch them either. To move or resize one, hover it and click **Unlock** in its bottom-right corner. Click **Lock** again when you're done.
- **Dark flat look:** Minimalistic skin base with "Details Flat" bars at height 18 in class colours and a thin 1 px black border around the bar area. The window body uses Blizzard's **Out of Control** background at **25 % opacity**, so it's mostly see-through. The title bar carries the **Details! Slash** texture (20 px, darkened), and its buttons **auto-hide** until the mouse is over the window.
- **Bar icons:** the **Specialization Alpha** spec icons (Details!' soft-edged set), plus the **arena role icon** next to names in arenas.
- **Text:** Fira Sans Condensed Medium (WeakAuras registers it), bar text size 9 and title size 11. Player names use the **Slug** outline (a smooth outline the 5.5 client can render); the numbers on the right keep no outline. The right side of each bar shows **total, per second and percent**, with the percent in muted grey.
- **Tooltips and menus:** the same font, tooltips at size 11 on a dark background.
- **Window 1: Damage Done** in all three profiles.
- **Window 2: Damage Taken** in all three profiles. Jon asked for a tank mitigation view, and Details! has no built-in display by that name (checked in its source for MoP Classic). Damage Taken is the closest one it ships: it lists who took the most damage, and its tooltips break each player's hits down by spell, with dodges, parries, blocks and absorbs once tank avoidance is recorded.
- **Fast, live numbers:** the windows refresh every **0.05 s** (Display → Update Interval, the lowest Details! allows, was 0.2) and **Fast Updates** is on (Bars: General), so the per-second numbers tick smoothly between refreshes.
- **Combat log settings:** **Clear On Logoff** (the Overall segment resets when you log out), **Advanced Damage Taken** (Combat Log → Damage Options: on tanks, damage that was absorbed is taken out of their damage taken, the way Details! already treats Monk stagger; it works together with tank avoidance), **Record Tank Avoidance** (Combat Log → Parser Options: hits, blocks and absorbs on tanks as well as dodges and parries) and **Auto Start Combatlog** (Combat Log: Details! turns on the game's `/combatlog` file writing in dungeons and raids, and off again outside them). Since v1.6 all three profiles set all of these.

### Settings the profile switch doesn't carry
Two of these are not per-profile settings in Details!, so they don't follow the profile around:
- **Record Tank Avoidance** is **account-wide**. The import sets it once for every character on the account; switching profiles never changes it.
- **Auto Start Combatlog** is **per character**. The import turns it on only for the character that does the import. On every other character, open `/details options` → **Combat Log** and tick **Auto Start Combatlog** once.

### Performance
A 0.05 s update interval with Fast Updates is the heaviest refresh Details! offers: the windows redraw four times as often as before (0.2 s), and Fast Updates animates the per-second numbers between those redraws. On most PCs this is fine, but in big raid fights it costs noticeably more CPU than the default. If frame rate drops in combat, set **Display → Update Interval** back to 0.2–0.3 or untick **Bars: General → Fast Updates** first. Auto Start Combatlog also writes a combat log file (`Logs/WoWCombatLog*.txt`) in every dungeon and raid, which grows quickly and is worth clearing out now and then.
- **A real mitigation view:** the optional **Tank Mitigation** custom display from the [Monk Details! folder](../../../Schizzle's%20Monk/AddOns/Details!/) works for Protection Warriors too (it shows block amounts and dodge + parry rate). A profile can't open on a custom display by itself, because its slot number depends on each player's list, so pick it once from window 2's sword icon → **Custom** → **Tank Mitigation** (or bookmark it).

## Import
1. Type `/details options` and open **Profiles**.
2. Click **Import Profile** and paste the whole contents of `Arms Profile.txt`. When Details! asks for the profile name, type **exactly** `Schizzle's Warrior Arms`. Leave **Import Auto Run Scripts** unticked (the profiles don't carry any). Details! switches to the new profile.
3. Repeat for `Fury Profile.txt` (name it `Schizzle's Warrior Fury`) and `Protection Profile.txt` (name it `Schizzle's Warrior Protection`).
4. Pick the profile for the spec you're in now from the Profiles dropdown (or type `/details profile Schizzle's Warrior Protection`, etc.).
5. `/reload` so the windows, snap links, lock and combat log settings apply cleanly.
6. On your other Warriors, tick **Auto Start Combatlog** once (`/details options` → **Combat Log**); see [Settings the profile switch doesn't carry](#settings-the-profile-switch-doesnt-carry).
7. Import the [XP & Rep Tray](../WeakAuras/#xp--rep-tray-separate-import) in WeakAuras (`/wa` → **Import**) to fill the 34 px strip under the windows. Without it, that strip is just empty screen.

Import all three, even if you only play one spec today, so the switcher has somewhere to go after a respec.

**The names matter.** The switcher looks for these three exact names. If a profile with that name already exists, Details! adds a "2" to the new one; delete the old profile first in **Profiles** and import again. To use other names, edit the three names at the top of `Spec Switch Code.lua` before pasting it.

**Font:** if WeakAuras isn't installed, Details! falls back to its default font with no error. Everything else works.

## Spec switching
**Details! has no working per-spec profile option in MoP Classic.** This was checked in the Details! source (Tercioo/Details-Damage-Meter master, Oct 15 2026, `Details_Mists.toc` Interface 50504):
- The default profile has a `profile_by_spec` table (`functions/profiles.lua`), but no code reads it, and its options panel is commented out (`frames/window_options2_sections.lua`). Profiles are picked per character only, or "Use on all characters".
- Auto Run Code has an **On Spec Change** event, but Details! only listens for `PLAYER_SPECIALIZATION_CHANGED` on clients newer than build 60000 (`functions/autorun.lua`: `if not detailsFramework.IsTimewalkWoW()`). On MoP Classic that slot runs **once, about 2 seconds after login or `/reload`**, and never again on its own.

**So the switch is a small snippet that runs from that slot and listens for spec changes itself.** It switches by your **actual spec** (Arms, Fury or Protection), not by talent group, so it stays right after a respec as well as a dual-spec swap.

### Set it up (once per account)
1. Open `/details options` and click **Auto Run Code** in the list on the left of the options window.
2. In **Event:** choose **On Spec Change**.
3. Paste the whole contents of [Spec Switch Code.lua](Spec%20Switch%20Code.lua) into the editor (replace anything already in that slot, or add it at the end if you already use it) and click **Save**.
4. Type `/reload`. Details! saves Auto Run Code account wide, so it now works on every Warrior you log in.

### What it does
- Checks your spec at login and loading screens, on a dual-spec swap (`ACTIVE_TALENT_GROUP_CHANGED`), on a respec (`PLAYER_SPECIALIZATION_CHANGED`, when the client sends it) and on talent changes.
- Arms (spec 71) → *Schizzle's Warrior Arms*, Fury (72) → *Schizzle's Warrior Fury*, Protection (73) → *Schizzle's Warrior Protection*.
- Uses Details!' own `Details:ApplyProfile`, the same call as picking a profile in the dropdown. No reload needed.
- **Never switches in combat.** It waits until combat ends.
- If the profile for your spec doesn't exist, it prints one chat line and does nothing.
- **Only runs on Warriors, and only while one of these three profiles is active**, so your other characters and other profiles are left alone. To switch away from any profile on a Warrior, set `ONLY_FROM_OUR_PROFILES = false` at the top of the code.
- At most one switch every 5 seconds, so it can't loop.
- Uses no function Details! blocks in Auto Run Code (no `pcall`, `loadstring`, `setmetatable` and so on).

To stop switching, clear the **On Spec Change** slot, Save and `/reload`.

**"Use on all characters"** (Profiles) forces one profile at every login. Leave it off if you use the switcher; if it's on with one of these three profiles, the switcher still corrects it about 3 seconds after login.

**Why not import the code with the profile?** Details! has an "Import Auto Run Scripts" box on profile import, but in the current source the imported code isn't added to the table Details! saves at logout, so it is lost. Pasting it in the Auto Run Code window is the reliable way.

## Bookmarks
Details! doesn't export bookmarks in profiles, so set them up once by hand: right-click a window's bar area to open the bookmark panel, then right-click a slot to choose what it holds. Suggested slots:
- **Arms / Fury:** Damage → Damage Done, Damage → Damage Taken, Damage → Enemies, Misc → Interrupts, Misc → Cooldowns, Misc → Deaths.
- **Protection:** Damage → Damage Taken, Custom → Tank Mitigation, Damage → Damage Taken by Spell, Misc → Cooldowns (defensive cooldowns), Misc → Deaths, Misc → Interrupts.

## Unlock, re-snap or unsnap the windows
- The windows are locked. Hover one and click **Unlock** at its bottom-right corner before moving or resizing it, and **Lock** afterwards.
- To re-snap, unlock both, then drag window 1's right edge against window 2's left edge until the edges highlight, then release.
- To unsnap, hover a window and click **Ungroup** along its bottom edge.
- Bar options live in **Options → Designer** in current Details! (click a part of the preview window). "Bars: General" and "Bars: Texts" look almost empty; that's normal.

## Fits with the rest of the kit
- The windows cover the bottom-right corner from 38 px up (the top of the XP & Rep Tray) to 199 px up (141 px windows plus their 20 px title bars). The top edge is unchanged from v1.4, so the [MoveAny tooltip spot](../MoveAny/) still sits just above them.
- [Baganator](../Baganator/)'s bag opens just above the windows (its bottom is 190 px up), so while it's open it covers the top 9 px of the title bars under it.
- **Bartender4 neighbours** (positions in UI units; at UI scale 1 on a 16:9 screen the UI is 1365 wide):
  - **Action bars 1–3:** their right end is about 213 px right of the screen centre, and window 1's left edge is 504 px in from the right. On a UI narrower than about 1435 px (such as 1365) window 1 covers the right end of bars 1–3 by up to about 35 px. On a wider UI (a smaller UI scale) they clear.
  - **Extra action button** (236 px right of centre, about 160 px up): when one appears it lands under window 1 on a UI narrower than about 1575 px.
  - **Micro menu:** Bartender4's faded-out micro menu (bottom right, its right edge 300 px in, its bottom 30 px up) sits under the bottom rows of window 1, so hovering there can show the micro buttons. Since the three-bar tray (top edge 38 px up), its bottom 8 px (30-38 px up) also overlap the tray's top bar from 300 px in leftwards, where hovering can bring up the micro buttons instead of the XP tooltip. Moving the micro menu up to y 42 in `/bt4` (or in the Bartender4 profile) clears it.
  - **Bar 5** (right edge, around the middle of the screen) now stays well above the windows, whose title bars top out 199 px up.
  - If something gets in the way, unlock and nudge the windows, lower the UI scale, or move the bar in `/bt4`.

## Caveats
- **Slug outline:** "Slug" is one of Details!' own outline choices, and both Details! and WeakAuras offer it on the Mists client, but it hasn't been seen in-game here. If names ever look wrong, pick another outline in **Designer → Bars → Unit Name**.
- **Not tested in-game.** The strings and the snippet were built and checked offline against the Details! source (see Source below), including a decode/re-encode round trip of every string and a simulated import.
- **Existing windows:** importing replaces your current window set with these 2 windows.
- **Display per window:** Details! may restore a character's last display for windows 1 and 2. If window 2 doesn't open on the listed display, pick it once from the menu; it's remembered after that.
- **Tank data needs a role:** avoidance is only recorded for players Details! sees as tanks (group role TANK, or your own tank spec). Block and absorb numbers start after the import and a `/reload`.
- Avoidable damage (Damage sub-display 9) is retail only, so it isn't used.
- Saving in the Auto Run Code window doesn't run the code; it starts after the next `/reload`.

## Source
[source/](source/) has the build and verify scripts (plain Lua 5.1) that make and check these files. They load Details!' own serializer and default tables from a Details! checkout:

```
cd source
DETAILS_SRC=/path/to/Details-Damage-Meter WA_TYPES=/path/to/WeakAuras/Types.lua lua build.lua
DETAILS_SRC=/path/to/Details-Damage-Meter WA_TYPES=/path/to/WeakAuras/Types.lua lua verify.lua
```

`verify.lua` checks each string's round trip, keys and types against Details!' defaults, fonts and textures, and a simulated import. It also checks each v1.6 setting against the key its options widget writes in the Details! source (and that the background, title bar texture, Slug outline and Specialization Alpha icons are real Details! values), the window size (250 × 141), the displays (Damage Done and Damage Taken, by Details!' own attribute numbers), the lock, and the anchors (bottom right, 4 px in from the right and 38 px up so the windows rest on the XP & Rep Tray, window 1 directly left of window 2, snapped side by side). It also checks the snippet: it compiles, uses none of Details!' blocked names, and behaves correctly in a mocked game (login, dual-spec swap, respec in combat, missing profile, your own profile left alone, throttle, non-Warrior).

## Version history
- **v1 (Nov 1 2026):** three spec profiles (two 232 × 176 windows each) plus the spec-switch snippet.
- **v1.1 (Nov 2 2026):** both windows in every profile are now **211 × 150** (was 232 × 176). They stay snapped edge to edge at the bottom right, 24 px from the right edge and 190 px up. Fonts, bar size 9, title 11 and displays are unchanged. Re-import the profile (or resize the windows by hand) to get the new size.
- **v1.2 (Nov 2 2026):** both windows are now **209 × 150** (was 211 × 150), still snapped edge to edge at the same spot. Nothing else changed.
- **v1.3 (Nov 2 2026):** both windows are now **250 × 175** (was 209 × 150) and **stacked** in the bottom-right corner, 4 px from the right and bottom edges (they used to sit side by side, 24 px in and 190 px up). Window 1 shows Damage Done and window 2 shows **Damage Taken** in all three profiles (Arms and Fury used to show Interrupts). Both windows start **locked**, and a locked window no longer stretches when its title bar is dragged. Re-import the profiles to get the changes.
- **v1.4 (Nov 2 2026):** the windows are **side by side** again instead of stacked: window 2 in the bottom-right corner, 4 px from the right and bottom edges, and window 1 directly to its left, snapped to it. Size (250 × 175), displays and the lock are unchanged. Re-import the profiles to get the change.
- **v1.5 (Nov 3 2026):** both windows are **22 px shorter (250 × 153, was 250 × 175)** and their bottom edge moved up from 4 px to **26 px**, so they sit right on top of the new WeakAuras [XP & Rep Tray](../WeakAuras/#xp--rep-tray-separate-import) (500 × 22, 4 px from the bottom). The title bars still top out 199 px up, so nothing above the windows moves. Width, side-by-side snap, displays and the lock are unchanged. Re-import the profiles (same names, delete the old ones first) and `/reload`.
- **v1.6 (Nov 3 2026):** new look and combat log settings in all three profiles, on both windows: Update Interval **0.05** (was 0.2), **Fast Updates** on, **Clear On Logoff**, **Advanced Damage Taken**, **Auto Start Combatlog**, and **Record Tank Avoidance** now in all three (it used to be Protection only). Designer: **Blizzard Out of Control** background at **0.25** row area opacity (was Details Ground at 0.82), **Details! Slash** title bar texture, **auto-hiding** title bar buttons, **Slug** outline on player names, **Specialization Alpha** icons and the **arena role icon**. Size (250 × 153), position, lock, fonts and displays are unchanged. Re-import the profiles (same names, delete the old ones first), `/reload`, and tick Auto Start Combatlog on any other Warrior.
- **v1.7 (Nov 3 2026):** both windows are **12 px shorter (250 × 141, was 250 × 153)** and their bottom edge moved up from 26 px to **38 px**, to make room for the XP & Rep Tray's new guild reputation bar (the tray is now 500 × 34, from tray v1.3). The title bars still top out 199 px up, so nothing above the windows moves. Width, side-by-side snap, lock, displays and every v1.6 setting (update interval, Fast Updates, combat log settings, background, title bar, outline, icons) are unchanged. Re-import the profiles (delete the old ones first, then import with the exact names `Schizzle's Warrior Arms`, `Schizzle's Warrior Fury` and `Schizzle's Warrior Protection`) and `/reload`.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
