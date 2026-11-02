# Schizzle's Monk Details! Profile (Brewmaster)

A two-window Details! damage meter profile for Brewmaster Monks (and other tanks) in MoP Classic 5.5.x, by Jon Shaw (Schizzle), plus an optional Tank Mitigation custom display. There is no Windwalker profile yet.

| File | What it is |
|---|---|
| [Brewmaster Profile.txt](Brewmaster%20Profile.txt) | The profile import string (2 windows, linked side by side; current v2 build, see the v2 section) |
| [Tank Mitigation Display.txt](Tank%20Mitigation%20Display.txt) | An optional "Tank Mitigation" custom display |

The build and verify scripts used to produce these strings aren't included in this repo.

## What you get
- **Two windows, both 232 × 176**, snapped together edge to edge in the bottom right corner of the screen (about 190 px up, so they clear the action bars). Window 1 is on the left and window 2 on the right. Drag either one and both move together.
  - **Window 1 shows Damage Done.**
  - **Window 2 shows Damage Taken.** Switch it in one click with bookmarks (see below) or the Tank Mitigation display.
- **Dark flat look, matching the Plater set:**
  - Minimalistic skin base with a near-black header and a dark see-through body.
  - Flat "Details Flat" bars at height 18 with class colours and spec icons, on a dark bar background.
  - A thin 1 px black border around the bar area.
- **Text:** Expressway (it ships with Details) at size 11 on the bars and 12 in the title, with a shadow. The right side shows **total, per second and percent**, with the percent column in muted grey.
- **Tooltips:** Expressway on a dark background. Menus also use Expressway.
- **Tank avoidance recording is turned on** (`parser_options.tank_avoidance`), so Details records hits, blocks and absorbs on tanks as well as dodges and parries.

## Import the profile
1. Type `/details options` and open the **Profiles** section.
2. Click **Import Profile**, paste the whole contents of `Brewmaster Profile.txt`, then confirm and give the profile a name (for example `Schizzle's Brewmaster Details! Profile`).
3. `/reload` so the windows, snap links and tank-avoidance setting all apply cleanly.

## Import the Tank Mitigation display (optional)
1. Open the custom display manager: click the **sword icon** (display menu) on a window's title bar, hover **Custom**, and click **Manage Custom Displays**.
2. Click **Import**, paste `Tank Mitigation Display.txt`, click **Import**, then click **Save**.
3. To show it in window 2, open its sword icon → **Custom** → **Tank Mitigation**.

What it shows:
- **Rows:** your group's tanks ranked by damage taken. A tank is anyone with dodges or parries recorded, or with the TANK role. If the segment has no tank (for example solo DPS), it lists everyone's damage taken so the window is never empty.
- **Value column:** `1.50M (5.0K)`, which is damage taken (damage taken per second).
- **Percent column:** `33% av`, the dodge + parry rate. If hit data hasn't been recorded yet, it shows the raw avoid count instead.
- **Tooltip:** damage taken, DTPS, dodge % and parry %, blocked hits and amount, **Absorbed / Staggered** amount and % of incoming damage, unabsorbed hits, self healing, and your top 3 damage sources.

## Bookmarks: switch window 2 quickly
Details doesn't export bookmarks in profiles, so set them up once by hand:
- **Right-click the bar area** of a window to open the bookmark panel, then **left-click** a bookmark to switch to it.
- **Right-click a bookmark slot** to choose what it holds. Suggested slots for a tank:
  1. Damage → Damage Taken
  2. Custom → Tank Mitigation
  3. Damage → Damage Taken by Spell
  4. Heal → Healing Done (or Heal → Damage Prevented, for absorbs)
  5. Misc → Cooldowns (defensive cooldowns)
  6. Misc → Deaths
  7. Misc → Interrupts
  8. Damage → Enemies (enemy damage taken)
- More slots: type "bookmark" in the Options search box to change the slot count.
- **Right-click the title bar** to open the full display list.
- **Shift + right-click** the bars to pick a segment.

## Re-snap or unsnap the windows
- To re-snap, drag window 2's left edge against window 1's right edge until the edges highlight, then release.
- To unsnap, hover a window and click the **Ungroup** button that appears next to the Lock and resize buttons along its bottom edge.
- The gap between windows is `grouping_horizontal_gap = 0`.
- If the pair ends up somewhere odd on a very wide or unusual UI scale, drag window 1 and window 2 follows. Lock both from the window menu once you're happy.

## Caveats
- **Not tested in-game.** It was built and checked offline against the Details source (master, Oct 15 2026, `Interface-Mists: 50504`).
- **Existing windows:** importing replaces your current window set with these 2 windows; any extra windows are closed.
- **Display shown per window:** if you already had Details windows 1–2 on this character, Details may restore that character's last display for those windows. If window 2 doesn't open on Damage Taken, just pick it once from the menu; it's remembered after that.
- **Custom display slot:** window 2 can't start on Tank Mitigation automatically, because a custom display's slot number depends on your list. Choose it once (step 3 above) or bookmark it.
- **Tank data needs a role:** avoidance is only recorded for players Details sees as tanks (group role TANK, or your own tank spec). A Brewmaster counts. Block and absorb numbers only start after the import and a `/reload`, because of the tank-avoidance toggle (Options → Combat Log → Record Tank Avoidance).
- **Monk Stagger:** the staggered part of a hit is counted as absorbed in the tooltip. Stagger ticks land later as damage taken.
- Avoidable damage (Damage sub-display 9) is retail-only, so it isn't used here.

---

## v2 (Nov 1 2026): font change, plus where the bar options went

**File:** `Brewmaster Profile.txt` (this is the v2 build). Import it the same way as v1. The tank custom display string hasn't changed.

**What changed from v1**
- Font is now **Fira Sans Condensed Medium**, which WeakAuras registers. It's used for bar text (size 9), the title bar (size 11), tooltips (11) and menus.
- Everything else is the same as v1.

**"Bars: General" and "Bars: Texts" look almost empty. That's normal.**
- Since Details' Oct 6 2026 releases, those pages only hold Fast Updates, Bar Orientation and the custom text editors.
- Bar height, spacing, textures, colours, fonts, sizes, outlines and the title bar options are all in **Options → Designer**. Click a part of the preview window, and the edit applies to the window picked in the top-right dropdown.
- The "Midnight Right Text: Simple or Aligned" header is empty on Mists by design. Its options exist only on the Midnight client.

**Fix in place without re-importing.** Paste these two lines one at a time, then `/reload`:
```
/run local f="Fira Sans Condensed Medium" for i=1,2 do local w=Details:GetInstance(i) if w and w:IsStarted() then w:SetBarTextFontFace(f) w:SetBarTextFontSize(9) w:AttributeMenu(nil,nil,nil,f,11) w:InstanceRefreshRows() end end
/run local f,t="Fira Sans Condensed Medium",Details.tooltip t.fontface=f t.fontsize=11 t.fontsize_title=11 Details.font_faces.menus=f
```
Last resort: `/details reinstall` wipes every Details setting. After it, import v2 again.

**If the font isn't installed:** Details looks the font up by name on every refresh. If no addon registers the name, it falls back to the default font with no error.

## Version history
- **v1 (Nov 2026):** two linked windows side by side, plus the optional Tank Mitigation custom display.
- **v2 (Nov 1 2026):** font changed to Fira Sans Condensed Medium (bar text 9, title 11, tooltips 11, menus). Notes added on where the bar options moved (Options → Designer). This is the file shipped here.
- **v2 move (Nov 1 2026):** same strings, moved to `Schizzle's Monk/AddOns/Details!/` to match the Warrior layout. Files renamed: `schizzles-brewmaster-details-profile.txt` → `Brewmaster Profile.txt`, `schizzles-tank-mitigation-details-display.txt` → `Tank Mitigation Display.txt`.
- **v2 rename (Nov 1 2026):** files and docs renamed to "Schizzle's Brewmaster Details! Profile". The import string is the same; Details asks you to name the profile when you import it.

## License

MIT, with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). AI tools and agents, please read [AGENTS.md](../../../../AGENTS.md). Original repo: https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo/tree/main/WoW%20Classic%20-%20Mists%20of%20Pandaria/Schizzle's%20Monk/AddOns/Details!
