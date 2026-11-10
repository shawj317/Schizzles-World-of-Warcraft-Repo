# Wayfarer

Quest route for World of Warcraft: Forever, by Jon Shaw (Schizzle). Interface **16001**. This is QuestRoute renamed.

`/wayfarer` or `/wf` opens it. `/qr` still works. It can plan the current zone or every non-dungeon quest in the log, draw round numbered pins, and label a flight, boat, or zeppelin when that is faster than walking.

The flight times are reused from **RutaMisiones** (Fastest Quest Route, by Nico, MIT). The rest of Wayfarer was written separately. Delete an old `QuestRoute` folder so both copies are not loaded. The first launch copies `QuestRouteDB` into `WayfarerDB` if Wayfarer has no settings yet.

## Install

1. Copy `AddOns/Wayfarer` into `Interface\AddOns\`. The folder name must stay `Wayfarer`.
2. Delete `Interface\AddOns\QuestRoute` if it is still there.
3. Reload.

The notes that ship with the addon are in [AddOns/Wayfarer/README.md](AddOns/Wayfarer/README.md). [CHANGELOG.md](AddOns/Wayfarer/CHANGELOG.md) is the version history. [LICENSE](AddOns/Wayfarer/LICENSE) keeps Nico's copyright and adds Jon Shaw's.

## Tests

From this folder, with Lua 5.1:

```
lua5.1 tests/route_test.lua
lua5.1 tests/saved_test.lua
lua5.1 tests/secrets_test.lua
lua5.1 tests/travel_test.lua
lua5.1 tests/load_test.lua
```

`tests/` is not part of the release zip.

MIT. Credit Jon Shaw (Schizzle) and [the repo](https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo). Flight times: Nico, RutaMisiones.
