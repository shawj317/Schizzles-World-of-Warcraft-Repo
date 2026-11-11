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


def money(copper):
    if copper is None:
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


def profession_rows(db):
    rows = [["Character", "Realm", "Faction", "Class", "Level", "Profession", "Rank", "Max", "Secondary"]]
    for char in character_rows(db):
        profs = as_list(char.get("professions")) or [{}]
        for row in profs:
            if not isinstance(row, dict):
                continue
            rows.append([
                char.get("name") or char.get("key"),
                char.get("realm") or "",
                char.get("faction") or "",
                char.get("classFile") or char.get("class") or "",
                char.get("level") or "",
                row.get("name") or "",
                row.get("rank") or "",
                row.get("maxRank") or "",
                "yes" if row.get("secondary") else "",
            ])
    return rows


def inventory_rows(db):
    rows = [["Character", "Where", "Bag", "Slot", "Item ID", "Name", "Count", "Snapshot"]]
    for char in character_rows(db):
        for bucket, where in (("bags", "bag"), ("bank", "bank")):
            block = char.get(bucket) or {}
            when = stamp(block.get("updated")) if isinstance(block, dict) else ""
            items = as_list(block.get("items") if isinstance(block, dict) else None)
            if not items and bucket == "bank":
                rows.append([char.get("name"), "bank", "", "", "", "(bank not opened)", "", when])
            for item in items:
                if not isinstance(item, dict):
                    continue
                rows.append([
                    char.get("name"),
                    item.get("where") or where,
                    item.get("bag", ""),
                    item.get("slot", ""),
                    item.get("id", ""),
                    item.get("name") or "",
                    item.get("count") or "",
                    when,
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
            money(unit) if unit else "",
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
            rows.append([name, profession["name"], "", "", "", "", "", "", "", money(profession["total"]), "", " | ".join(profession["notes"])])
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
                    money(step["cost"]),
                    money(step["running"]),
                    "; ".join(step["notes"] + [f"no price: {item}" for item in step["unpriced"]]),
                ])
    return rows


def shopping_rows(report):
    rows = [[
        "Character", "Item ID", "Item", "Need", "From bags", "Buy",
        "Base unit", "Discount", "Faction", "Standing", "Unit paid", "Line cost", "Source",
    ]]
    for entry in report:
        name = entry["char"].get("name") or entry["char"].get("key")
        for row in entry["shopping"]:
            if row["need"] <= 0.001:
                continue
            rows.append([
                name,
                row["id"],
                row["name"],
                round(row["need"], 2),
                round(row["fromStock"], 2),
                row["buyWhole"],
                money(row["base"]) if row.get("base") else "",
                f"{row['discount']}%" if row.get("discount") else "",
                row.get("faction") or "",
                row.get("standing") or "",
                money(row["unit"]) if row.get("unit") else "",
                money(row["cost"]) if row.get("cost") else "",
                row.get("source") or "",
            ])
    return rows


def vendor_rows(db, report):
    rows = [["Section", "Character", "Faction", "Faction ID", "Standing", "Discount", "Item", "Item ID", "Base", "Unit paid", "NPC", "When", "Note"]]
    for char in character_rows(db):
        name = char.get("name") or char.get("key")
        block = char.get("standings") or {}
        for row in as_list(block.get("factions") if isinstance(block, dict) else None):
            if not isinstance(row, dict):
                continue
            standing = int(row.get("standing") or 0)
            rows.append([
                "Standing", name, row.get("name") or "", row.get("id") or "",
                plan.standing_name(standing), f"{plan.discount_percent(standing)}%",
                "", "", "", "", "", stamp(block.get("updated") if isinstance(block, dict) else None),
                "Unfriendly and below cannot buy. Neutral pays the catalog price.",
            ])
        merchant = char.get("merchant") or {}
        for row in as_list(merchant.get("rows") if isinstance(merchant, dict) else None):
            if not isinstance(row, dict):
                continue
            standing = row.get("standing")
            rows.append([
                "Merchant window", name, row.get("faction") or "", row.get("factionId") or "",
                plan.standing_name(int(standing)) if standing else "",
                f"{plan.discount_percent(int(standing))}%" if standing else "",
                row.get("name") or "", row.get("id") or "",
                "", money(row.get("unit")), row.get("npc") or "", stamp(row.get("at")),
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
                "Plan price", name, row.get("faction") or "", "",
                row.get("standing") or "",
                f"{row['discount']}%" if row.get("discount") else "0%",
                row["name"], row["id"],
                money(row.get("base")) if row.get("base") else "",
                money(row.get("unit")) if row.get("unit") else "",
                "", "",
                "Standing was not saved, so Neutral was assumed." if row.get("assumed") else row.get("source") or "",
            ])
    return rows


SHEETS = [
    ("Professions", profession_rows),
    ("Inventory", inventory_rows),
    ("AH Prices", price_rows),
    ("Leveling Plan", None),
    ("Shopping List", None),
    ("Vendors", None),
]


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


def write_xlsx(path, tables):
    from openpyxl import Workbook
    from openpyxl.styles import Alignment, Font, PatternFill
    from openpyxl.utils import get_column_letter

    book = Workbook()
    header_fill = PatternFill("solid", fgColor="1A1A1A")
    header_font = Font(bold=True, color="F5C16C", name="Calibri")
    section_fill = PatternFill("solid", fgColor="3A2A1C")
    section_font = Font(bold=True, color="F5C16C", name="Calibri")
    wrap = Alignment(wrap_text=True, vertical="top")
    for index, (name, rows) in enumerate(tables):
        sheet = book.active if index == 0 else book.create_sheet()
        sheet.title = name[:31]
        for row_index, row in enumerate(rows, start=1):
            for col_index, value in enumerate(row, start=1):
                cell = sheet.cell(row_index, col_index, value)
                cell.alignment = wrap
            if row_index == 1:
                for col_index in range(1, len(row) + 1):
                    cell = sheet.cell(row_index, col_index)
                    cell.fill = header_fill
                    cell.font = header_font
            elif row and row[0] in ("Standing", "Merchant window", "Plan price"):
                for col_index in range(1, len(row) + 1):
                    sheet.cell(row_index, col_index).fill = section_fill
                    sheet.cell(row_index, col_index).font = section_font
        sheet.freeze_panes = "A2"
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
        sheet.oddHeader.left.text = "SkillLedger"
        sheet.oddFooter.right.text = "Jon Shaw (Schizzle)"
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
        ("Professions", profession_rows(db)),
        ("Inventory", inventory_rows(db)),
        ("AH Prices", price_rows(db)),
        ("Leveling Plan", plan_rows(report)),
        ("Shopping List", shopping_rows(report)),
        ("Vendors", vendor_rows(db, report)),
    ]
    output = os.path.abspath(args.output or default_output())
    wrote = []
    use_xlsx = openpyxl_ready()
    if use_xlsx:
        write_xlsx(output, tables)
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
