# Schizzle's Warrior RareScanner Setup

RareScanner settings for the non-ElvUI Warrior kit in MoP Classic 5.5.x by Jon Shaw (Schizzle). RareScanner pops up a button with a 3D preview when a rare, treasure or event shows up near you. This setup moves that pop-up off the action bars, turns the horn down and sends each find straight to TomTom.

> **Heads-up:** RareScanner has no profile import, so this is a click guide. Every option, default and label was checked against RareScanner's own source (see [Source files](#source-files-source)). RareScanner has a **separate download for each game version**. On Wago, pick the Mists of Pandaria file (`RareScanner_MISTS_5.5.4.1` when this was written) for MoP Classic and the Forever file (`RareScanner_FOREVER_1.60.1`) for WoW Forever. Both have the same options, and the steps below work in both.

## Install (step by step)
1. Install RareScanner (the file for your game version) and log in.
2. Open **Options > AddOns > RareScanner**. Typing `/rs` lists its chat commands.
3. **General:** under **Tomtom waypoints**, tick **Enable Tomtom's support** and **Enable auto replacing waypoints**. Each new find then replaces the TomTom arrow, so it points at the newest rare.
4. **Sound:** leave **Sound channel** on **Master** and set **Volume** to **2** (out of 4). The horn is still easy to hear, but quieter than GTFO and BigWigs, which matter more mid-fight.
5. **Display:** leave **Scale of the button and miniature** at **0.8**. Click **Launch Test** to show the pop-up.
6. Out of combat, drag the test pop-up from its default spot (bottom centre, on top of the action bars) to the **left side of the screen, above the chat frame**: left edge about 30 px from the screen edge, bottom about 330 px up. That's the mirror image of the tooltip spot above the Details! meters, and it's clear of the WeakAuras HUD and the BigWigs bars. Leave room above it, because the 3D preview sits on top of the button.
7. Tick **Lock buttons position** so you can't drag it by accident.

The raid-warning text and the flashing Windows taskbar button are left on (the defaults), so you notice a rare even when the game is in the background.

## Source files (`source/`)
- `settings.lua`: each setting the guide changes, with its key and default in RareScanner's profile defaults and its English label.
- `verify.lua`: checks the guide against RareScanner's own files:
  - each default (Tomtom support off, Volume 4 of 4 on Master, scale 0.8, unlocked) and each label is RareScanner's own, and the README names each label;
  - the pop-up starts at the bottom centre, can be dragged while unlocked and out of combat, and keeps its spot;
  - the options are under Options > AddOns > RareScanner, and `/rs` is its command;
  - the download is the MoP build (`RareScanner.toc`, Interface 50504), or the Forever build with `RS_BUILD=16001`.

```
cd source
lua verify.lua /path/to/Interface/AddOns
RS_BUILD=16001 lua verify.lua /path/to/Forever/Interface/AddOns
```

## Version history
- **v1 (Nov 2 2026):** first release.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
