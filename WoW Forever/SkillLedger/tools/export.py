#!/usr/bin/env python3
"""Turn SkillLedger SavedVariables into an Excel workbook, or CSV files.

Usage:
  export.py SavedVariables\\SkillLedger.lua
  export.py --account "C:\\World of Warcraft\\_forever_\\WTF\\Account\\NAME"
  export.py
  export.bat -o "%USERPROFILE%\\Desktop\\SkillLedger.xlsx"

With no .lua path, the newest SkillLedger.lua under a _forever_ install is used.
The workbook defaults to Desktop\\SkillLedger.xlsx. A non-.lua path is rejected.

Log out of WoW, or /reload, before running this. The game writes
SavedVariables on logout and reload. The addon cannot write the file itself.

openpyxl is optional. Without it, or with --csv, the script writes one CSV
per sheet.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import sys
from datetime import datetime, timezone

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import plan  # noqa: E402


class LuaError(ValueError):
    pass


class LuaParser:
    def __init__(self, text):
        if text.startswith("\ufeff"):
            text = text[1:]
        self.s = text
        self.n = len(text)
        self.i = 0

    def peek(self):
        return self.s[self.i] if self.i < self.n else ""

    def skip(self):
        while self.i < self.n:
            char = self.s[self.i]
            if char in " \t\r\n,;":
                self.i += 1
                continue
            if char == "-" and self.s.startswith("--", self.i):
                self.i += 2
                if self.s.startswith("[[", self.i):
                    end = self.s.find("]]", self.i + 2)
                    self.i = self.n if end < 0 else end + 2
                else:
                    end = self.s.find("\n", self.i)
                    self.i = self.n if end < 0 else end + 1
                continue
            return

    def parse_file(self):
        values = {}
        while True:
            self.skip()
            if self.i >= self.n:
                break
            name = self.ident()
            self.skip()
            if self.peek() != "=":
                raise LuaError(f"expected = after {name}")
            self.i += 1
            values[name] = self.value()
        return values

    def ident(self):
        self.skip()
        start = self.i
        while self.i < self.n and (self.s[self.i].isalnum() or self.s[self.i] == "_"):
            self.i += 1
        if start == self.i:
            raise LuaError(f"expected a name at {self.i}")
        return self.s[start:self.i]

    def value(self):
        self.skip()
        char = self.peek()
        if char == "{":
            return self.table()
        if char == '"' or char == "'":
            return self.string()
        if char == "-" or char.isdigit():
            return self.number()
        word = self.ident()
        if word == "true":
            return True
        if word == "false":
            return False
        if word == "nil":
            return None
        raise LuaError(f"unexpected {word}")

    def string(self):
        quote = self.s[self.i]
        self.i += 1
        out = []
        while self.i < self.n:
            char = self.s[self.i]
            if char == "\\":
                self.i += 1
                esc = self.s[self.i] if self.i < self.n else ""
                out.append({"n": "\n", "r": "\r", "t": "\t", "\\": "\\", '"': '"', "'": "'"}.get(esc, esc))
                self.i += 1
                continue
            if char == quote:
                self.i += 1
                return "".join(out)
            out.append(char)
            self.i += 1
        raise LuaError("unterminated string")

    def number(self):
        start = self.i
        if self.peek() == "-":
            self.i += 1
        while self.i < self.n and (self.s[self.i].isdigit() or self.s[self.i] in ".eE+-"):
            # stop a second sign that is not part of an exponent
            if self.s[self.i] in "+-" and self.s[self.i - 1] not in "eE":
                break
            self.i += 1
        text = self.s[start:self.i]
        if text in ("-", "", ".", "-."):
            raise LuaError(f"bad number {text}")
        if any(mark in text for mark in ".eE"):
            return float(text)
        return int(text)

    def table(self):
        self.i += 1  # {
        array = []
        mapping = {}
        while True:
            self.skip()
            if self.peek() == "}":
                self.i += 1
                break
            if self.peek() == "":
                raise LuaError("unterminated table")
            if self.peek() == "[":
                self.i += 1
                key = self.value()
                self.skip()
                if self.peek() != "]":
                    raise LuaError("expected ]")
                self.i += 1
                self.skip()
                if self.peek() != "=":
                    raise LuaError("expected =")
                self.i += 1
                mapping[key] = self.value()
            else:
                mark = self.i
                if self.peek().isalpha() or self.peek() == "_":
                    name = self.ident()
                    self.skip()
                    if self.peek() == "=":
                        self.i += 1
                        mapping[name] = self.value()
                    else:
                        self.i = mark
                        array.append(self.value())
                else:
                    array.append(self.value())
            self.skip()
        if mapping and array:
            for index, value in enumerate(array, start=1):
                mapping.setdefault(index, value)
            return mapping
        if mapping:
            return mapping
        return array


# Excel allows two conditions plus a fallback. Silver and copper are the last
# two digits, so 1234567 is 123g 45s 67c, 1205 is 12s 05c, and 42 is 42c.
# A negative number is also < 100, so it must not use that first section:
# Excel would drop the minus and a loss would look like a profit. Losses use
# a second format, applied by a conditional rule, with the same split in red.
COIN_FORMAT = '[<100]0"c";[>9999]#"g "00"s "00"c";0"s "00"c"'
NEG_COIN_FORMAT = '[<=-10000]-#"g "00"s "00"c";[<=-100]-0"s "00"c";-0"c"'
MONEY_HEADERS = {
    "Min buyout / unit", "Copper", "Cost", "Running total", "Base unit",
    "Unit paid", "Line cost", "Base", "Reagent cost", "AH price", "Profit",
    "Spend", "Cost to cap", "Vendor Sell", "AH Net", "Market Value", "Expected / day",
}


def coins(value):
    """Copper as an int, so a sheet can sort, sum, and chart it. Blank if unknown."""
    if value is None or value == "":
        return ""
    return int(plan.iround(value))


def money(copper):
    """Text form, kept for notes. Sheet cells store coins() instead."""
    if copper is None or copper == "":
        return ""
    copper = int(plan.iround(copper))
    sign = "-" if copper < 0 else ""
    copper = abs(copper)
    gold, rem = divmod(copper, 10000)
    silver, coppers = divmod(rem, 100)
    if gold:
        text = f"{gold}g {silver:02d}s {coppers:02d}c"
    elif silver:
        text = f"{silver}s {coppers:02d}c"
    else:
        text = f"{coppers}c"
    return sign + text


def stamp(value):
    if not value:
        return ""
    try:
        return datetime.fromtimestamp(int(value), timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    except (TypeError, ValueError, OSError):
        return str(value)


def as_list(value):
    if value is None:
        return []
    if isinstance(value, list):
        return value
    if isinstance(value, dict):
        rows = []
        for key in sorted(value, key=lambda item: (isinstance(item, str), item)):
            row = value[key]
            if isinstance(row, dict):
                rows.append(row)
        return rows
    return []


def load_saved(path):
    if not str(path).lower().endswith(".lua"):
        raise SystemExit(non_lua_message(path))
    try:
        with open(path, encoding="utf-8") as handle:
            text = handle.read()
    except OSError as exc:
        raise SystemExit(f"Could not read {path}: {exc}")
    try:
        parsed = LuaParser(text).parse_file()
    except LuaError as exc:
        raise SystemExit(
            f"Could not read {path}: {exc}. "
            "Log out or type /reload in game so WoW finishes writing "
            "SavedVariables\\SkillLedger.lua, then run this again."
        )
    db = parsed.get("SkillLedgerDB")
    if not isinstance(db, dict):
        raise SystemExit(
            f"{path} has no SkillLedgerDB table. "
            "Log out or type /reload in game so WoW writes "
            "SavedVariables\\SkillLedger.lua, then run this again."
        )
    return db


def load_recipes():
    path = os.path.join(HERE, "recipes.json")
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def index_rows(rows, key="id"):
    out = {}
    for row in as_list(rows):
        if isinstance(row, dict) and row.get(key) is not None:
            out[int(row[key])] = row
    return out


def character_rows(db):
    chars = db.get("chars") or {}
    if isinstance(chars, list):
        return chars
    rows = []
    for key, value in chars.items():
        if isinstance(value, dict):
            value = dict(value)
            value.setdefault("key", key)
            rows.append(value)
    rows.sort(key=lambda row: str(row.get("key") or ""))
    return rows


CLASS_BIT = {
    "WARRIOR": 1, "PALADIN": 2, "HUNTER": 4, "ROGUE": 8, "PRIEST": 16,
    "DEATHKNIGHT": 32, "SHAMAN": 64, "MAGE": 128, "WARLOCK": 256, "DRUID": 1024,
}
RACE_BIT = {
    "Human": 1, "Orc": 2, "Dwarf": 4, "NightElf": 8, "Scourge": 16,
    "Tauren": 32, "Gnome": 64, "Troll": 128, "BloodElf": 512, "Draenei": 1024,
}


def inventory_of(char):
    totals = {}
    for bucket in ("bags", "bank"):
        block = char.get(bucket) or {}
        for row in as_list(block.get("items") if isinstance(block, dict) else None):
            if not isinstance(row, dict) or not row.get("id"):
                continue
            totals[int(row["id"])] = totals.get(int(row["id"]), 0) + int(row.get("count") or 0)
    return totals


def prices_of(db):
    prices, sources = {}, {}
    block = db.get("prices") or {}
    for row in as_list(block.get("items") if isinstance(block, dict) else None):
        if isinstance(row, dict) and row.get("id") and row.get("unit"):
            prices[int(row["id"])] = int(row["unit"])
            sources[int(row["id"])] = row.get("source") or "scan"
    return prices, sources


def standings_of(char):
    block = char.get("standings") or {}
    out = {}
    for row in as_list(block.get("factions") if isinstance(block, dict) else None):
        if isinstance(row, dict) and row.get("id") is not None and row.get("standing") is not None:
            out[int(row["id"])] = int(row["standing"])
    return out


def captured_of(char):
    block = char.get("merchant") or {}
    out = {}
    for row in as_list(block.get("rows") if isinstance(block, dict) else None):
        if not isinstance(row, dict) or not row.get("id") or not row.get("unit"):
            continue
        item_id = int(row["id"])
        unit = int(row["unit"])
        current = out.get(item_id)
        if current is None or unit < current["unit"]:
            out[item_id] = {
                "unit": unit,
                "factionId": int(row["factionId"]) if row.get("factionId") else None,
                "faction": row.get("faction") or "",
                "standingId": int(row["standing"]) if row.get("standing") is not None else None,
            }
    return out


def build_report(db, data):
    prices, sources = prices_of(db)
    report = []
    for char in character_rows(db):
        professions = []
        for row in as_list(char.get("professions")):
            if isinstance(row, dict):
                professions.append({
                    "name": row.get("name"),
                    "skillLine": int(row["skillLine"]) if row.get("skillLine") else None,
                    "rank": int(row.get("rank") or 0),
                    "maxRank": int(row.get("maxRank") or 0),
                })
        plans, shopping = plan.plan_character(
            data,
            inventory_of(char),
            professions,
            prices,
            standings_of(char),
            captured_of(char),
            char.get("faction") or "",
            CLASS_BIT.get(char.get("classFile") or "", 0),
            RACE_BIT.get(char.get("race") or "", 0),
            sources,
        )
        report.append({"char": char, "plans": plans, "shopping": shopping})
    return report


TRADE_GOODS_CLASS = 7
LEARNED_NOTE = (
    "Open each profession window once so SkillLedger can record the recipes you have learned, "
    "then rescan the auction house."
)


def reagent_ids(data):
    found = set()
    for recipe in data.get("recipes") or []:
        for reagent in recipe.get("reagents") or []:
            if reagent:
                found.add(int(reagent[0]))
    return found


def is_crafting_item(item, reagents):
    if not isinstance(item, dict) or not item.get("id"):
        return False
    if int(item["id"]) in reagents:
        return True
    class_id = item.get("classId")
    if class_id is None:
        class_id = item.get("classID")
    if class_id is not None:
        try:
            if int(class_id) == TRADE_GOODS_CLASS:
                return True
        except (TypeError, ValueError):
            pass
    kind = str(item.get("class") or item.get("itemClass") or "").strip().lower()
    return kind == "trade goods"


def profession_rows(db):
    # Secondary is a yes/no flag on each row, so Cooking, First Aid and Fishing
    # are left off this sheet. The flag column goes with them. Summary still
    # shows those professions.
    rows = [["Character", "Faction", "Class", "Level", "Profession", "Rank", "Max"]]
    for char in character_rows(db):
        profs = as_list(char.get("professions")) or [{}]
        for row in profs:
            if not isinstance(row, dict) or row.get("secondary"):
                continue
            rows.append([
                char.get("name") or char.get("key"),
                char.get("faction") or "",
                char.get("classFile") or char.get("class") or "",
                char.get("level") or "",
                row.get("name") or "",
                row.get("rank") or "",
                row.get("maxRank") or "",
            ])
    return rows


def inventory_rows(db, data):
    rows = [["Character", "Item ID", "Name", "Count", "Location"]]
    reagents = reagent_ids(data)
    for char in character_rows(db):
        totals = {}
        for bucket, label in (("bags", "Bags"), ("bank", "Bank")):
            block = char.get(bucket) or {}
            for item in as_list(block.get("items") if isinstance(block, dict) else None):
                if not is_crafting_item(item, reagents):
                    continue
                item_id = int(item["id"])
                slot = totals.setdefault(item_id, {"name": item.get("name") or "", "bags": 0, "bank": 0})
                if item.get("name"):
                    slot["name"] = item["name"]
                slot["bags" if bucket == "bags" else "bank"] += int(item.get("count") or 0)
        ordered = sorted(totals.items(), key=lambda pair: (pair[1]["name"].lower(), pair[0]))
        for item_id, slot in ordered:
            parts = []
            if slot["bags"]:
                parts.append(f"Bags {slot['bags']}")
            if slot["bank"]:
                parts.append(f"Bank {slot['bank']}")
            rows.append([
                char.get("name") or char.get("key"),
                item_id,
                slot["name"],
                slot["bags"] + slot["bank"],
                " / ".join(parts),
            ])
    return rows


def price_rows(db):
    rows = [["Item ID", "Name", "Min buyout / unit", "Copper", "Qty at min", "Total listed", "Source", "Scanned"]]
    block = db.get("prices") or {}
    for item in as_list(block.get("items") if isinstance(block, dict) else None):
        if not isinstance(item, dict):
            continue
        unit = item.get("unit") or 0
        rows.append([
            item.get("id"),
            item.get("name") or "",
            coins(unit) if unit else "",
            unit,
            item.get("qty") or 0,
            item.get("total") or 0,
            item.get("source") or "",
            stamp(item.get("at") or block.get("updated")),
        ])
    return rows


def plan_rows(report):
    rows = [[
        "Character", "Profession", "Skill from", "Skill to", "Recipe", "Color",
        "Crafts", "Reagents to buy", "Vendor discount", "Cost", "Running total", "Notes",
    ]]
    for entry in report:
        name = entry["char"].get("name") or entry["char"].get("key")
        for profession in entry["plans"]:
            rows.append([name, profession["name"], "", "", "", "", "", "", "", coins(profession["total"]), "", " | ".join(profession["notes"])])
            for step in profession["steps"]:
                bits = []
                for reagent in step["reagents"]:
                    piece = reagent["name"]
                    if reagent["fromStock"] > 0.05:
                        piece += f" {reagent['fromStock']:.1f} from bags"
                    if reagent["buy"] > 0.05:
                        piece += f" buy {reagent['buy']:.1f}"
                    bits.append(piece)
                rows.append([
                    name,
                    profession["name"],
                    step["start"],
                    step["end"],
                    step["recipe"],
                    step["color"],
                    round(step["crafts"], 2),
                    "; ".join(bits),
                    "; ".join(step["discounts"]),
                    coins(step["cost"]),
                    coins(step["running"]),
                    "; ".join(step["notes"] + [f"no price: {item}" for item in step["unpriced"]]),
                ])
    return rows


def shopping_rows(report):
    rows = [[
        "Character", "Item", "Need", "From bags", "Buy",
        "Base unit", "Discount", "Faction", "Standing", "Unit paid", "Line cost", "Source",
    ]]
    for entry in report:
        name = entry["char"].get("name") or entry["char"].get("key")
        for row in entry["shopping"]:
            if row["need"] <= 0.001:
                continue
            rows.append([
                name,
                row["name"],
                round(row["need"], 2),
                round(row["fromStock"], 2),
                row["buyWhole"],
                coins(row["base"]) if row.get("base") else "",
                f"{row['discount']}%" if row.get("discount") else "",
                row.get("faction") or "",
                row.get("standing") or "",
                coins(row["unit"]) if row.get("unit") else "",
                coins(row["cost"]) if row.get("cost") else "",
                row.get("source") or "",
            ])
    return rows


def vendor_rows(db, report):
    rows = [["Section", "Character", "Faction", "Standing", "Discount", "Item", "Base", "Unit paid", "When", "Note"]]
    for char in character_rows(db):
        name = char.get("name") or char.get("key")
        block = char.get("standings") or {}
        for row in as_list(block.get("factions") if isinstance(block, dict) else None):
            if not isinstance(row, dict):
                continue
            standing = int(row.get("standing") or 0)
            rows.append([
                "Standing", name, row.get("name") or "",
                plan.standing_name(standing), f"{plan.discount_percent(standing)}%",
                "", "", "", stamp(block.get("updated") if isinstance(block, dict) else None),
                "Unfriendly and below cannot buy. Neutral pays the catalog price.",
            ])
        merchant = char.get("merchant") or {}
        for row in as_list(merchant.get("rows") if isinstance(merchant, dict) else None):
            if not isinstance(row, dict):
                continue
            standing = row.get("standing")
            rows.append([
                "Merchant window", name, row.get("faction") or "",
                plan.standing_name(int(standing)) if standing else "",
                f"{plan.discount_percent(int(standing))}%" if standing else "",
                row.get("name") or "",
                "", coins(row.get("unit")), stamp(row.get("at")),
                "Captured from the merchant window. Used as-is while this standing is unchanged.",
            ])
    for entry in report:
        name = entry["char"].get("name") or entry["char"].get("key")
        seen = set()
        for row in entry["shopping"]:
            if not row.get("base") and row.get("source") not in ("vendor", "vendor-assumed", "vendor-nofaction", "merchant"):
                continue
            key = (row["id"], row.get("faction"), row.get("source"))
            if key in seen:
                continue
            seen.add(key)
            rows.append([
                "Plan price", name, row.get("faction") or "",
                row.get("standing") or "",
                f"{row['discount']}%" if row.get("discount") else "0%",
                row["name"],
                coins(row.get("base")) if row.get("base") else "",
                coins(row.get("unit")) if row.get("unit") else "",
                "",
                "Standing was not saved, so Neutral was assumed." if row.get("assumed") else row.get("source") or "",
            ])
    return rows


def price_index(db):
    out = {}
    block = db.get("prices") or {}
    for row in as_list(block.get("items") if isinstance(block, dict) else None):
        if isinstance(row, dict) and row.get("id") is not None:
            out[int(row["id"])] = row
    return out


def learned_recipes(char):
    block = char.get("learned") or {}
    rows = as_list(block.get("recipes") if isinstance(block, dict) else block)
    if not rows and isinstance(block, dict):
        rows = as_list(block.get("spells"))
    found = []
    for row in rows:
        if isinstance(row, int):
            found.append({"spell": row})
        elif isinstance(row, dict) and (row.get("spell") or row.get("name")):
            found.append(row)
    return found


# 12-hour auction deposit is 15% of the vendor sell price. The 5% cut is not returned.
AH_CUT_PERCENT = 5
DEPOSIT_PERCENT = 15
THIN_MARKET = 5
SHUFFLE_HEADER = [
    "Character", "Item", "Profession", "Reagents", "Cost", "Vendor Sell", "AH Net",
    "Best Channel", "Profit", "Margin %", "AH Qty Listed", "Can Make Now",
    "Sale Rate", "Sold/Day", "Market Value", "Confidence", "Expected / day",
]


def sell_price(data, item_id):
    table = data.get("sell") or {}
    raw = table.get(str(item_id), table.get(item_id))
    if raw is None:
        return 0
    try:
        return int(raw)
    except (TypeError, ValueError):
        return 0


def ah_proceeds(unit_buyout, produced, sell_each):
    """Copper kept after the 5% cut and a 12-hour deposit. None when nothing is listed."""
    if not unit_buyout or unit_buyout <= 0 or produced <= 0:
        return None
    gross = int(unit_buyout) * produced
    cut = gross * AH_CUT_PERCENT // 100
    deposit = int(sell_each) * produced * DEPOSIT_PERCENT // 100
    return gross - cut - deposit


def cheapest_reagent(state, item_id, owned, need):
    """Cheapest of vendor, auction, or owned-at-auction opportunity cost.

    Owned stock is not free: using it costs the auction price you could have sold
    it for. Vendor wins a tie because that price is guaranteed. Owned wins a tie
    with the auction house when the bags already hold enough.
    """
    vendor_unit, _info = plan.vendor_quote(state, item_id)
    auction = state["prices"].get(item_id)
    options = []
    if vendor_unit is not None:
        options.append((int(vendor_unit), 0, "vendor"))
    if auction:
        options.append((int(auction), 2, "AH"))
    if owned >= need and auction:
        options.append((int(auction), 1, "owned"))
    if not options:
        return None
    _price, _rank, source = min(options)
    unit = next(price for price, _rank, name in options if name == source)
    return source, unit


def can_make_now(recipe, inventory, vendor_available):
    """How many crafts owned stacks plus vendor reagents can cover. 'any' if none are scarce."""
    limit = None
    for reagent_id, count in recipe.get("reagents") or []:
        count = int(count or 0)
        if count <= 0:
            continue
        if vendor_available(int(reagent_id)):
            continue
        owned = int(inventory.get(int(reagent_id), 0))
        crafts = owned // count
        limit = crafts if limit is None else min(limit, crafts)
    if limit is None:
        return "any"
    return limit


def craft_quotes(db, data):
    """Learned crafts that sell for more than their cheapest reagents."""
    recipes_by_spell = {}
    for recipe in data.get("recipes") or []:
        recipes_by_spell[int(recipe["spell"])] = recipe
    skill_names = {int(row["id"]): row["name"] for row in data.get("professions") or [] if row.get("id")}
    quotes = []
    any_learned = False
    for char in character_rows(db):
        learned = learned_recipes(char)
        if not learned:
            continue
        any_learned = True
        state = plan.prepare_state(
            data,
            inventory_of(char),
            prices_of(db)[0],
            standings_of(char),
            captured_of(char),
            char.get("faction") or "",
            CLASS_BIT.get(char.get("classFile") or "", 0),
            RACE_BIT.get(char.get("race") or "", 0),
            prices_of(db)[1],
        )
        listing = price_index(db)
        inventory = inventory_of(char)

        def vendor_available(item_id, state=state):
            unit, _info = plan.vendor_quote(state, item_id)
            return unit is not None

        for known in learned:
            spell = known.get("spell")
            recipe = recipes_by_spell.get(int(spell)) if spell else None
            if recipe is None or recipe.get("enchant") or not recipe.get("made"):
                continue
            bits = []
            cost = 0
            sources = []
            priced = True
            for reagent_id, count in recipe.get("reagents") or []:
                reagent_id = int(reagent_id)
                count = int(count or 0)
                if count <= 0:
                    continue
                owned = int(inventory.get(reagent_id, 0))
                choice = cheapest_reagent(state, reagent_id, owned, count)
                name = (data.get("items") or {}).get(str(reagent_id)) or (data.get("items") or {}).get(reagent_id) or f"Item {reagent_id}"
                if choice is None:
                    priced = False
                    bits.append(f"{name} x{count} unpriced (own {owned})")
                    continue
                source, unit = choice
                cost += unit * count
                sources.append(source)
                bits.append(f"{name} x{count} {source} {money(unit)} (own {owned})")
            if not priced:
                continue
            made = int(recipe.get("made") or known.get("item") or 0)
            produced = int(recipe.get("count") or 1) or 1
            sell_each = sell_price(data, made)
            vendor_sell = sell_each * produced
            sale_row = listing.get(made) or {}
            buyout = int(sale_row.get("unit") or 0)
            auction_net = ah_proceeds(buyout, produced, sell_each)
            listed = int(sale_row.get("total") or sale_row.get("qty") or 0) if buyout else None
            channels = []
            if vendor_sell > 0:
                channels.append(("Vendor", vendor_sell))
            if auction_net is not None:
                channels.append(("AH", auction_net))
            if not channels:
                continue
            best_name, best_net = max(channels, key=lambda pair: (pair[1], 0 if pair[0] == "Vendor" else 1))
            profit = best_net - cost
            if profit <= 0:
                continue
            vendor_profit = vendor_sell - cost
            risk_free = bool(sources) and all(source == "vendor" for source in sources) and vendor_profit > 0 and best_name == "Vendor"
            profession = known.get("profession") or skill_names.get(int(recipe.get("skill") or 0)) or ""
            quotes.append({
                "character": char.get("name") or char.get("key"),
                "item": known.get("name") or recipe.get("name") or "",
                "profession": profession,
                "reagents": "; ".join(bits),
                "cost": cost,
                "vendor_sell": vendor_sell,
                "ah_net": auction_net,
                "channel": best_name,
                "profit": profit,
                "margin": round(100 * profit / best_net) if best_net else 0,
                "listed": listed,
                "thin": listed is not None and 0 < listed < THIN_MARKET,
                "can_make": can_make_now(recipe, inventory, vendor_available),
                "risk_free": risk_free,
                "made": made,
            })
    attach_market(db, quotes)
    has_velocity = any(row.get("sold_per_day") is not None for row in quotes)
    if has_velocity:
        quotes.sort(key=lambda row: (-(row["expected"] or 0), -row["profit"], row["item"]))
    else:
        quotes.sort(key=lambda row: (-row["profit"], row["item"]))
    return quotes, any_learned


def sale_rate_percent(raw):
    if raw is None or raw == "":
        return None
    try:
        value = float(raw)
    except (TypeError, ValueError):
        return None
    if 0 <= value <= 1:
        return value * 100
    return value


def age_text(seconds):
    if seconds is None or seconds == "":
        return ""
    try:
        seconds = int(seconds)
    except (TypeError, ValueError):
        return ""
    if seconds < 3600:
        return f"{max(1, seconds // 60)}m"
    if seconds < 86400:
        return f"{max(1, seconds // 3600)}h"
    return f"{max(1, seconds // 86400)}d"


def confidence_rating(rate_percent, listed):
    listed = listed or 0
    if rate_percent is None and listed <= 0:
        return ""
    if rate_percent is None:
        return "Med" if listed >= 10 else "Low"
    if rate_percent >= 20 and listed >= 10:
        return "High"
    if (rate_percent >= 5 and listed >= 5) or (rate_percent >= 20 and listed >= 1):
        return "Med"
    return "Low"


def expected_per_day(profit, sold_per_day, can_make):
    if sold_per_day is None:
        return None
    if can_make == "any":
        cap = float(sold_per_day)
    else:
        cap = min(float(sold_per_day), float(can_make or 0))
    return int(round(profit * cap))


def market_index(db):
    out = {}
    block = db.get("market") or {}
    for row in as_list(block.get("items") if isinstance(block, dict) else None):
        if isinstance(row, dict) and row.get("id") is not None:
            out[int(row["id"])] = row
    return out


def attach_market(db, quotes):
    markets = market_index(db)
    for row in quotes:
        info = markets.get(row.get("made")) or {}
        rate = sale_rate_percent(info.get("saleRate"))
        sold = info.get("soldPerDay")
        if sold is not None and sold != "":
            sold = float(sold)
        else:
            sold = None
        market = info.get("market")
        atr = info.get("atrPrice") is not None or info.get("atrAge") is not None
        if rate is None and atr and sold is None and market is None:
            age = age_text(info.get("atrAge"))
            row["sale_rate"] = "n/a (Auctionator" + (f", {age}" if age else "") + ")"
        else:
            row["sale_rate"] = "" if rate is None else round(rate)
        row["sold_per_day"] = sold
        row["market"] = int(market) if isinstance(market, (int, float)) and not isinstance(market, bool) else None
        row["confidence"] = confidence_rating(rate, row.get("listed"))
        row["expected"] = expected_per_day(row["profit"], sold, row["can_make"])


def quote_row(row):
    return [
        row["character"],
        row["item"],
        row["profession"],
        row["reagents"],
        row["cost"],
        row["vendor_sell"],
        "" if row["ah_net"] is None else row["ah_net"],
        row["channel"],
        row["profit"],
        row["margin"],
        "" if row["listed"] is None else row["listed"],
        row["can_make"],
        row.get("sale_rate", ""),
        "" if row.get("sold_per_day") is None else row["sold_per_day"],
        "" if row.get("market") is None else row["market"],
        row.get("confidence", ""),
        "" if row.get("expected") is None else row["expected"],
    ]


def profitable_rows(db, data):
    quotes, any_learned = craft_quotes(db, data)
    if not any_learned:
        return [SHUFFLE_HEADER, [LEARNED_NOTE] + [""] * (len(SHUFFLE_HEADER) - 1)]
    guaranteed = [row for row in quotes if row["risk_free"]]
    other = [row for row in quotes if not row["risk_free"]]
    rows = [SHUFFLE_HEADER]
    if not guaranteed and not other:
        rows.append(["No learned recipe sells for more than its reagents. Open each profession once and rescan the auction house."] + [""] * (len(SHUFFLE_HEADER) - 1))
        return rows
    if guaranteed:
        rows.append(["Risk-free: buy every reagent from a vendor, craft, and sell the item to a vendor."] + [""] * (len(SHUFFLE_HEADER) - 1))
        rows.extend(quote_row(row) for row in guaranteed)
    if other:
        rows.append(["Auction: profitable after the 5% cut and the 12-hour deposit."] + [""] * (len(SHUFFLE_HEADER) - 1))
        rows.extend(quote_row(row) for row in other)
    return rows


def age_phrase(when):
    if not when:
        return "not opened", "Open the bank once so this can be dated."
    try:
        then = int(when)
    except (TypeError, ValueError):
        return "not opened", ""
    seconds = max(0, int(datetime.now(timezone.utc).timestamp()) - then)
    if seconds < 90:
        text = "just now"
    elif seconds < 3600:
        minutes = max(1, seconds // 60)
        text = f"{minutes} minute ago" if minutes == 1 else f"{minutes} minutes ago"
    elif seconds < 86400:
        hours = max(1, seconds // 3600)
        text = f"{hours} hour ago" if hours == 1 else f"{hours} hours ago"
    else:
        days = seconds // 86400
        text = f"{days} day ago" if days == 1 else f"{days} days ago"
    return text, stamp(when)


def progress_bar(rank, cap, width=16):
    if not cap:
        return ""
    filled = int(round(width * max(0, min(1, rank / cap))))
    return ("#" * filled) + ("-" * (width - filled))


def summary_facts(db, report):
    gold_bits = []
    for char in character_rows(db):
        if char.get("money") is not None:
            who = char.get("name") or char.get("key")
            gold_bits.append((who, coins(char.get("money"))))
    if len(gold_bits) == 1:
        gold = gold_bits[0][1]
    elif gold_bits:
        gold = sum(amount for _, amount in gold_bits)
    else:
        gold = None
    total = 0
    progress = []
    shopping = []
    for entry in report:
        name = entry["char"].get("name") or entry["char"].get("key")
        for profession in entry["plans"]:
            cost = int(profession.get("total") or 0)
            total += cost
            rank = int(profession.get("rank") or 0)
            cap = int(profession.get("cap") or 0)
            progress.append({
                "character": name,
                "profession": profession.get("name") or "",
                "rank": rank,
                "cap": cap,
                "cost": cost,
            })
        for row in entry["shopping"]:
            cost = int(row.get("cost") or 0)
            if cost <= 0:
                continue
            shopping.append({"character": name, "item": row.get("name") or "", "cost": cost})
    shopping.sort(key=lambda row: -row["cost"])
    prices = db.get("prices") or {}
    priced = 0
    for row in as_list(prices.get("items") if isinstance(prices, dict) else None):
        if isinstance(row, dict) and row.get("unit"):
            priced += 1
    bank_when = None
    for char in character_rows(db):
        block = char.get("bank") or {}
        if isinstance(block, dict) and block.get("updated"):
            bank_when = block.get("updated")
            break
    bank_age, bank_when_text = age_phrase(bank_when)
    return {
        "gold": gold if gold is not None else "not recorded",
        "gold_caption": "From the last bag snapshot." if gold is not None else "Open your bags once after updating.",
        "total": total,
        "priced": priced,
        "scanned": stamp(prices.get("updated") if isinstance(prices, dict) else None) or "no scan yet",
        "bank_age": bank_age,
        "bank_when": bank_when_text,
        "progress": progress,
        "shopping": shopping[:8],
        "character": (character_rows(db)[0].get("name") if character_rows(db) else "") or "",
        "detail": character_line(character_rows(db)[0]) if character_rows(db) else "",
    }


def character_line(char):
    bits = [char.get("name") or "", char.get("faction") or "", char.get("class") or char.get("classFile") or ""]
    if char.get("level"):
        bits.append(f"level {char.get('level')}")
    return " · ".join(bit for bit in bits if bit)


def summary_rows(db, report):
    facts = summary_facts(db, report)
    rows = [
        ["Card", "Value", "Note"],
        ["Gold on hand", facts["gold"], facts["gold_caption"]],
        ["Cost to cap", coins(facts["total"]), "Every profession, including secondary skills."],
        ["AH prices", facts["priced"], "Listings with a buyout."],
        ["Last scan", facts["scanned"], ""],
        ["Bank snapshot", facts["bank_age"], facts["bank_when"]],
        [],
        ["Character", "Profession", "Rank", "Max", "Progress", "Cost to cap"],
    ]
    for row in facts["progress"]:
        percent = round(100 * row["rank"] / row["cap"]) if row["cap"] else 0
        rows.append([row["character"], row["profession"], row["rank"], row["cap"], f"{percent}%", coins(row["cost"])])
    rows.append([])
    rows.append(["Item", "Spend"])
    for row in facts["shopping"]:
        rows.append([row["item"], coins(row["cost"])])
    return rows


def positive_money(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and value > 0


def write_csv_dir(directory, tables):
    os.makedirs(directory, exist_ok=True)
    paths = []
    for name, rows in tables:
        safe = name.replace(" ", "-")
        path = os.path.join(directory, safe + ".csv")
        with open(path, "w", encoding="utf-8", newline="") as handle:
            csv.writer(handle).writerows(rows)
        paths.append(path)
    return paths


def write_xlsx(path, tables, db, report):
    from openpyxl import Workbook
    from openpyxl.chart import BarChart, PieChart, Reference
    from openpyxl.chart.label import DataLabelList
    from openpyxl.chart.series import DataPoint
    from openpyxl.chart.shapes import GraphicalProperties
    from openpyxl.formatting.rule import DataBarRule, Rule
    from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
    from openpyxl.styles.differential import DifferentialStyle
    from openpyxl.styles.numbers import NumberFormat
    from openpyxl.utils import get_column_letter
    from openpyxl.chart.legend import Legend

    ink = PatternFill("solid", fgColor="1A120C")
    card_colors = ["3A2A1C", "2E261C", "3A2618", "243028", "2C2430"]
    header_fill = PatternFill("solid", fgColor="1A1A1A")
    header_font = Font(bold=True, color="F5C16C", name="Calibri", size=12)
    section_fill = PatternFill("solid", fgColor="3A2A1C")
    section_font = Font(bold=True, color="F5C16C", name="Calibri", size=12)
    cream = Font(color="F4EDE4", name="Calibri", size=12)
    gold = Font(bold=True, color="F5C16C", name="Calibri", size=22)
    tan = Font(color="C79B6E", name="Calibri", size=11)
    title_font = Font(bold=True, color="F5C16C", name="Calibri", size=28)
    good_fill = PatternFill("solid", fgColor="1E3A2A")
    good_font = Font(color="D5F5E3", name="Calibri", size=12, bold=True)
    wrap = Alignment(wrap_text=True, vertical="center")
    left = Alignment(vertical="center", wrap_text=True)
    thin = Border(
        left=Side(style="thin", color="3A2A1C"),
        right=Side(style="thin", color="3A2A1C"),
        top=Side(style="thin", color="3A2A1C"),
        bottom=Side(style="thin", color="3A2A1C"),
    )

    def page(sheet):
        sheet.page_setup.orientation = "landscape"
        sheet.page_setup.fitToPage = True
        sheet.page_setup.fitToWidth = 1
        sheet.page_setup.fitToHeight = 1
        sheet.page_setup.paperSize = sheet.PAPERSIZE_TABLOID
        sheet.sheet_properties.pageSetUpPr.fitToPage = True
        sheet.page_setup.horizontalCentered = True
        sheet.sheet_view.showGridLines = False
        sheet.sheet_view.zoomScale = 110
        sheet.oddHeader.left.text = "SkillLedger"
        sheet.oddFooter.right.text = "Jon Shaw (Schizzle)"
        sheet.page_margins.left = 0.4
        sheet.page_margins.right = 0.4
        sheet.page_margins.top = 0.6
        sheet.page_margins.bottom = 0.5
        sheet.sheet_properties.tabColor = "C47A3A"

    def mark_money(cell):
        if isinstance(cell.value, bool) or not isinstance(cell.value, (int, float)):
            return
        cell.number_format = COIN_FORMAT

    def red_losses(sheet, span):
        sheet.conditional_formatting.add(span, Rule(
            type="cellIs",
            operator="lessThan",
            formula=["0"],
            dxf=DifferentialStyle(
                font=Font(color="FF6B6B", name="Calibri"),
                numFmt=NumberFormat(numFmtId=180, formatCode=NEG_COIN_FORMAT),
            ),
        ))

    def paint_range(sheet, rows, cols):
        for row in sheet.iter_rows(min_row=1, max_row=rows, min_col=1, max_col=cols):
            for cell in row:
                cell.fill = ink
                cell.font = cream

    def write_summary(sheet):
        facts = summary_facts(db, report)
        paint_range(sheet, 36, 10)
        sheet.merge_cells("A1:J1")
        sheet["A1"] = "SkillLedger"
        sheet["A1"].font = title_font
        sheet["A1"].alignment = Alignment(vertical="center")
        sheet.row_dimensions[1].height = 38
        sheet.merge_cells("A2:J2")
        sheet["A2"] = facts["detail"] or facts["character"]
        sheet["A2"].font = Font(color="C79B6E", name="Calibri", size=14)
        sheet.row_dimensions[2].height = 22
        cards = [
            ("Gold on hand", facts["gold"], facts["gold_caption"]),
            ("Cost to cap", coins(facts["total"]), "All professions, secondary skills included."),
            ("AH prices", str(facts["priced"]), "Listings with a buyout."),
            ("Last scan", facts["scanned"], "When the auction file was written."),
            ("Bank snapshot", facts["bank_age"], facts["bank_when"] or ""),
        ]
        for index, (label, value, caption) in enumerate(cards):
            col = 1 + index * 2
            fill = PatternFill("solid", fgColor=card_colors[index])
            sheet.merge_cells(start_row=4, start_column=col, end_row=4, end_column=col + 1)
            sheet.merge_cells(start_row=5, start_column=col, end_row=6, end_column=col + 1)
            sheet.merge_cells(start_row=7, start_column=col, end_row=7, end_column=col + 1)
            label_cell = sheet.cell(4, col, label)
            value_cell = sheet.cell(5, col, value)
            caption_cell = sheet.cell(7, col, caption)
            for cell in (label_cell, value_cell, caption_cell):
                cell.fill = fill
                cell.alignment = left
            label_cell.font = tan
            value_cell.font = gold
            if index < 2:
                mark_money(value_cell)
            caption_cell.font = Font(color="A89880", name="Calibri", size=10)
            sheet.cell(4, col + 1).fill = fill
            sheet.cell(5, col + 1).fill = fill
            sheet.cell(6, col).fill = fill
            sheet.cell(6, col + 1).fill = fill
            sheet.cell(7, col + 1).fill = fill
        red_losses(sheet, "A5")
        red_losses(sheet, "C5")
        sheet.row_dimensions[5].height = 28
        sheet.row_dimensions[6].height = 22
        sheet["A9"] = "Profession progress"
        sheet["A9"].font = Font(bold=True, color="F5C16C", name="Calibri", size=16)
        headers = ["Profession", "Rank", "Progress", "Cost", "Percent"]
        for col, text in enumerate(headers, start=1):
            cell = sheet.cell(10, col, text)
            cell.fill = header_fill
            cell.font = header_font
            cell.alignment = left
        for offset, row in enumerate(facts["progress"]):
            excel_row = 11 + offset
            percent = round(100 * row["rank"] / row["cap"]) if row["cap"] else 0
            values = [
                row["profession"],
                f"{row['rank']} / {row['cap']}",
                progress_bar(row["rank"], row["cap"]),
                coins(row["cost"]),
                percent,
            ]
            for col, value in enumerate(values, start=1):
                cell = sheet.cell(excel_row, col, value)
                cell.font = Font(color="F4EDE4", name="Calibri", size=12)
                cell.fill = PatternFill("solid", fgColor="241910")
                cell.alignment = left
                if col == 4:
                    mark_money(cell)
            sheet.row_dimensions[excel_row].height = 20
        last_prof = 10 + max(1, len(facts["progress"]))
        if facts["progress"]:
            sheet.conditional_formatting.add(
                f"E11:E{last_prof}",
                DataBarRule(start_type="num", start_value=0, end_type="num", end_value=100, color="C47A3A", showValue=True),
            )
            red_losses(sheet, f"D11:D{last_prof}")
            chart = BarChart()
            chart.type = "col"
            chart.title = "Cost to cap"
            chart.y_axis.title = "copper"
            chart.style = 10
            chart.legend = None
            chart.y_axis.majorGridlines = None
            data = Reference(sheet, min_col=4, min_row=10, max_row=last_prof)
            cats = Reference(sheet, min_col=1, min_row=11, max_row=last_prof)
            chart.add_data(data, titles_from_data=True)
            chart.set_categories(cats)
            chart.shape = 4
            chart.width = 15
            chart.height = 7
            if chart.series:
                chart.series[0].graphicalProperties.solidFill = "C47A3A"
            sheet.add_chart(chart, "A22")
        sheet["G9"] = "Top shopping"
        sheet["G9"].font = Font(bold=True, color="F5C16C", name="Calibri", size=16)
        for col, text in enumerate(["Item", "Spend"], start=7):
            cell = sheet.cell(10, col, text)
            cell.fill = header_fill
            cell.font = header_font
        top = facts["shopping"][:6]
        rest = sum(row["cost"] for row in facts["shopping"][6:])
        pie_rows = list(top)
        if rest:
            pie_rows.append({"item": "Other", "cost": rest})
        for offset, row in enumerate(pie_rows):
            excel_row = 11 + offset
            sheet.cell(excel_row, 7, row["item"]).font = cream
            spend = sheet.cell(excel_row, 8, coins(row["cost"]))
            spend.font = cream
            mark_money(spend)
            for col in (7, 8):
                sheet.cell(excel_row, col).fill = PatternFill("solid", fgColor="241910")
                sheet.cell(excel_row, col).alignment = left
        if pie_rows:
            pie = PieChart()
            pie.title = "Shopping spend"
            labels = Reference(sheet, min_col=7, min_row=11, max_row=10 + len(pie_rows))
            data = Reference(sheet, min_col=8, min_row=10, max_row=10 + len(pie_rows))
            pie.add_data(data, titles_from_data=True)
            pie.set_categories(labels)
            pie.dataLabels = DataLabelList()
            pie.dataLabels.showPercent = True
            pie.dataLabels.showVal = False
            pie.dataLabels.showCatName = False
            pie.dataLabels.showSerName = False
            pie.width = 14
            pie.height = 8
            palette = ["C47A3A", "F5C16C", "E07A3D", "8C5A3C", "C79B6E", "6B8F71", "A89880"]
            if pie.series:
                points = []
                for index, color in enumerate(palette[:len(pie_rows)]):
                    point = DataPoint(idx=index)
                    point.graphicalProperties = GraphicalProperties(solidFill=color)
                    points.append(point)
                pie.series[0].data_points = points
            pie.legend.position = "b"
            sheet.add_chart(pie, "G22")
            red_losses(sheet, f"H11:H{10 + len(pie_rows)}")
        widths = {"A": 24, "B": 14, "C": 22, "D": 18, "E": 12, "F": 14, "G": 22, "H": 16, "I": 14, "J": 16}
        for letter, width in widths.items():
            sheet.column_dimensions[letter].width = width
        sheet.freeze_panes = "A11"
        sheet.auto_filter.ref = None
        sheet.oddHeader.center.text = facts["character"]
        page(sheet)
        sheet.print_title_rows = "1:2"

    def write_profit(sheet, rows):
        width = max(12, len(SHUFFLE_HEADER))
        paint_range(sheet, max(12, len(rows) + 4), width)
        sheet.merge_cells(start_row=1, start_column=1, end_row=1, end_column=width)
        sheet["A1"] = "Profitable crafts"
        sheet["A1"].font = title_font
        sheet.row_dimensions[1].height = 36
        sheet.merge_cells(start_row=2, start_column=1, end_row=2, end_column=width)
        content = rows[1:] if rows else []
        if len(content) == 1 and isinstance(content[0][0], str) and (
            content[0][0].startswith("Open each") or content[0][0].startswith("No learned")
        ):
            note = content[0][0]
            content = []
        else:
            note = (
                "Reagent cost is the cheaper of the discounted vendor price and the auction price. "
                "Owned mats use that auction price, and the count you hold is in parentheses. "
                "AH net subtracts the 5% cut and a 12-hour deposit. "
                "Sale rate and sold per day come from TSM. Auctionator has no sale rate; its price age is the freshness note. "
                "The top block is risk-free: vendor in, vendor out."
            )
        sheet["A2"] = note
        sheet["A2"].font = Font(color="C79B6E", name="Calibri", size=12)
        sheet["A2"].alignment = left
        sheet.row_dimensions[2].height = 36
        header = rows[0] if rows else SHUFFLE_HEADER
        safe_fill = PatternFill("solid", fgColor="5C4328")
        auction_fill = PatternFill("solid", fgColor="3A2A1C")
        risk_fill = PatternFill("solid", fgColor="2F4A32")
        thin_fill = PatternFill("solid", fgColor="C47A3A")
        risk_zone = False
        qty_col = header.index("AH Qty Listed") + 1 if "AH Qty Listed" in header else None
        margin_col = header.index("Margin %") + 1 if "Margin %" in header else None
        for col, value in enumerate(header, start=1):
            cell = sheet.cell(3, col, value)
            cell.fill = header_fill
            cell.font = header_font
            cell.alignment = left
            cell.border = thin
        for offset, row in enumerate(content, start=4):
            label = row[0] if row else ""
            kind = "data"
            if isinstance(label, str) and label.startswith("Risk-free"):
                kind = "section-safe"
                risk_zone = True
            elif isinstance(label, str) and label.startswith("Auction"):
                kind = "section-ah"
                risk_zone = False
            elif isinstance(label, str) and (label.startswith("Open each") or label.startswith("No learned")):
                kind = "note"
            for col, value in enumerate(row, start=1):
                cell = sheet.cell(offset, col, value)
                cell.alignment = left
                cell.border = thin
                if kind == "section-safe":
                    cell.fill = safe_fill
                    cell.font = Font(bold=True, color="F5C16C", name="Calibri", size=12)
                elif kind == "section-ah":
                    cell.fill = auction_fill
                    cell.font = Font(bold=True, color="C79B6E", name="Calibri", size=12)
                elif kind == "note":
                    cell.fill = PatternFill("solid", fgColor="241910")
                    cell.font = Font(color="C79B6E", name="Calibri", size=12)
                elif risk_zone:
                    cell.fill = risk_fill
                    cell.font = Font(color="E7F6D8", name="Calibri", size=12, bold=True)
                else:
                    cell.fill = good_fill
                    cell.font = good_font
                if kind == "data" and col - 1 < len(header) and header[col - 1] in MONEY_HEADERS:
                    mark_money(cell)
                if kind == "data" and margin_col and col == margin_col and isinstance(value, int):
                    cell.number_format = '0"%"'
                if kind == "data" and col - 1 < len(header) and header[col - 1] == "Sale Rate" and isinstance(value, (int, float)):
                    cell.number_format = '0"%"'
                if kind == "data" and qty_col and col == qty_col and isinstance(value, int) and 0 < value < THIN_MARKET:
                    cell.fill = thin_fill
                    cell.font = Font(color="1A120C", name="Calibri", size=12, bold=True)
            sheet.row_dimensions[offset].height = 22 if kind == "data" else 24
        last = 3 + max(1, len(content))
        for title in ("Cost", "Vendor Sell", "AH Net", "Profit"):
            if title in header:
                column = get_column_letter(header.index(title) + 1)
                red_losses(sheet, f"{column}4:{column}{last}")
        widths = [16, 26, 16, 54, 14, 14, 14, 14, 14, 12, 16, 14]
        for index, size in enumerate(widths, start=1):
            sheet.column_dimensions[get_column_letter(index)].width = size
        sheet.freeze_panes = "A4"
        sheet.auto_filter.ref = f"A3:{get_column_letter(width)}{last}"
        page(sheet)

    def write_table(sheet, rows):
        for row_index, row in enumerate(rows, start=1):
            for col_index, value in enumerate(row, start=1):
                cell = sheet.cell(row_index, col_index, value)
                cell.alignment = wrap
                cell.font = Font(name="Calibri", size=11, color="1A120C")
            if row_index == 1:
                for col_index in range(1, len(row) + 1):
                    cell = sheet.cell(row_index, col_index)
                    cell.fill = header_fill
                    cell.font = header_font
            elif row and row[0] in ("Standing", "Merchant window", "Plan price"):
                for col_index in range(1, len(row) + 1):
                    sheet.cell(row_index, col_index).fill = section_fill
                    sheet.cell(row_index, col_index).font = section_font
        money_columns = []
        if rows and rows[0]:
            for col_index, title in enumerate(rows[0], start=1):
                if title in MONEY_HEADERS:
                    money_columns.append(col_index)
                    for row_index in range(2, len(rows) + 1):
                        mark_money(sheet.cell(row_index, col_index))
        if money_columns and len(rows) > 1:
            for col_index in money_columns:
                letter = get_column_letter(col_index)
                red_losses(sheet, f"{letter}2:{letter}{len(rows)}")
        sheet.freeze_panes = "A2"
        if rows and rows[0]:
            sheet.auto_filter.ref = sheet.dimensions
        for col_index in range(1, (len(rows[0]) if rows else 1) + 1):
            width = 14
            for row in rows[:80]:
                if col_index - 1 < len(row):
                    width = max(width, min(48, len(str(row[col_index - 1])) + 2))
            sheet.column_dimensions[get_column_letter(col_index)].width = width
        sheet.page_setup.orientation = "landscape"
        sheet.page_setup.fitToPage = True
        sheet.page_setup.fitToWidth = 1
        sheet.page_setup.fitToHeight = 0
        sheet.sheet_properties.pageSetUpPr.fitToPage = True
        sheet.oddHeader.left.text = "SkillLedger"
        sheet.oddFooter.right.text = "Jon Shaw (Schizzle)"
        sheet.sheet_properties.tabColor = "8C5A3C"
        sheet.auto_filter.ref = sheet.dimensions
        sheet.freeze_panes = "A2"

    book = Workbook()
    for index, (name, rows) in enumerate(tables):
        sheet = book.active if index == 0 else book.create_sheet()
        sheet.title = name[:31]
        if name == "Summary":
            write_summary(sheet)
        elif name == "Profitable Crafts":
            write_profit(sheet, rows)
        else:
            write_table(sheet, rows)
    book.save(path)


def non_lua_message(path):
    shown = path or ""
    return (
        f"{shown} is not a SavedVariables file. "
        "Pass SkillLedger.lua from WTF\\Account\\<ACCOUNT>\\SavedVariables, "
        "or run export.bat with no file name and it will search for that .lua file. "
        "A .bat or other non-.lua file is never read as the source."
    )


def desktop_dir():
    home = os.path.expanduser("~")
    candidates = []
    if os.name == "nt":
        folder = windows_known_folder("Desktop")
        if folder:
            candidates.append(folder)
        profile = os.environ.get("USERPROFILE") or home
        candidates.append(os.path.join(profile, "Desktop"))
        candidates.append(os.path.join(profile, "OneDrive", "Desktop"))
    candidates.append(os.path.join(home, "Desktop"))
    for path in candidates:
        if path and os.path.isdir(os.path.expandvars(path)):
            return os.path.abspath(os.path.expandvars(path))
    return os.path.abspath(home)


def windows_known_folder(name):
    try:
        import winreg
    except ImportError:
        return None
    key_path = r"Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    try:
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, key_path) as key:
            value, _ = winreg.QueryValueEx(key, name)
    except OSError:
        return None
    if not isinstance(value, str) or not value:
        return None
    return os.path.expandvars(value)


def default_output():
    return os.path.join(desktop_dir(), "SkillLedger.xlsx")


def _unique(paths):
    seen = set()
    out = []
    for path in paths:
        if not path:
            continue
        normal = os.path.normpath(os.path.expandvars(str(path).strip().strip('"')))
        key = os.path.normcase(normal)
        if key in seen:
            continue
        seen.add(key)
        out.append(normal)
    return out


def _looks_like_wow_path(value):
    if not isinstance(value, str):
        return False
    text = value.replace("/", "\\").strip().strip('"')
    if len(text) < 3 or "\n" in text:
        return False
    lower = text.lower()
    return "world of warcraft" in lower or lower.rstrip("\\").endswith("\\_forever_")


def registry_wow_roots():
    """Battle.net / World of Warcraft install paths from the registry, when present."""
    try:
        import winreg
    except ImportError:
        return []
    found = []
    parents = (
        (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\WOW6432Node\Blizzard Entertainment"),
        (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Blizzard Entertainment"),
        (winreg.HKEY_CURRENT_USER, r"SOFTWARE\Blizzard Entertainment"),
        (winreg.HKEY_CURRENT_USER, r"SOFTWARE\WOW6432Node\Blizzard Entertainment"),
    )
    uninstall = (
        (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"),
        (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"),
        (winreg.HKEY_CURRENT_USER, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"),
    )

    def walk(hive, subkey, depth):
        try:
            key = winreg.OpenKey(hive, subkey)
        except OSError:
            return
        with key:
            index = 0
            while True:
                try:
                    _name, value, _kind = winreg.EnumValue(key, index)
                except OSError:
                    break
                index += 1
                if _looks_like_wow_path(value):
                    found.append(value)
            if depth <= 0:
                return
            index = 0
            while True:
                try:
                    child = winreg.EnumKey(key, index)
                except OSError:
                    break
                index += 1
                walk(hive, subkey + "\\" + child, depth - 1)

    for hive, subkey in parents:
        walk(hive, subkey, 3)
    for hive, subkey in uninstall:
        try:
            key = winreg.OpenKey(hive, subkey)
        except OSError:
            continue
        with key:
            index = 0
            while True:
                try:
                    child = winreg.EnumKey(key, index)
                except OSError:
                    break
                index += 1
                lowered = child.lower()
                if "warcraft" in lowered or "battle.net" in lowered or "blizzard" in lowered:
                    walk(hive, subkey + "\\" + child, 1)
    return _unique(found)


def common_install_roots():
    roots = []
    for env in ("PROGRAMFILES(X86)", "PROGRAMFILES", "ProgramFiles(x86)", "ProgramFiles", "PROGRAMW6432"):
        base = os.environ.get(env)
        if base:
            roots.append(os.path.join(base, "World of Warcraft"))
    roots.append(os.path.join(os.path.expanduser("~"), "World of Warcraft"))
    roots.extend(registry_wow_roots())
    for drive in "CDEFGH":
        roots.append(drive + ":\\Program Files (x86)\\World of Warcraft")
        roots.append(drive + ":\\Program Files\\World of Warcraft")
        roots.append(drive + ":\\World of Warcraft")
        roots.append(drive + ":\\Games\\World of Warcraft")
    return _unique(roots)


def forever_account_dirs(root):
    """WTF\\Account folders for a WoW install, including a nested _forever_ directory."""
    if not root or not os.path.isdir(root):
        return []
    bases = []
    normal = os.path.normpath(root)
    if os.path.basename(normal).lower() == "_forever_":
        bases.append(normal)
    else:
        direct = os.path.join(normal, "_forever_")
        if os.path.isdir(direct):
            bases.append(direct)
        try:
            names = os.listdir(normal)
        except OSError:
            names = []
        for name in names:
            child = os.path.join(normal, name)
            if not os.path.isdir(child):
                continue
            if name.lower() == "_forever_":
                bases.append(child)
            nested = os.path.join(child, "_forever_")
            if os.path.isdir(nested):
                bases.append(nested)
    accounts = []
    for base in _unique(bases):
        account = os.path.join(base, "WTF", "Account")
        if os.path.isdir(account):
            accounts.append(account)
    return accounts


def saved_files_under(root):
    found = []
    if not root or not os.path.isdir(root):
        return found
    direct = os.path.join(root, "SavedVariables", "SkillLedger.lua")
    if os.path.isfile(direct):
        found.append(os.path.abspath(direct))
    try:
        names = os.listdir(root)
    except OSError:
        return found
    for name in names:
        path = os.path.join(root, name, "SavedVariables", "SkillLedger.lua")
        if os.path.isfile(path):
            found.append(os.path.abspath(path))
    return found


def user_path(path):
    text = os.path.expanduser(str(path))
    if os.name != "nt" and ("\\" in text):
        text = text.replace("\\", os.sep)
    return text


def collect_saved(explicit=None):
    """Return (candidates, searched_roots). Candidates are SkillLedger.lua paths."""
    searched = []
    found = []
    if explicit:
        path = user_path(explicit)
        if os.path.isdir(path):
            searched.append(os.path.abspath(path))
            found.extend(saved_files_under(path))
            for account in forever_account_dirs(path):
                searched.append(account)
                found.extend(saved_files_under(account))
        elif not path.lower().endswith(".lua"):
            raise SystemExit(non_lua_message(path))
        elif not os.path.isfile(path):
            raise SystemExit(
                f"Cannot find {path}. Pass SkillLedger.lua, or run export.bat with no file name to search for it."
            )
        else:
            return [os.path.abspath(path)], []
    else:
        for root in common_install_roots():
            searched.append(root)
            for account in forever_account_dirs(root):
                searched.append(account)
                found.extend(saved_files_under(account))
    unique = []
    seen = set()
    for path in found:
        key = os.path.normcase(path)
        if key in seen:
            continue
        seen.add(key)
        unique.append(path)
    unique.sort(key=lambda item: os.path.getmtime(item), reverse=True)
    return unique, searched


def openpyxl_ready():
    try:
        import openpyxl  # noqa: F401
        return True
    except ImportError:
        print("openpyxl is not installed, so an .xlsx workbook cannot be written yet.")
        print("Install it with this command: py -3 -m pip install openpyxl")
        if sys.stdin is not None and sys.stdin.isatty():
            try:
                answer = input("Install openpyxl now? [y/N] ")
            except EOFError:
                answer = ""
            if answer.strip().lower() in ("y", "yes"):
                import subprocess
                command = [sys.executable, "-m", "pip", "install", "openpyxl"]
                print("running " + " ".join(command))
                result = subprocess.call(command)
                if result == 0:
                    try:
                        import openpyxl  # noqa: F401
                        return True
                    except ImportError:
                        pass
                print("openpyxl is still not importable. This run will write CSV instead.")
        return False


def main(argv):
    parser = argparse.ArgumentParser(description="Export SkillLedger SavedVariables to Excel or CSV.")
    parser.add_argument("saved", nargs="?", help="SkillLedger.lua, or a WTF Account folder")
    parser.add_argument("--account", help="WTF\\Account folder, or one account's folder")
    parser.add_argument("-o", "--output", help="xlsx path (default: Desktop\\SkillLedger.xlsx)")
    parser.add_argument("--csv", action="store_true", help="also write CSV files; used alone if openpyxl is missing")
    args = parser.parse_args(argv)
    explicit = args.saved or args.account
    candidates, searched = collect_saved(explicit)
    if not candidates:
        print("No SkillLedger.lua was found. Looked under:")
        for root in searched:
            print(f"  {root}")
        raise SystemExit(
            "Pass SavedVariables\\SkillLedger.lua, or log out / type /reload so WoW writes it, then run this again."
        )
    if not explicit:
        print("SavedVariables files found:")
        for path in candidates:
            print(f"  {path}")
    source = candidates[0]
    if len(candidates) > 1 or not explicit:
        print(f"using {source}")
    else:
        print(f"reading {source}")
    db = load_saved(source)
    data = load_recipes()
    report = build_report(db, data)
    tables = [
        ("Summary", summary_rows(db, report)),
        ("Profitable Crafts", profitable_rows(db, data)),
        ("Professions", profession_rows(db)),
        ("Inventory", inventory_rows(db, data)),
        ("AH Prices", price_rows(db)),
        ("Leveling Plan", plan_rows(report)),
        ("Shopping List", shopping_rows(report)),
        ("Vendors", vendor_rows(db, report)),
    ]
    output = os.path.abspath(args.output or default_output())
    wrote = []
    use_xlsx = openpyxl_ready()
    if use_xlsx:
        write_xlsx(output, tables, db, report)
        wrote.append(output)
        print(f"wrote {output}")
    if args.csv or not use_xlsx:
        folder = os.path.splitext(output)[0] + "-csv"
        wrote.extend(write_csv_dir(folder, tables))
        print(f"wrote CSV files in {folder}")
    if wrote:
        print(f"output: {os.path.abspath(wrote[0])}")
    return wrote


if __name__ == "__main__":
    main(sys.argv[1:])
