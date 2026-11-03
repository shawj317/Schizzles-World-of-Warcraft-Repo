# Schizzle's Warrior GTFO Setup

GTFO settings for the non-ElvUI Warrior kit in MoP Classic 5.5.x by Jon Shaw (Schizzle). GTFO plays a sound when you're standing in something bad. This setup keeps every alert type on but plays the softer sounds, so the alarm is easy to hear over BigWigs without making you jump.

> **Heads-up:** GTFO has no profile import, so this is a short click guide. Every option and label below was checked against GTFO's own source (see [Source files](#source-files-source)). GTFO ships a WoW Forever build (`GTFO_Camelot.toc`, Interface 16001), and the same settings apply there.

## Install (step by step)
1. Install GTFO and log in. If a "settings have been reset" popup appears, click **Yes** to open the options. Otherwise type `/gtfo options`.
2. Drag **GTFO Volume** to **2: Soft**.
3. Leave **Sound Channel** on **Master**, so alerts still play when you turn game sounds or music down.
4. Make sure these four boxes are ticked (they're on by default):
   - **Raid/High Damage sounds**
   - **PvP/Environment/Low Damage sounds**
   - **Fail Alert sounds**
   - **Friendly Fire sounds**
5. Leave **Trivial content alerts**, **Play sounds when muted** and **Experimental/Beta Mode** unticked.
6. Click **Test** next to each sound type to hear it. If the soft buzzer is too quiet with your headset, use **3: Normal (Recommended)** instead.

## Why these settings
| Setting | Value | Why |
|---|---|---|
| GTFO Volume | 2: Soft | plays GTFO's quieter sound files. From 4 up, each alert plays two or three times at once, which drowns out BigWigs callouts. |
| Sound Channel | Master | follows the master volume only. On SFX, turning spell sounds down would also turn GTFO down. |
| Alert sounds | all four on | high damage means move now; low damage, fail and friendly fire are all useful for a melee class. |
| Trivial content alerts | off | no alarms while soloing old content that can't hurt you. |
| Play sounds when muted | off | muting the game mutes GTFO too. |

GTFO doesn't draw anything on screen, so it can't overlap the WeakAuras HUD or any other frame.

## Source files (`source/`)
- `settings.lua`: each setting, its key in GTFO's saved settings, and its label.
- `verify.lua`: checks the guide against GTFO's own files:
  - every key, default and label exists in `GTFO.lua` and `Localization/enUS.lua`, and the README names each label;
  - `/gtfo options` opens the options, Soft uses the `_soft` sounds, and Loud and up play each alert more than once;
  - the MoP (`GTFO_Mists.toc`, 50504) and Forever (`GTFO_Camelot.toc`, 16001) builds are both there.

```
cd source
lua verify.lua /path/to/Interface/AddOns
```

## Version history
- **v1 (Nov 2 2026):** first release.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
