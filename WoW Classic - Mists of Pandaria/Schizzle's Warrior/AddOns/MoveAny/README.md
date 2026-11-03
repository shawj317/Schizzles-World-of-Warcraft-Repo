# Schizzle's Warrior MoveAny Setup

MoveAny settings for the non-ElvUI Warrior kit in MoP Classic 5.5.x by Jon Shaw (Schizzle). In this kit MoveAny only moves the Blizzard frames nothing else handles: the loss-of-control alert, the tooltip, and the windows you open (character, spellbook, quest log and so on). Action bars belong to Bartender4, unit frames to BetterBlizzFrames, bags to Baganator, chat to Prat and the minimap to SexyMap, so MoveAny stays away from all of them.

> **Heads-up:** MoveAny's profile export only works between players on the same MoveAny version, and its positions depend on your screen size, so this is a click guide instead. Every element key, default and label was checked against MoveAny's own source (see [Source files](#source-files-source)). MoveAny ships a WoW Forever build (`MoveAny_Camelot.toc`, Interface 16001), and the same steps apply there.

## Install (step by step)
1. Install MoveAny and type `/move` (or `/moveany`). Use the search box at the top of the window to find each element below.
2. **Untick Extra Actionbar (Clickable Button)**. It's the only element MoveAny turns on by default, and Bartender4's extra action bar already places that button. If both are on, they fight over the same button. MoveAny can't spot this by itself because it only checks a per-character Bartender4 profile, not the shared "Schizzle's Warrior" profile.
3. Tick **Loss of Control Frame** and **Tooltip**.
4. Leave **Move Windows**, **Save Frame Position** and **Save Frame Scale** ticked (the defaults). You can then drag any Blizzard window by its title, and it stays where you put it.
5. Click **Reload & Reopen**. Then, for each of the two frames, click its row to highlight its mover and drag the mover (the arrow keys nudge it 1 px at a time):
   - **Loss of Control Frame:** by default it sits in the middle of the screen, right on top of the rotation aura. Drag its mover to about **150 px above the centre**, between the top of the WeakAuras HUD and the BigWigs pull countdown. Right-click the mover and set its scale to **0.8** so it fits in that gap.
   - **Tooltip:** drag its mover to the bottom right, just **above the Details! meters** (right edge about 4 px from the screen edge, bottom about 400 px up). Tooltips for units and the world then pop up there instead of on top of the meters.
6. Close the MoveAny window when you're done.

## Leave these unticked
Another addon in the kit already places each of these. Turning them on in MoveAny too makes both addons fight over the frame.

| MoveAny element | Owned by |
|---|---|
| **Actionbars 1 + 5 + 6**, the other Actionbars, **Pet Bar**, **Stance Bar Anchor** | Bartender4 |
| **Micro Menu**, **Bags** | Bartender4 (micro menu shown, Blizzard bag bar hidden) and Baganator |
| **Player Frame**, **Target Frame**, **Casting Bar**, **Buffs** | BetterBlizzFrames (frames kept at their Blizzard default spots) |
| **Chatframe** 1 to 10 and the chat buttons and edit box | Prat 3.0 |
| **Mini Map** | SexyMap |

Leatrix Plus is set up so it doesn't move anything ([its guide](../Leatrix%20Plus/) leaves Manage widget and Manage timer off), so MoveAny is the only addon moving frames.

## Source files (`source/`)
- `settings.lua`: each element the guide mentions, with its key and default in `settings.lua` and its English label.
- `verify.lua`: checks the guide against MoveAny's own files:
  - each element exists with the default the guide describes (Extra Actionbar on, everything else off; Move Windows and both Save options on);
  - each label is MoveAny's real English text, and the README names it;
  - MoveAny's Bartender4 check only looks at a per-character profile;
  - the MoP (`MoveAny_Mists.toc`, 50504) and Forever (`MoveAny_Camelot.toc`, 16001) builds are both there.

```
cd source
lua verify.lua /path/to/Interface/AddOns
```

## Version history
- **v1 (Nov 2 2026):** first release.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
