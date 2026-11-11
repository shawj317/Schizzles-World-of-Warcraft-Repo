#!/usr/bin/env python3
"""Compare the Lua planner with tools/plan.py and check the discount curve."""

import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import plan  # noqa: E402

ROOT = os.path.normpath(os.path.join(HERE, "..", "AddOns", "SkillLedger"))


def lua_lines():
    script = os.path.join(HERE, "test_plan.lua")
    out = subprocess.check_output(["lua", script], text=True)
    return [line.strip() for line in out.splitlines() if line.strip()]


def test_discount():
    assert plan.apply_discount(20, 1) == 19  # Friendly 5%
    assert plan.apply_discount(20, 2) == 18  # Honored 10%
    assert plan.apply_discount(20, 3) == 17  # Revered 15%
    assert plan.apply_discount(20, 4) == 16  # Exalted 20%
    assert plan.apply_discount(10, 1) == 9   # floor(9.5)
    assert plan.apply_discount(10, 4) == 8   # floor(8)
    assert plan.apply_discount(1, 4) == 0
    assert plan.apply_discount(20, 0) == 20


def fixture():
    return {
        "professions": [
            {"id": 129, "name": "First Aid", "secondary": True, "gathering": False},
            {"id": 164, "name": "Blacksmithing", "secondary": False, "gathering": False},
        ],
        "items": {2589: "Linen Cloth", 2770: "Copper Ore", 2840: "Copper Bar", 3371: "Empty Vial"},
        "vendor": {
            3371: {
                "price": 20,
                "factions": [
                    {"id": 72, "name": "Stormwind", "side": "Alliance"},
                    {"id": 76, "name": "Orgrimmar", "side": "Horde"},
                    {"id": 470, "name": "Ratchet", "side": "Neutral"},
                ],
            }
        },
        "recipes": [
            {"spell": 3275, "skill": 129, "name": "Linen Bandage", "orange": 1, "yellow": 30, "green": 45, "grey": 60, "ups": 1, "made": 1251, "count": 1, "reagents": [(2589, 1)], "classMask": 0, "raceMask": 0, "skillup": True, "rankSource": "wowhead"},
            {"spell": 3276, "skill": 129, "name": "Heavy Linen Bandage", "orange": 40, "yellow": 50, "green": 75, "grey": 100, "ups": 1, "made": 2581, "count": 1, "reagents": [(2589, 2)], "classMask": 0, "raceMask": 0, "skillup": True, "rankSource": "wowhead"},
            {"spell": 2657, "skill": 186, "name": "Smelt Copper", "orange": 1, "yellow": 25, "green": 47, "grey": 70, "ups": 1, "made": 2840, "count": 1, "reagents": [(2770, 1)], "classMask": 0, "raceMask": 0, "skillup": True, "rankSource": "wowhead"},
            {"spell": 2662, "skill": 164, "name": "Copper Chain Pants", "orange": 1, "yellow": 1, "green": 20, "grey": 40, "ups": 1, "made": 2852, "count": 1, "reagents": [(2840, 2)], "classMask": 0, "raceMask": 0, "skillup": True, "rankSource": "test"},
        ],
    }


def test_vendor_choice():
    data = fixture()
    state = plan.prepare_state(data, {}, {}, {76: 5, 72: 8}, {}, "Horde", 1, 2)
    unit, info = plan.vendor_quote(state, 3371)
    assert unit == 19, unit
    assert info["faction"] == "Orgrimmar"
    assert info["discount"] == 5
    # Alliance exalted would be 16, and must be ignored for a Horde buyer.
    state_hostile = plan.prepare_state(data, {}, {}, {76: 2, 470: 4}, {}, "Horde", 1, 2)
    unit, info = plan.vendor_quote(state_hostile, 3371)
    assert unit == 20 and info["faction"] == "Ratchet"
    captured = plan.prepare_state(
        data, {}, {}, {76: 5},
        {3371: {"unit": 15, "factionId": 76, "faction": "Orgrimmar", "standingId": 5}},
        "Horde", 1, 2,
    )
    unit, info = plan.vendor_quote(captured, 3371)
    assert unit == 15 and info["source"] == "merchant"
    moved = plan.prepare_state(
        data, {}, {}, {76: 6},
        {3371: {"unit": 19, "factionId": 76, "faction": "Orgrimmar", "standingId": 5}},
        "Horde", 1, 2,
    )
    unit, info = plan.vendor_quote(moved, 3371)
    assert unit == 18 and info["source"] == "vendor" and info["discount"] == 10


def test_paths_match_lua():
    data = fixture()
    plans, _shopping = plan.plan_character(
        data, {2589: 10},
        [{"name": "First Aid", "skillLine": 129, "rank": 1, "maxRank": 50}],
        {2589: 100}, {76: 5, 72: 8}, {}, "Horde", 1, 2,
    )
    plan_fa = plans[0]
    assert plan_fa["steps"][0]["spell"] == 3275
    assert plan_fa["steps"][0]["start"] == 1
    assert plan_fa["steps"][0]["end"] == 46
    assert plan_fa["steps"][1]["spell"] == 3276
    assert plan_fa["steps"][1]["start"] == 46
    # 10 linen from bags cover the first 10 orange crafts.
    assert plan_fa["steps"][0]["reagents"][0]["fromStock"] == 10
    plans_bs, _ = plan.plan_character(
        data, {},
        [{"name": "Blacksmithing", "skillLine": 164, "rank": 1, "maxRank": 4}],
        {2770: 30, 2840: 100}, {}, {}, "Horde", 1, 2,
    )
    notes = " ".join(plans_bs[0]["steps"][0]["notes"])
    assert "crafting Copper Bar beats buying" in notes
    plans_buy, _ = plan.plan_character(
        data, {},
        [{"name": "Blacksmithing", "skillLine": 164, "rank": 1, "maxRank": 2}],
        {2770: 30, 2840: 10}, {}, {}, "Horde", 1, 2,
    )
    notes = " ".join(plans_buy[0]["steps"][0]["notes"])
    assert "buying Copper Bar beats crafting" in notes

    lines = lua_lines()
    discount = [line for line in lines if line.startswith("DISCOUNT")]
    assert discount[0] == "DISCOUNT 20 1 19"
    assert discount[3] == "DISCOUNT 20 4 16"
    assert discount[4] == "DISCOUNT 10 1 9"
    assert any(line.startswith("STEP 3275 1 46 ") for line in lines)
    assert any(line.startswith("STEP 3276 46 50 ") for line in lines)
    lua_total = int(next(line.split()[1] for line in lines if line.startswith("TOTAL")))
    assert lua_total == plan_fa["total"]
    bs = next(line for line in lines if line.startswith("BSNOTE"))
    assert "crafting Copper Bar beats buying" in bs
    buy = next(line for line in lines if line.startswith("BUYNOTE"))
    assert "buying Copper Bar beats crafting" in buy


if __name__ == "__main__":
    test_discount()
    test_vendor_choice()
    test_paths_match_lua()
    print("plan tests passed")
