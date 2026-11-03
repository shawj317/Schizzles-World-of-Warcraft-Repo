# Schizzle's Warrior Prat 3.0 Profile

A Prat 3.0 chat profile for the non-ElvUI Warrior kit in MoP Classic 5.5.x by Jon Shaw (Schizzle): Fira Sans Condensed Medium in chat, short channel names, bronze timestamps, clickable links you can copy, and a dark edit box with a bronze border.

> **Heads-up:** Prat has no import box, so the profile is applied by the [Schizzle's Warrior Setup](../SchizzlesWarriorSetup/) helper addon (`/schizzle chat`). Prat runs on both MoP Classic and WoW Forever with the same settings.

| File | What it is |
|---|---|
| [Profile.lua](Profile.lua) | the profile, in Prat's own module and setting keys |

## Install (step by step)
1. Install Prat 3.0 and the [helper addon](../SchizzlesWarriorSetup/).
2. Log in and click **Yes** on the Schizzle's Warrior prompt, or type `/schizzle chat`.
3. Click **Reload** when asked.

The character moves to a new Prat profile, **Schizzle's Warrior**. Your old one is kept (`/prat` > Profiles).

## What it does
- **Font:** Fira Sans Condensed Medium in every chat window, no outline. Size is left as it was.
- **Short channel names:** [G], [P], [R], [1], and so on.
- **Timestamps** in bronze, `[21:05]`, local time.
- **Links:** web addresses turn gold and clickable; click one to get a copy box.
- **Edit box:** above the chat window, near-black with a 12 px bronze border, coloured by the channel you're typing in, in Fira.
- **Buttons:** the scroll arrows, minimise and voice buttons are hidden; the chat menu, channel and Battle.net buttons stay. A reminder shows when you are scrolled up.
- **History:** 1000 lines per window, kept between reloads.
- **Copy chat** and **fading** on. Prat's **chat tabs** module is off, so tabs look like Blizzard's.

## Checks
In [SchizzlesWarriorSetup/source](../SchizzlesWarriorSetup/source/): `verify.lua` writes the profile the way the helper does, loads it with Prat's own AceDB-3.0, checks every module setting comes back as written and the old profile is untouched, and checks every key here appears in Prat's code.

## Version history
- **v1 (Nov 2 2026):** first release.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
