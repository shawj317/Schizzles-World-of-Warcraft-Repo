# QuestRoute

Zone quest route for World of Warcraft: Forever, by Jon Shaw (Schizzle). Interface **16001**.

It plans the quests in your current zone, including turn-ins and Questie follow-ups, and can point TomTom at the next step. `/qr` opens it.

This is an improved take on **RutaMisiones** (Fastest Quest Route, by Nico, MIT). The code was written separately and does not include that addon's source or data. Both can be installed: this one uses the folder `QuestRoute` and the saved variable `QuestRouteDB`.

## Install

1. Copy `AddOns/QuestRoute` into `Interface\AddOns\` on the Forever client. The folder name must stay `QuestRoute`.
2. Reload. `/qr` toggles the window. `/qr help` lists commands.

The notes that ship with the addon are in [AddOns/QuestRoute/README.md](AddOns/QuestRoute/README.md): screen, options, slash commands, Questie and TomTom, saved variables, and the in-game check list. [CHANGELOG.md](AddOns/QuestRoute/CHANGELOG.md) is the version history. [LICENSE](AddOns/QuestRoute/LICENSE) keeps Nico's copyright and adds Jon Shaw's.

## Tests

From this folder, with Lua 5.1:

```
lua5.1 tests/route_test.lua
lua5.1 tests/saved_test.lua
lua5.1 tests/secrets_test.lua
lua5.1 tests/load_test.lua
```

`tests/` is not part of the release zip.

MIT. Credit Jon Shaw (Schizzle) and [the repo](https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo).
