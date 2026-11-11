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
    crafts = {}
    for row in book["Profitable Crafts"].iter_rows(min_row=4, values_only=True):
        if row[2]:
            crafts[row[2]] = row
    assert crafts["Smelt Copper"][4] == "owned"
    assert crafts["Smelt Copper"][7] == 400
    assert crafts["Copper Bracers"][7] == -300
    profit_cell = None
    for row in book["Profitable Crafts"].iter_rows(min_row=4):
        if row[2].value == "Copper Bracers":
            profit_cell = row[7]
    assert profit_cell is not None and profit_cell.number_format == export.COIN_FORMAT
    smelt_fill = book["Profitable Crafts"]["C4"].fill.fgColor.rgb
    assert smelt_fill in ("001E3A2A", "FF1E3A2A")
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
