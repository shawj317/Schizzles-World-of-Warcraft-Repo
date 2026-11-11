#!/usr/bin/env python3
"""Export the sample SavedVariables and check the workbook."""

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from export import main  # noqa: E402

SAMPLE = os.path.join(HERE, "sample", "SkillLedger.lua")
OUT = os.path.join(HERE, "sample", "SkillLedger-test.xlsx")


def main_test():
    main([SAMPLE, "-o", OUT, "--csv"])
    from openpyxl import load_workbook
    book = load_workbook(OUT)
    assert book.sheetnames == [
        "Professions", "Inventory", "AH Prices", "Leveling Plan", "Shopping List", "Vendors",
    ]
    for name in book.sheetnames:
        assert book[name].freeze_panes == "A2"
    plan_sheet = book["Leveling Plan"]
    recipes = [row[4].value for row in plan_sheet.iter_rows(min_row=2)]
    assert "Smelt Copper" in recipes
    shopping = {row[2].value: row for row in book["Shopping List"].iter_rows(min_row=2)}
    vial = shopping["Empty Vial"]
    assert vial[7].value == "5%"
    assert vial[8].value == "Orgrimmar"
    assert vial[10].value == "19c"
    assert vial[12].value == "merchant"
    cloth = shopping["Linen Cloth"]
    assert cloth[4].value == 13  # 8 in bags + 5 in the bank, subtracted once
    vendors = book["Vendors"]
    found = False
    for row in vendors.iter_rows(min_row=2, values_only=True):
        if row[0] == "Standing" and row[2] == "Orgrimmar":
            assert row[4] == "Friendly" and row[5] == "5%"
            found = True
    assert found
    csv_dir = os.path.join(HERE, "sample", "SkillLedger-test-csv")
    assert os.path.isfile(os.path.join(csv_dir, "Vendors.csv"))
    os.remove(OUT)
    for name in os.listdir(csv_dir):
        os.remove(os.path.join(csv_dir, name))
    os.rmdir(csv_dir)
    print("export test passed")


if __name__ == "__main__":
    main_test()
