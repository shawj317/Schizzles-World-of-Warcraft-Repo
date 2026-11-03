# Schizzle's Warrior Details! Profiles

Three Details! damage meter profiles for Warriors in MoP Classic 5.5.x, one per spec, by Jon Shaw (Schizzle), plus a small Auto Run Code snippet that switches between them when the spec changes.

| File | In-game profile name | Window 1 | Window 2 |
|---|---|---|---|
| [Arms Profile.txt](Arms%20Profile.txt) | **Schizzle's Warrior Arms** | Damage Done | Damage Taken |
| [Fury Profile.txt](Fury%20Profile.txt) | **Schizzle's Warrior Fury** | Damage Done | Damage Taken |
| [Protection Profile.txt](Protection%20Profile.txt) | **Schizzle's Warrior Protection** | Damage Done | Damage Taken (tank avoidance recording on) |
| [Spec Switch Code.lua](Spec%20Switch%20Code.lua) | – | switches between the three profiles by spec | |

The Arms and Fury strings are identical: the layout and displays are the same, and Details! takes the profile's name from what's typed at import. They are shipped as two files so each spec has its own profile to tweak.

The look matches [Schizzle's Monk Details! Profile](../../../Schizzle's%20Monk/AddOns/Details!/) (v2.2) and the Warrior [Plater profiles](../Plater/).

## What you get (all three profiles)
- **Two windows, both 250 × 175**, stacked in the bottom-right corner, 4 px from the right and bottom edges of the screen. Window 1 is on top and window 2 sits right below it. They're snapped together.
- **Locked:** both windows start locked, so they can't be dragged or resized by accident, and dragging the title bar doesn't stretch them either. To move or resize one, hover it and click **Unlock** in its bottom-right corner. Click **Lock** again when you're done.
- **Dark flat look:** Minimalistic skin base, near-black header, dark see-through body, "Details Flat" bars at height 18 with class colours and spec icons, and a thin 1 px black border around the bar area.
- **Text:** Fira Sans Condensed Medium (WeakAuras registers it), bar text size 9 and title size 11. The right side of each bar shows **total, per second and percent**, with the percent in muted grey.
- **Tooltips and menus:** the same font, tooltips at size 11 on a dark background.
- **Window 1: Damage Done** in all three profiles.
- **Window 2: Damage Taken** in all three profiles. Jon asked for a tank mitigation view, and Details! has no built-in display by that name (checked in its source for MoP Classic). Damage Taken is the closest one it ships: it lists who took the most damage, and its tooltips break each player's hits down by spell, with dodges, parries, blocks and absorbs once tank avoidance is recorded.
- **Record Tank Avoidance:** the Protection profile also turns on `parser_options.tank_avoidance`, so Details! records hits, blocks and absorbs on tanks as well as dodges and parries. This is an account-wide Details! setting, so the Arms and Fury profiles leave it alone; once the Protection profile has been imported it's on for all three.
- **A real mitigation view:** the optional **Tank Mitigation** custom display from the [Monk Details! folder](../../../Schizzle's%20Monk/AddOns/Details!/) works for Protection Warriors too (it shows block amounts and dodge + parry rate). A profile can't open on a custom display by itself, because its slot number depends on each player's list, so pick it once from window 2's sword icon → **Custom** → **Tank Mitigation** (or bookmark it).

## Import
1. Type `/details options` and open **Profiles**.
2. Click **Import Profile** and paste the whole contents of `Arms Profile.txt`. When Details! asks for the profile name, type **exactly** `Schizzle's Warrior Arms`. Leave **Import Auto Run Scripts** unticked (the profiles don't carry any). Details! switches to the new profile.
3. Repeat for `Fury Profile.txt` (name it `Schizzle's Warrior Fury`) and `Protection Profile.txt` (name it `Schizzle's Warrior Protection`).
4. Pick the profile for the spec you're in now from the Profiles dropdown (or type `/details profile Schizzle's Warrior Protection`, etc.).
5. `/reload` so the windows, snap links, lock and tank-avoidance setting apply cleanly.

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
- To re-snap, unlock both, then drag window 1's bottom edge onto the top of window 2's title bar until the edges highlight, then release.
- To unsnap, hover a window and click **Ungroup** along its bottom edge.
- Bar options live in **Options → Designer** in current Details! (click a part of the preview window). "Bars: General" and "Bars: Texts" look almost empty; that's normal.

## Fits with the rest of the kit
- The stack covers the bottom-right corner up to about 395 px from the bottom (two 175 px windows plus their 20 px title bars), so the [MoveAny tooltip spot](../MoveAny/) sits just above it.
- [Baganator](../Baganator/)'s bag opens over the top of the stack and covers it while it's open, as before.
- **Bartender4 neighbours:** on a 16:9 screen at the default UI scale, window 2's left edge comes within about 7 px of the right-hand column of Bartender4 bar 5 (the 6 × 2 block right of the main bars) and overlaps it slightly. Bartender4's faded-out micro menu (bottom right, 300 px in) also sits under window 2's bottom rows, so hovering there can show the micro buttons. If either gets in the way, unlock and nudge window 2, or move the micro menu in `/bt4`.

## Caveats
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

`verify.lua` checks each string's round trip, keys and types against Details!' defaults, fonts and textures, and a simulated import. It also checks the window size (250 × 175), the displays (Damage Done and Damage Taken, by Details!' own attribute numbers), the lock, and the anchors (bottom right, 4 px in, window 1 stacked on window 2's title bar). It also checks the snippet: it compiles, uses none of Details!' blocked names, and behaves correctly in a mocked game (login, dual-spec swap, respec in combat, missing profile, your own profile left alone, throttle, non-Warrior).

## Version history
- **v1 (Nov 1 2026):** three spec profiles (two 232 × 176 windows each) plus the spec-switch snippet.
- **v1.1 (Nov 2 2026):** both windows in every profile are now **211 × 150** (was 232 × 176). They stay snapped edge to edge at the bottom right, 24 px from the right edge and 190 px up. Fonts, bar size 9, title 11 and displays are unchanged. Re-import the profile (or resize the windows by hand) to get the new size.
- **v1.2 (Nov 2 2026):** both windows are now **209 × 150** (was 211 × 150), still snapped edge to edge at the same spot. Nothing else changed.
- **v1.3 (Nov 2 2026):** both windows are now **250 × 175** (was 209 × 150) and **stacked** in the bottom-right corner, 4 px from the right and bottom edges (they used to sit side by side, 24 px in and 190 px up). Window 1 shows Damage Done and window 2 shows **Damage Taken** in all three profiles (Arms and Fury used to show Interrupts). Both windows start **locked**, and a locked window no longer stretches when its title bar is dragged. Re-import the profiles to get the changes.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
