# Schizzle's Warrior BetterFishing Setup

BetterFishing settings for the non-ElvUI Warrior kit in MoP Classic 5.5.x by Jon Shaw (Schizzle). BetterFishing lets you fish with one key, or a right-click double-click, and turns up the bobber splash while you fish. It has no frames, so nothing on screen changes.

> **Heads-up:** BetterFishing has no profile import, so this is a short click guide. Every option and label was checked against BetterFishing's own source (see [Source files](#source-files-source)). The same download works in MoP Classic and WoW Forever (its `.toc` lists both 50504 and 16001).

## Install (step by step)
1. Install BetterFishing and type `/bf` (or `/betterfishing`). Every box starts unticked.
2. Tick **Enhance Sounds** and set its slider to about **60%**. While you're fishing, BetterFishing turns music and ambience off and sets the master and effects volume to this level, so you hear the splash. Your normal sound settings come back when you stop. 100% (the default) is much louder than the rest of the kit's sounds.
3. Tick **Double-click to cast** and leave its speed at **0.2s**. Double right-click anywhere in the world to cast, and again to reel in when the bobber splashes. It never works in combat, so it can't fire a cast mid-fight.
4. Leave **Allow double-clicking to cast while mounted** unticked, so double right-clicking while mounted (to loot, talk to an NPC or turn the camera) never starts a cast.
5. Optional: in **Options > Keybindings**, find the **Better Fishing** section and bind a spare key such as **Alt-F** (no kit keybind uses it). That one key casts, then hooks the fish.

## Source files (`source/`)
- `settings.lua`: each box the guide mentions, with its key and label in `Settings.lua`.
- `verify.lua`: checks the guide against BetterFishing's own files:
  - each key and label exists, and the README names each label;
  - settings start empty (all boxes off), the double-click speed starts at 0.2 s, and the Enhance Sounds slider goes from 0 to 100%;
  - double-click casting is right-click only and never in combat;
  - Enhance Sounds sets the master volume and turns music off while fishing;
  - the Better Fishing key binding and `/bf` exist, and the `.toc` lists both MoP (50504) and Forever (16001).

```
cd source
lua verify.lua /path/to/Interface/AddOns
```

## Version history
- **v1 (Nov 2 2026):** first release.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
