# ProtWar24 (GSE import for WoW Forever)

One sequence for [GSE](https://github.com/TimothyLuke/GSE-Advanced-Macro-Compiler) 3.3.37-a, for an Orc Protection Warrior at level 24 on WoW Forever, by Jon Shaw (Schizzle).

| File | What it is |
|---|---|
| [ProtWar24.txt](ProtWar24.txt) | The import string and nothing else. One line, starting with `!GSE3!`. |
| [source/](source/) | The sequence, and the scripts that build and check the string. |

The string was produced by calling `GSE.EncodeMessage` from GSE 3.3.37-a. It is not a Lua snippet and it is not the sealed `!GSE3!+` form. GSE itself is All Rights Reserved and is not included in this repository.

## What was checked

| Item | Result |
|---|---|
| Release | GSE **3.3.37-a**, commit `ad50d1ab6e6d754f0b1c49f06c320cf7788f27a4`, 5 Nov 2026. The shipped TOC says `## Version: 3.3.37-a`. |
| Interface | `GSE.toc` lists `16001`. `release.json` for that tag has flavor `forever` at interface 16001. `GSE.TOCFlavour(16001)` is `"forever"`, so a Forever client does not get the "not designed for this version" warning. Classic Era is 11509 and is a different flavour. |
| Class | **SpecID 1, Warrior.** `GSE.SpecIDClassList[1] = 1`. `GSE.GetClassIDforSpec(1)` returns 1 because an id of 13 or less is that class. Class icon 1 is marked Warrior. **8 is Mage** (`SpecIDClassList[8] = 8`, trees Arcane/Fire/Frost, class icon marked Mage). Protection's retail tree id 73 also files under class 1, but this sequence uses the class id so it is the Warrior entry rather than a tree filter. |
| Schema | `{ type = "COLLECTION", payload = { Sequences, Variables, Macros, ElementCount } }`, the wrapper in `GSE_GUI/Export.lua`. The sequence uses `Versions`, not the old `Macros` field, which 3.3.37 refuses. Each block is `{ Type = "Action", type = "macro", macro = "..." }`. GSE compiles that to `macrotext` on a secure button. |
| Version number | `GSE.ParseVersion("3.3.37-a")` drops the `-a` and returns `3*1000 + 3*100 + 37 = 3337`. The sequence is stamped 3337 with `EnforceCompatability`, so 3.3.37-a imports it with no older-version note. An older GSE refuses it. |
| Round trip | `GSE.DecodeMessage` then `GSE.EncodeMessage` returns the same string. Python's zlib (`wbits = -15`) inflates the payload to the same bytes. `GSE.ImportSerialisedSequence` accepts it and files it under class 1. `GSE.CompileTemplate` returns two presses whose `macrotext` is the two blocks below. |

GSE has not been installed, and this has not been pressed in game.

## The two presses

GSE runs one block per key press, then the other, then the first again. A press that cannot cast does not move on to the other block by itself. The next press is what runs the next block. Heroic Strike is only on Alt, so an ordinary press does not queue it.

Block 1:

```
/startattack
/cast [mod:alt,mod:shift] Cleave; [mod:shift] Thunder Clap; [mod:ctrl] Shield Block; [mod:alt] Heroic Strike; [stance:2] Revenge
```

Block 2 is the same line with `Sunder Armor` in place of `Revenge`.

| While you hold | The `/cast` line tries |
|---|---|
| nothing, in stance 2 | Revenge, then Sunder Armor on the next press |
| Shift | Thunder Clap |
| Ctrl | Shield Block |
| Alt | Heroic Strike |
| Alt and Shift | Cleave |

Conditions are first match, in that order, because that is the order in the line. With no modifier, outside stance 2, the `/cast` matches nothing. `/startattack` still runs. This kit's Warrior Guide uses stance 2 as Defensive Stance.

Taunt, Shield Bash and cooldowns are not in the sequence. Last Stand (25), Vanguard (29) and Shield Slam (40) are not in it either. The talents at 24 (Shield Specialization 5, Improved Thunder Clap 3, Improved Bloodrage 2, Improved Revenge 3, Master of Defense 2) are the character this was written for. They are not encoded as a GSE talent string, and nothing here is a claim about the best rotation.

## Import

1. Install **GSE 3.3.37-a** (the release lists Forever, interface 16001). An older build will refuse this string.
2. Log in on the Warrior.
3. Open [ProtWar24.txt](ProtWar24.txt), select the whole line and copy it.
4. Type `/gse`, open **Import**, paste, and import. **ProtWar24** is the only sequence. Leave it ticked and import.
5. Out of combat, put it on an **empty action button**. Forever does not honour a key GSE binds with `SetBindingClick` (`GSE.DirectKeybindsRetired` is true when `GSE.IsForever` is true). The button's own key is the one that presses it.
6. Leave GSE's Shift, Alt and Ctrl **pause** options off. They default off. If one is on, that modifier blanks the press instead of casting.

## Known limits

- **Not pressed in game.** The checks are the addon's own import and compiler, run offline against the 3.3.37-a source, plus an independent zlib inflate.
- **No checksum.** GSE 3.3.37 can stamp `MetaData.Checksum` with a hash salted by the exporting client's `WOW_PROJECT_ID` and `GetExpansionLevel`. Those two values are not in the addon source. A hash made with the wrong salt fails as "altered". Leaving the checksum off makes `GSE.VerifySequenceChecksum` return `no_checksum`, which that build does not treat as tampering. A collection import does not stop for it.
- **English spell names.** The blocks are the names above, not spell ids. `GSE.TranslateSequence` would rewrite known names to ids on a client that has them. This string does not, so the imported text stays as written.
- **Key order inside the encoded map** follows this writer (numbers, then names). GSE reads the map either way. Compressing again in game can produce different bytes. Decoding this string is what was checked.
- **255 characters.** Block 1 is 141 characters and block 2 is 146, under the macro limit GSE enforces.

## Source files

- `source/sequence.lua`: name, metadata and the two blocks.
- `source/gse_format.lua`: a stand-in for `C_EncodingUtil` (standard Base64, raw DEFLATE via LibDeflate, CBOR). No GSE code is copied.
- `source/build.lua`: loads `GSE/API/Serialisation.lua` from `GSE_SRC` and calls `GSE.EncodeMessage`. Run `lua build.lua`.
- `source/gse_sim.lua`: loads GSE 3.3.37-a, imports the string and compiles it. Debug-only blocks are commented out the way the release zip comments them.
- `source/verify.lua`: the checks in the table above, then `gse_sim.lua`. Run `lua verify.lua`.

`GSE_SRC` defaults to `/tmp/gse-src/gse-3337a`. `WA_LIBS` defaults to `/opt/wow-addon-deps` and must contain `LibDeflate/LibDeflate.lua`.

## License

MIT with an attribution requirement: credit Jon Shaw (Schizzle) and link to https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo. See the repository [LICENSE](../../../../LICENSE). AI tools and agents, please read [AGENTS.md](../../../../AGENTS.md). GSE is by TimothyLuke and is not part of this repository.
