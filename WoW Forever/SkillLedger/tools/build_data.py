#!/usr/bin/env python3
"""Build SkillLedger's recipe tables from WoW Forever client data.

Sources, in order:

- Forever client DB2 build 1.60.1.70790 via wago.tools (product wowf):
  SkillLine, SkillLineAbility, SpellName, SpellReagents, SpellEffect,
  ItemSparse, Item, ItemEffect, ItemXItemEffect.
  Yellow is TrivialSkillLineRankLow. Grey is TrivialSkillLineRankHigh.
  Green is their integer midpoint, which is what Wowhead Classic publishes
  and what the vanilla skill-up curve treats as the 50% point.
- Wowhead Classic skill pages supply the color curve when the spell is
  listed. Classic Era SkillLineAbility (build 1.15.9.70576) fills spells the
  skill page did not include. Those two agree on yellow and grey. Forever's
  own trivial ranks are used only for spells in neither source, because on
  this wowf build hundreds of shared recipes are shifted down (often by 25)
  while Classic Era and Wowhead still agree.
- Wowhead Classic item XML (jsonEquip.buyprice) is the neutral vendor price.
  It is present only when a vendor sells the item. ItemSparse.BuyPrice is not
  used. The sold-by list plus each NPC's faction page records which faction
  owns the vendor, so a reputation discount can be applied later.

The script expects the CSVs in FOREVER_DB (default: /tmp/forever-db) and
caches Wowhead pages under /tmp/skillledger-wh.
"""

from __future__ import annotations

import csv
import json
import os
import re
import time
import urllib.request
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed

BUILD = "1.60.1.70790"
ERA_BUILD = "1.15.9.70576"
FACTION_RE = re.compile(r"faction=(\d+)/[^\]\s]*\]([^\[\\<]+)")
DB = os.environ.get("FOREVER_DB", "/tmp/forever-db")
CACHE = os.environ.get("SKILLLEDGER_CACHE", "/tmp/skillledger-wh")
HERE = os.path.dirname(os.path.abspath(__file__))
ADDON = os.path.normpath(os.path.join(HERE, "..", "AddOns", "SkillLedger"))

# Classic skill line ids. The 2937+ copies in this client have no recipes.
PROFESSIONS = [
    # id, name, secondary, gathering (no craft path of its own)
    (171, "Alchemy", False, False),
    (164, "Blacksmithing", False, False),
    (333, "Enchanting", False, False),
    (202, "Engineering", False, False),
    (165, "Leatherworking", False, False),
    (186, "Mining", False, True),
    (182, "Herbalism", False, True),
    (393, "Skinning", False, True),
    (197, "Tailoring", False, False),
    (185, "Cooking", True, False),
    (129, "First Aid", True, False),
    (356, "Fishing", True, True),
]
PROF_IDS = {row[0] for row in PROFESSIONS}

# Wowhead Classic skill pages. The recipe list on the skill page is the
# learn-at source. Gathering pages are fetched so a node spell is not missed.
WH_SKILLS = {
    171: "alchemy",
    164: "blacksmithing",
    333: "enchanting",
    202: "engineering",
    165: "leatherworking",
    186: "mining",
    182: "herbalism",
    393: "skinning",
    197: "tailoring",
    185: "cooking",
    129: "first-aid",
    356: "fishing",
}

# Wowhead answers a descriptive agent with an empty 202. A browser token is required.
UA = {"User-Agent": "Mozilla/5.0"}


def read_csv(name):
    path = os.path.join(DB, name + ".csv")
    with open(path, encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def fetch(url, cache_name):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, cache_name)
    if os.path.exists(path) and os.path.getsize(path) > 0:
        with open(path, encoding="utf-8") as handle:
            return handle.read()
    req = urllib.request.Request(url, headers=UA)
    last = None
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=60) as response:
                text = response.read().decode("utf-8", "replace")
            if not text.strip():
                raise RuntimeError(f"empty response ({response.status})")
            with open(path, "w", encoding="utf-8") as handle:
                handle.write(text)
            return text
        except Exception as exc:  # noqa: BLE001 - retry then surface
            last = exc
            time.sleep(1.5 * (attempt + 1))
    raise RuntimeError(f"fetch failed for {url}: {last}")


def extract_json_array(html, marker):
    """Return the first JSON array in `data: [` after marker."""
    start_at = html.find(marker)
    if start_at < 0:
        return []
    window = html[start_at:start_at + 4000]
    rel = window.find("data:")
    if rel < 0:
        return []
    bracket = html.find("[", start_at + rel)
    if bracket < 0:
        return []
    depth = 0
    in_str = False
    esc = False
    for index in range(bracket, len(html)):
        char = html[index]
        if in_str:
            if esc:
                esc = False
            elif char == "\\":
                esc = True
            elif char == '"':
                in_str = False
            continue
        if char == '"':
            in_str = True
        elif char == "[":
            depth += 1
        elif char == "]":
            depth -= 1
            if depth == 0:
                return json.loads(html[bracket:index + 1])
    raise RuntimeError(f"unclosed data array after {marker}")


def load_wowhead_ranks():
    ranks = {}
    for skill_id, slug in WH_SKILLS.items():
        url = f"https://www.wowhead.com/classic/skill={skill_id}/{slug}"
        html = fetch(url, f"skill-{skill_id}.html")
        rows = extract_json_array(html, 'id: "recipes"')
        print(f"wowhead {slug}: {len(rows)} recipes")
        for row in rows:
            spell = row.get("id")
            learned = row.get("learnedat")
            colors = row.get("colors") or []
            if not spell or learned in (None, 9999) or learned <= 0:
                continue
            ranks[int(spell)] = {
                "learned": int(learned),
                "colors": [int(c) for c in colors],
                "name": row.get("name") or "",
                "skill": skill_id,
            }
    return ranks


def load_era():
    path = os.path.join(CACHE, "SkillLineAbility-era.csv")
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        src = "/tmp/sla-era.csv"
        if os.path.exists(src) and os.path.getsize(src) > 0:
            with open(src, encoding="utf-8") as handle:
                text = handle.read()
            os.makedirs(CACHE, exist_ok=True)
            with open(path, "w", encoding="utf-8") as handle:
                handle.write(text)
        else:
            fetch(
                f"https://wago.tools/db2/SkillLineAbility/csv?build={ERA_BUILD}",
                "SkillLineAbility-era.csv",
            )
    by_spell = {}
    with open(path, encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            by_spell.setdefault(int(row["Spell"]), row)
    return by_spell


def side_from_react(react):
    """Wowhead react is [Alliance, Horde]. 1 friendly, -1 hostile."""
    if not react or len(react) < 2:
        return "Neutral"
    alliance, horde = react[0], react[1]
    if alliance == 1 and horde == -1:
        return "Alliance"
    if horde == 1 and alliance == -1:
        return "Horde"
    if alliance == 1 and horde == 1:
        return "Neutral"
    if alliance == 1 and horde is None:
        return "Alliance"
    if horde == 1 and alliance is None:
        return "Horde"
    return "Neutral"


def parse_faction(html):
    text = html.replace("\\/", "/").replace("\\]", "]")
    match = FACTION_RE.search(text)
    if not match:
        return None
    return int(match.group(1)), match.group(2).strip()


def load_vendor_prices(item_ids):
    """Neutral catalog price plus the factions whose vendors sell the item."""
    prices = {}

    def one(item_id):
        text = fetch(
            f"https://www.wowhead.com/classic/item={item_id}?xml",
            f"item-{item_id}.xml",
        )
        match = re.search(r'"buyprice":(\d+)', text)
        if not match:
            return item_id, None
        return item_id, int(match.group(1))

    ids = sorted(item_ids)
    print(f"vendor lookup for {len(ids)} items")
    with ThreadPoolExecutor(max_workers=8) as pool:
        futures = [pool.submit(one, item_id) for item_id in ids]
        done = 0
        for future in as_completed(futures):
            item_id, price = future.result()
            done += 1
            if price and price > 0:
                prices[item_id] = price
            if done % 100 == 0:
                print(f"  vendor {done}/{len(ids)}")
    print(f"vendor prices: {len(prices)}")

    sold = {}

    def sellers(item_id):
        html = fetch(
            f"https://www.wowhead.com/classic/item={item_id}/item",
            f"item-{item_id}.html",
        )
        rows = []
        for marker in ("id: 'sold-by'", 'id: "sold-by"'):
            if marker in html:
                try:
                    rows = extract_json_array(html, marker)
                except RuntimeError:
                    rows = []
                if rows:
                    break
        return item_id, rows

    print(f"sold-by pages for {len(prices)} vendor items")
    with ThreadPoolExecutor(max_workers=6) as pool:
        futures = [pool.submit(sellers, item_id) for item_id in prices]
        done = 0
        for future in as_completed(futures):
            item_id, rows = future.result()
            sold[item_id] = rows
            done += 1
            if done % 25 == 0:
                print(f"  sold-by {done}/{len(prices)}")

    npc_ids = {}
    for rows in sold.values():
        for row in rows:
            npc_id = row.get("id")
            if npc_id:
                npc_ids[int(npc_id)] = row
    print(f"unique vendor NPCs: {len(npc_ids)}")

    resolved = {}

    def npc_faction(npc_id):
        html = fetch(f"https://www.wowhead.com/classic/npc={npc_id}", f"npc-{npc_id}.html")
        return npc_id, parse_faction(html)

    with ThreadPoolExecutor(max_workers=6) as pool:
        futures = [pool.submit(npc_faction, npc_id) for npc_id in npc_ids]
        done = 0
        for future in as_completed(futures):
            npc_id, parsed = future.result()
            done += 1
            if parsed:
                faction_id, faction_name = parsed
                resolved[npc_id] = {
                    "faction": faction_id,
                    "name": faction_name,
                    "side": side_from_react(npc_ids[npc_id].get("react")),
                }
            if done % 50 == 0:
                print(f"  npc factions {done}/{len(npc_ids)}")
    print(f"npc factions resolved: {len(resolved)}")

    vendors = {}
    for item_id, price in prices.items():
        factions = {}
        for row in sold.get(item_id, []):
            info = resolved.get(int(row.get("id") or 0))
            if not info:
                continue
            factions[info["faction"]] = {
                "id": info["faction"],
                "name": info["name"],
                "side": info["side"],
            }
        vendors[item_id] = {"price": price, "factions": sorted(factions.values(), key=lambda f: f["id"])}
    return vendors, resolved


def lua_string(text):
    return '"' + (
        text.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
        .replace("\r", "")
    ) + '"'


def build():
    spell_names = {int(row["ID"]): row["Name_lang"] for row in read_csv("SpellName")}
    items = {int(row["ID"]): row for row in read_csv("ItemSparse")}
    reagents_by_spell = {int(row["SpellID"]): row for row in read_csv("SpellReagents")}
    effects = defaultdict(list)
    for row in read_csv("SpellEffect"):
        effects[int(row["SpellID"])].append(row)
    taught_by = defaultdict(list)
    effect_by_id = {int(row["ID"]): row for row in read_csv("ItemEffect")}
    for row in read_csv("ItemXItemEffect"):
        effect = effect_by_id.get(int(row["ItemEffectID"]))
        if not effect:
            continue
        spell_id = int(effect["SpellID"])
        # A recipe item's use-effect teaches the craft. Effect 36 (learn spell)
        # points at the taught spell via EffectTriggerSpell. Some rows store
        # the craft spell directly. Record both and resolve after we know crafts.
        trigger = None
        for spell_effect in effects.get(spell_id, []):
            if spell_effect["Effect"] == "36" and spell_effect["EffectTriggerSpell"] not in ("0", ""):
                trigger = int(spell_effect["EffectTriggerSpell"])
        taught_by[trigger or spell_id].append(int(row["ItemID"]))

    def item_name(item_id):
        row = items.get(item_id)
        if not row:
            return f"Item {item_id}"
        name = row["Display_lang"] or ""
        if not name or name == "None":
            return f"Item {item_id}"
        return name

    def spell_reagents(spell_id):
        row = reagents_by_spell.get(spell_id)
        if not row:
            return []
        found = []
        for index in range(8):
            raw = row[f"Reagent_{index}"]
            if raw in ("0", ""):
                continue
            count = int(row[f"ReagentCount_{index}"] or 0)
            if count > 0:
                found.append((int(raw), count))
        return found

    def product(spell_id):
        made_id = 0
        made_count = 0
        enchant = False
        for effect in effects.get(spell_id, []):
            if effect["Effect"] == "24" and effect["EffectItemType"] not in ("0", ""):
                made_id = int(effect["EffectItemType"])
                made_count = int(float(effect["EffectBasePointsF"] or 1))
                if made_count < 1:
                    made_count = 1
                return made_id, made_count, False
            if effect["Effect"] == "53":
                enchant = True
        return made_id, made_count, enchant

    wowhead = load_wowhead_ranks()
    era = load_era()
    abilities = []
    superseded = set()
    for row in read_csv("SkillLineAbility"):
        skill = int(row["SkillLine"])
        if skill not in PROF_IDS:
            continue
        spell_id = int(row["Spell"])
        if row["SupercedesSpell"] not in ("0", ""):
            superseded.add(int(row["SupercedesSpell"]))
        abilities.append(row)

    recipes = []
    skipped_stub = 0
    skipped_rank = 0
    sources = defaultdict(int)
    for row in abilities:
        spell_id = int(row["Spell"])
        if spell_id in superseded:
            continue
        skill = int(row["SkillLine"])
        forever_yellow = int(row["TrivialSkillLineRankLow"])
        forever_grey = int(row["TrivialSkillLineRankHigh"])
        forever_min = int(row["MinSkillLineRank"] or 0)
        ups = int(row["NumSkillUps"] or 0)
        if ups < 1:
            continue
        regs = spell_reagents(spell_id)
        made_id, made_count, enchant = product(spell_id)
        if not regs and made_id == 0:
            skipped_stub += 1
            continue
        name = spell_names.get(spell_id) or ""
        wh = wowhead.get(spell_id)
        era_row = era.get(spell_id)
        if (not name or name == "None") and wh:
            name = wh.get("name") or ""
        if (not name or name == "None") and made_id:
            name = item_name(made_id)
        if not name or name == "None":
            name = f"Spell {spell_id}"
        if wh and wh.get("colors") and len(wh["colors"]) >= 4:
            yellow = wh["colors"][1]
            grey = wh["colors"][3]
            green = wh["colors"][2]
            # colors[0] is the orange rank. Wowhead uses 0 as "not published"
            # and then copies the yellow rank into learnedat (Smelt Copper).
            # A recipe learned with the profession (acquire 1) still starts at 1.
            published = wh["colors"][0]
            learned = wh["learned"]
            acquire = int(row["AcquireMethod"] or 0)
            if era_row and acquire == 0:
                acquire = int(era_row.get("AcquireMethod") or 0)
            if published > 0:
                orange = published
            elif 0 < learned < yellow:
                orange = learned
            elif acquire == 1:
                orange = 1
            elif learned > 0:
                orange = learned
            else:
                orange = yellow if yellow > 0 else 1
            source = "wowhead"
            if yellow <= 0 and era_row and int(era_row["TrivialSkillLineRankHigh"] or 0) > 0:
                yellow = int(era_row["TrivialSkillLineRankLow"])
                grey = int(era_row["TrivialSkillLineRankHigh"])
                green = yellow if grey <= yellow else (yellow + grey) // 2
                era_min = int(era_row["MinSkillLineRank"] or 0)
                if 1 < era_min < grey:
                    orange = era_min
                elif acquire == 1:
                    orange = 1
                elif 0 < learned < grey:
                    orange = learned
                else:
                    orange = yellow if yellow > 0 else 1
                source = "era"
        elif era_row and int(era_row["TrivialSkillLineRankHigh"] or 0) > 0:
            yellow = int(era_row["TrivialSkillLineRankLow"])
            grey = int(era_row["TrivialSkillLineRankHigh"])
            green = yellow if grey <= yellow else (yellow + grey) // 2
            era_min = int(era_row["MinSkillLineRank"] or 0)
            if 1 < era_min < grey:
                orange = era_min
                source = "era"
            else:
                orange = yellow if yellow > 0 else 1
                source = "era-yellow"
        elif forever_grey > 0:
            yellow = forever_yellow
            grey = forever_grey
            green = yellow if grey <= yellow else (yellow + grey) // 2
            if 1 < forever_min < grey:
                orange = forever_min
                source = "forever"
            else:
                orange = yellow if yellow > 0 else 1
                source = "forever-yellow"
        else:
            skipped_rank += 1
            continue
        if orange < 1:
            orange = 1
        if yellow < 1 and grey > orange:
            yellow = orange
        if grey <= 0:
            skipped_rank += 1
            continue
        skillup = orange < grey and grey >= yellow
        if not skillup and not (made_id and regs):
            skipped_rank += 1
            continue
        class_mask = int(row["ClassMask"] or 0)
        race_mask = int(row["RaceMasks_0"] or 0)
        teachers = taught_by.get(spell_id) or []
        teacher = teachers[0] if teachers else 0
        sources[source] += 1
        recipes.append({
            "spell": spell_id,
            "skill": skill,
            "name": name,
            "orange": orange,
            "yellow": yellow,
            "green": green,
            "grey": grey,
            "ups": ups,
            "made": made_id,
            "count": made_count if made_id else 0,
            "enchant": enchant,
            "reagents": regs,
            "acquire": int(row["AcquireMethod"] or 0),
            "classMask": class_mask,
            "raceMask": race_mask,
            "rankSource": source,
            "skillup": skillup,
            "taught": teacher,
        })

    recipes.sort(key=lambda recipe: (recipe["skill"], recipe["orange"], recipe["yellow"], recipe["spell"]))
    print(f"recipes {len(recipes)} skipped stubs {skipped_stub} skipped ranks {skipped_rank}")
    print("rank sources", dict(sources))
    by_skill = defaultdict(int)
    by_source = defaultdict(lambda: defaultdict(int))
    for recipe in recipes:
        by_skill[recipe["skill"]] += 1
        by_source[recipe["skill"]][recipe["rankSource"]] += 1
    for skill, name, _secondary, _gathering in PROFESSIONS:
        print(f"  {name}: {by_skill[skill]} {dict(by_source[skill])}")

    reagent_ids = set()
    item_ids = set()
    for recipe in recipes:
        if recipe["made"]:
            item_ids.add(recipe["made"])
        if recipe["taught"]:
            item_ids.add(recipe["taught"])
        for item_id, _count in recipe["reagents"]:
            reagent_ids.add(item_id)
            item_ids.add(item_id)
    vendors, npcs = load_vendor_prices(reagent_ids)
    names = {item_id: item_name(item_id) for item_id in sorted(item_ids)}
    if 3371 in vendors:
        print("empty vial factions", vendors[3371])

    sell = load_sell_prices(item_ids)
    write_lua(recipes, names, vendors, npcs)
    write_json(recipes, names, vendors, npcs, sell)
    print("wrote Data.lua and recipes.json")


def load_sell_prices(item_ids):
    """Vendor sell price from ItemSparse.SellPrice, in copper. Used by the shuffle sheet."""
    prices = {}
    for row in read_csv("ItemSparse"):
        item_id = int(row["ID"])
        if item_id not in item_ids:
            continue
        try:
            prices[item_id] = int(row.get("SellPrice") or 0)
        except ValueError:
            continue
    return prices


def write_json(recipes, names, vendors, npcs, sell=None):
    payload = {
        "build": BUILD,
        "eraBuild": ERA_BUILD,
        "professions": [
            {"id": skill, "name": name, "secondary": secondary, "gathering": gathering}
            for skill, name, secondary, gathering in PROFESSIONS
        ],
        "items": {str(item_id): name for item_id, name in names.items()},
        "vendor": {
            str(item_id): {"price": entry["price"], "factions": entry["factions"]}
            for item_id, entry in sorted(vendors.items())
        },
        "npcs": {
            str(npc_id): info for npc_id, info in sorted(npcs.items())
        },
        "sell": {str(item_id): price for item_id, price in sorted((sell or {}).items())},
        "recipes": [
            {
                "spell": recipe["spell"],
                "skill": recipe["skill"],
                "name": recipe["name"],
                "orange": recipe["orange"],
                "yellow": recipe["yellow"],
                "green": recipe["green"],
                "grey": recipe["grey"],
                "ups": recipe["ups"],
                "made": recipe["made"],
                "count": recipe["count"],
                "enchant": recipe["enchant"],
                "reagents": recipe["reagents"],
                "acquire": recipe["acquire"],
                "classMask": recipe["classMask"],
                "raceMask": recipe["raceMask"],
                "rankSource": recipe["rankSource"],
                "skillup": recipe["skillup"],
                "taught": recipe["taught"],
            }
            for recipe in recipes
        ],
    }
    path = os.path.join(HERE, "recipes.json")
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, separators=(",", ":"))
        handle.write("\n")


def write_text(path, lines):
    with open(path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines))
        handle.write("\n")


def chunks(rows, size):
    rows = list(rows)
    return [rows[i:i + size] for i in range(0, len(rows), size)] or [[]]


def recipe_line(recipe):
    regs = ",".join("{%d,%d}" % pair for pair in recipe["reagents"])
    ench = "true" if recipe["enchant"] else "false"
    skillup = "true" if recipe["skillup"] else "false"
    return (
        "  { spell = %d, skill = %d, name = %s, orange = %d, yellow = %d, green = %d, grey = %d, ups = %d, made = %d, count = %d, enchant = %s, reagents = {%s}, acquire = %d, classMask = %d, raceMask = %d, rankSource = %s, skillup = %s, taught = %d },"
        % (
            recipe["spell"], recipe["skill"], lua_string(recipe["name"]),
            recipe["orange"], recipe["yellow"], recipe["green"], recipe["grey"],
            recipe["ups"], recipe["made"], recipe["count"], ench, regs,
            recipe["acquire"], recipe["classMask"], recipe["raceMask"],
            lua_string(recipe["rankSource"]), skillup, recipe["taught"],
        )
    )


def update_toc(data_files):
    path = os.path.join(ADDON, "SkillLedger.toc")
    text = open(path, encoding="utf-8").read()
    block = "## DATA-BEGIN\n" + "".join(name + "\n" for name in data_files) + "## DATA-END\n"
    begin = text.find("## DATA-BEGIN\n")
    end = text.find("## DATA-END\n")
    if begin >= 0 and end > begin:
        end += len("## DATA-END\n")
        text = text[:begin] + block + text[end:]
    else:
        text = text.replace("Init.lua\n", "Init.lua\n" + block, 1)
    text = text.replace("## DATA-END\nData.lua\n", "## DATA-END\n")
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text)


def write_lua(recipes, names, vendors, npcs):
    # Drop previously generated parts so a smaller split does not leave stale files.
    for name in os.listdir(ADDON):
        if name == "Data.lua" or (name.startswith("Data") and name.endswith(".lua")):
            os.remove(os.path.join(ADDON, name))

    header = [
        "-- SkillLedger recipe data. Generated by tools/build_data.py. Do not edit by hand.",
        f"-- Reagents and products: Forever client build {BUILD} (wago.tools, product wowf).",
        f"-- Yellow and grey: Wowhead Classic, else Classic Era SkillLineAbility {ERA_BUILD}.",
        "-- This global is SkillLedgerData. It is not local: a local would not be visible",
        "-- to the other addon files. The tables are split so each file stays under WoW's",
        "-- per-chunk constant limit.",
        "SkillLedgerData = {",
        f"  build = {lua_string(BUILD)},",
        f"  eraBuild = {lua_string(ERA_BUILD)},",
        "  cap = 300,",
        "  professions = {",
    ]
    for skill, name, secondary, gathering in PROFESSIONS:
        header.append(
            "    { id = %d, name = %s, secondary = %s, gathering = %s },"
            % (skill, lua_string(name), "true" if secondary else "false", "true" if gathering else "false")
        )
    header += [
        "  },",
        "  items = {},",
        "  vendor = {},",
        "  npcs = {},",
        "  recipes = {},",
        "}",
    ]
    files = ["Data.lua"]
    write_text(os.path.join(ADDON, "Data.lua"), header)

    item_rows = sorted(names.items())
    for index, group in enumerate(chunks(item_rows, 800), start=1):
        name = "DataItems%02d.lua" % index
        lines = ["local add = {"]
        for item_id, item_name in group:
            lines.append("  [%d] = %s," % (item_id, lua_string(item_name)))
        lines += [
            "}",
            "local items = SkillLedgerData.items",
            "for id, name in pairs(add) do items[id] = name end",
        ]
        write_text(os.path.join(ADDON, name), lines)
        files.append(name)

    vendor_lines = ["local add = {"]
    for item_id, entry in sorted(vendors.items()):
        bits = ",".join(
            "{ id = %d, name = %s, side = %s }"
            % (faction["id"], lua_string(faction["name"]), lua_string(faction["side"]))
            for faction in entry["factions"]
        )
        vendor_lines.append("  [%d] = { price = %d, factions = { %s } }," % (item_id, entry["price"], bits))
    vendor_lines += [
        "}",
        "local vendor = SkillLedgerData.vendor",
        "for id, row in pairs(add) do vendor[id] = row end",
    ]
    write_text(os.path.join(ADDON, "DataVendor.lua"), vendor_lines)
    files.append("DataVendor.lua")

    npc_rows = sorted(npcs.items())
    for index, group in enumerate(chunks(npc_rows, 200), start=1):
        name = "DataNpcs%02d.lua" % index
        lines = ["local add = {"]
        for npc_id, info in group:
            lines.append(
                "  [%d] = { faction = %d, name = %s, side = %s },"
                % (npc_id, info["faction"], lua_string(info["name"]), lua_string(info["side"]))
            )
        lines += [
            "}",
            "local npcs = SkillLedgerData.npcs",
            "for id, row in pairs(add) do npcs[id] = row end",
        ]
        write_text(os.path.join(ADDON, name), lines)
        files.append(name)

    for index, group in enumerate(chunks(recipes, 300), start=1):
        name = "DataRecipes%02d.lua" % index
        lines = ["local add = {"]
        for recipe in group:
            lines.append(recipe_line(recipe))
        lines += [
            "}",
            "local list = SkillLedgerData.recipes",
            "for i = 1, #add do list[#list + 1] = add[i] end",
        ]
        write_text(os.path.join(ADDON, name), lines)
        files.append(name)

    update_toc(files)
    print("lua data files", len(files))


if __name__ == "__main__":
    build()
