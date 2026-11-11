#!/usr/bin/env python3
"""Export the sample SavedVariables and check the workbook."""

import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import export  # noqa: E402
from export import collect_saved, load_saved, main  # noqa: E402

SAMPLE = os.path.join(HERE, "sample", "SkillLedger.lua")
OUT = os.path.join(HERE, "sample", "SkillLedger-test.xlsx")


def test_bat_argument_is_not_parsed():
    """PowerShell can pass .\\export.bat as the first argument. That file is not SavedVariables."""
    previous = os.getcwd()
    os.chdir(HERE)
    try:
        main([".\\export.bat", "-o", OUT])
    except SystemExit as exc:
        text = str(exc)
        assert "export.bat" in text, text
        assert "not a SavedVariables file" in text, text
        assert "expected a name" not in text, text
    else:
        raise AssertionError("export.bat was accepted as the SavedVariables source")
    finally:
        os.chdir(previous)
    assert not os.path.exists(OUT)


def test_parse_failure_names_the_file():
    folder = tempfile.mkdtemp()
    path = os.path.join(folder, "SkillLedger.lua")
    with open(path, "w", encoding="utf-8") as handle:
        handle.write("@echo off\n")
    try:
        load_saved(path)
    except SystemExit as exc:
        text = str(exc)
        assert path in text, text
        assert "/reload" in text, text
        assert "expected a name" in text, text
    else:
        raise AssertionError("a batch file renamed to .lua was parsed")


def test_newest_saved_file_is_chosen():
    root = tempfile.mkdtemp()
    wow = os.path.join(root, "World of Warcraft", "_forever_", "WTF", "Account")
    older = os.path.join(wow, "OLD", "SavedVariables")
    newer = os.path.join(wow, "NEW", "SavedVariables")
    os.makedirs(older)
    os.makedirs(newer)
    old_file = os.path.join(older, "SkillLedger.lua")
    new_file = os.path.join(newer, "SkillLedger.lua")
    with open(old_file, "w", encoding="utf-8") as handle:
        handle.write("SkillLedgerDB = {}\n")
    with open(new_file, "w", encoding="utf-8") as handle:
        handle.write("SkillLedgerDB = {}\n")
    os.utime(old_file, (1000, 1000))
    os.utime(new_file, (2000, 2000))
    found, _searched = collect_saved(os.path.join(root, "World of Warcraft"))
    assert found[0] == os.path.abspath(new_file)
    assert os.path.abspath(old_file) in found
    assert export.default_output().endswith(os.path.join("Desktop", "SkillLedger.xlsx")) or export.default_output().endswith(
        "SkillLedger.xlsx"
    )


def test_vendor_flip_section():
    data = {
        "professions": [{"id": 171, "name": "Alchemy"}],
        "items": {"1": "Empty Vial", "2": "Test Potion"},
        "vendor": {"1": {"price": 20, "factions": [{"id": 76, "name": "Orgrimmar", "side": "Horde"}]}},
        "sell": {"2": 100},
        "recipes": [{
            "spell": 9, "skill": 171, "name": "Test Potion", "made": 2, "count": 1,
            "enchant": False, "reagents": [[1, 1]],
        }],
    }
    db = {"chars": {"A": {
        "name": "Grimjaw", "faction": "Horde", "classFile": "WARRIOR", "race": "Orc",
        "bags": {"items": []}, "bank": {"items": []},
        "standings": {"factions": [{"id": 76, "standing": 5}]},
        "merchant": {"rows": []},
        "learned": {"recipes": [{"spell": 9, "name": "Test Potion", "profession": "Alchemy"}]},
    }}, "prices": {"items": []}}
    rows = export.profitable_rows(db, data)
    labels = [row[0] for row in rows]
    assert any(str(label).startswith("Risk-free") for label in labels)
    potion = next(row for row in rows if row[1] == "Test Potion")
    assert potion[4] == 19  # Friendly 5% on a 20c vial
    assert potion[5] == 100
    assert potion[7] == "Vendor"
    assert potion[8] == 81
    assert potion[11] == "any"
    assert potion[14] == "" and potion[15] == ""


def test_price_source():
    data = {
        "professions": [{"id": 171, "name": "Alchemy"}],
        "items": {"1": "Empty Vial", "2": "Test Potion", "3": "Copper Ore", "4": "Copper Bar"},
        "vendor": {"1": {"price": 20, "factions": [{"id": 76, "name": "Orgrimmar", "side": "Horde"}]}},
        "sell": {"2": 100, "4": 10},
        "recipes": [
            {
                "spell": 9, "skill": 171, "name": "Test Potion", "made": 2, "count": 1,
                "enchant": False, "reagents": [[1, 1]],
            },
            {
                "spell": 10, "skill": 171, "name": "Smelted Bar", "made": 4, "count": 1,
                "enchant": False, "reagents": [[3, 1]],
            },
        ],
    }
    char = {
        "name": "Grimjaw", "faction": "Horde", "classFile": "WARRIOR", "race": "Orc",
        "bags": {"items": []}, "bank": {"items": []},
        "standings": {"factions": [{"id": 76, "standing": 5}]},
        "merchant": {"rows": []},
        "learned": {"recipes": [
            {"spell": 9, "name": "Test Potion", "profession": "Alchemy"},
            {"spell": 10, "name": "Smelted Bar", "profession": "Alchemy"},
        ]},
    }

    def potion(prices, market):
        db = {"chars": {"A": char}, "prices": {"items": prices}, "market": {"items": market}}
        rows = export.profitable_rows(db, data)
        found = {row[1]: row for row in rows if row[1]}
        return found

    missing = potion([], [{"id": 2, "atrPrice": 200, "atrAge": 7200}])
    row = missing["Test Potion"]
    assert row[6] == 175  # 200c, minus 5% and a 15c deposit
    assert row[7] == "AH"
    assert row[8] == 156
    assert row[12] == ""
    assert row[14] == "Auctionator"
    assert row[15] == "2h"

    fresher = potion(
        [{"id": 2, "unit": 500, "total": 8, "at": 1000}],
        [{"id": 2, "atrPrice": 200, "atrAge": 50, "at": 8000, "market": 99999, "minBuyout": 1}],
    )
    row = fresher["Test Potion"]
    assert row[6] == 175
    assert row[8] == 156
    assert row[14] == "Auctionator"
    assert row[15] == "50s"

    own_scan = potion(
        [{"id": 2, "unit": 200, "total": 8, "at": 7900}],
        [{"id": 2, "atrPrice": 50, "atrAge": 5000, "at": 8000, "market": 99999, "minBuyout": 1}],
    )
    row = own_scan["Test Potion"]
    assert row[6] == 175
    assert row[14] == "Scan"
    assert row[15] == "1m"

    ignored = potion(
        [{"id": 2, "unit": 200, "total": 8, "at": 8000}],
        [{"id": 2, "market": 99999, "minBuyout": 1, "at": 8000}],
    )
    row = ignored["Test Potion"]
    assert row[6] == 175
    assert row[14] == "Scan"
    assert row[15] == "just now"

    reagent = potion(
        [{"id": 3, "unit": 100, "at": 1000}, {"id": 4, "unit": 400, "total": 4, "at": 1000}],
        [{"id": 3, "atrPrice": 30, "atrAge": 10, "at": 5000}],
    )
    bar = reagent["Smelted Bar"]
    assert "AH Auctionator 30c" in bar[3]
    assert bar[4] == 30
    assert bar[14] == "Scan"


def main_test():
    test_bat_argument_is_not_parsed()
    test_parse_failure_names_the_file()
    test_newest_saved_file_is_chosen()
    assert os.path.basename(export.default_output()) == "SkillLedger.xlsx"
    main([SAMPLE, "-o", OUT, "--csv"])
    from openpyxl import load_workbook
    book = load_workbook(OUT)
    assert book.sheetnames == [
        "Summary", "Profitable Crafts", "Professions", "Inventory", "AH Prices",
        "Leveling Plan", "Shopping List", "Vendors",
    ]
    assert book["Summary"].freeze_panes == "A11"
    assert book["Profitable Crafts"].freeze_panes == "A4"
    for name in book.sheetnames:
        if name not in ("Summary", "Profitable Crafts"):
            assert book[name].freeze_panes == "A2"
    assert book["Summary"].sheet_view.showGridLines is False
    assert len(book["Summary"]._charts) >= 2
    summary_text = " ".join(
        str(cell.value) for row in book["Summary"].iter_rows(max_row=8, max_col=10) for cell in row if cell.value
    )
    assert 354321 in [cell.value for row in book["Summary"].iter_rows(max_row=8, max_col=10) for cell in row]
    assert book["Summary"]["A5"].number_format == export.COIN_FORMAT
    assert "Gold on hand" in summary_text
    professions = [row[4] for row in book["Professions"].iter_rows(min_row=2, values_only=True)]
    assert "Mining" in professions and "Blacksmithing" in professions
    assert "First Aid" not in professions
    assert "Realm" not in [cell.value for cell in book["Professions"][1]]
    assert "Secondary" not in [cell.value for cell in book["Professions"][1]]
    inventory = {row[2]: row for row in book["Inventory"].iter_rows(min_row=2, values_only=True)}
    assert inventory["Linen Cloth"][3] == 13
    assert inventory["Linen Cloth"][4] == "Bags 8 / Bank 5"
    assert "Hearthstone" not in inventory
    assert "Worn Shortsword" not in inventory
    assert inventory["Loose Thread"][3] == 3
    assert "Bag" not in [cell.value for cell in book["Inventory"][1]]
    assert "Snapshot" not in [cell.value for cell in book["Inventory"][1]]
    plan_sheet = book["Leveling Plan"]
    recipes = [row[4].value for row in plan_sheet.iter_rows(min_row=2)]
    assert "Smelt Copper" in recipes
    shopping = {row[1].value: row for row in book["Shopping List"].iter_rows(min_row=2)}
    vial = shopping["Empty Vial"]
    assert vial[6].value == "5%"
    assert vial[7].value == "Orgrimmar"
    assert vial[9].value == 19
    assert vial[9].number_format == export.COIN_FORMAT
    assert vial[11].value == "merchant"
    assert "Item ID" not in [cell.value for cell in book["Shopping List"][1]]
    cloth = shopping["Linen Cloth"]
    assert cloth[3].value == 13  # 8 in bags + 5 in the bank, subtracted once
    vendors = book["Vendors"]
    assert "Faction ID" not in [cell.value for cell in vendors[1]]
    assert "NPC" not in [cell.value for cell in vendors[1]]
    assert "Item ID" not in [cell.value for cell in vendors[1]]
    found = False
    for row in vendors.iter_rows(min_row=2, values_only=True):
        if row[0] == "Standing" and row[2] == "Orgrimmar":
            assert row[3] == "Friendly" and row[4] == "5%"
            found = True
    assert found
    header = [cell.value for cell in book["Profitable Crafts"][3]]
    assert header[:8] == ["Character", "Item", "Profession", "Reagents", "Cost", "Vendor Sell", "AH Net", "Best Channel"]
    crafts = {}
    for row in book["Profitable Crafts"].iter_rows(min_row=4, values_only=True):
        if row[1]:
            crafts[row[1]] = row
    assert "Copper Bracers" not in crafts
    smelt = crafts["Smelt Copper"]
    assert "owned" in smelt[3] and "own 20" in smelt[3]
    assert smelt[4] == 30  # one copper ore at the 30c auction price
    assert smelt[5] == 10  # vendor pays 10c for a copper bar
    assert smelt[6] == 379  # 400c buyout, minus 5% and a 1c deposit
    assert smelt[7] == "AH"
    assert smelt[8] == 349
    assert smelt[11] == 20
    assert crafts["Linen Bandage"][8] == 109
    assert crafts["Rough Sharpening Stone"][12] == 40
    assert crafts["Rough Sharpening Stone"][14] == "Scan"
    assert crafts["Smelt Copper"][14] == "Scan"
    assert crafts["Smelt Copper"][15] == "just now"
    assert "Market Value" not in header
    assert header[14:16] == ["Price Source", "Price Age"]
    assert crafts["Rough Sharpening Stone"][16] == "High"
    assert crafts["Linen Bandage"][16] == "Med"
    assert crafts["Smelt Copper"][16] == "Low"
    assert crafts["Rough Sharpening Stone"][17] == 123 * 8
    names = [row[1] for row in book["Profitable Crafts"].iter_rows(min_row=4, values_only=True) if row[1]]
    assert names[:3] == ["Rough Sharpening Stone", "Linen Bandage", "Smelt Copper"]
    profit_cell = None
    for row in book["Profitable Crafts"].iter_rows(min_row=4):
        if row[1].value == "Smelt Copper":
            profit_cell = row[8]
    assert profit_cell is not None and profit_cell.number_format == export.COIN_FORMAT
    test_vendor_flip_section()
    test_price_source()
    bare = export.load_saved(SAMPLE)
    for char in bare["chars"].values():
        char.pop("learned", None)
    note_rows = export.profitable_rows(bare, export.load_recipes())
    assert any("Open each profession" in str(cell) for row in note_rows for cell in row)
    csv_dir = os.path.join(HERE, "sample", "SkillLedger-test-csv")
    assert os.path.isfile(os.path.join(csv_dir, "Vendors.csv"))
    os.remove(OUT)
    for name in os.listdir(csv_dir):
        os.remove(os.path.join(csv_dir, name))
    os.rmdir(csv_dir)
    print("export test passed")


if __name__ == "__main__":
    main_test()
