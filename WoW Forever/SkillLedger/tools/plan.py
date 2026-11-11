"""Cheapest profession path.

The same rules are implemented in AddOns/SkillLedger/Plan.lua. tests/test_plan.py
checks the two against one fixture.

Reputation discount, Classic client curve from patch 2.3 onward (also what
WoW Classic uses), confirmed on Wowpedia "Faction discount" and Warcraft Wiki
"Reputation":

    Friendly 5%, Honored 10%, Revered 15%, Exalted 20%.
    Neutral and below: no discount.
    Unfriendly and worse: that vendor will not sell.

The client truncates: floor(base * (20 - steps) / 20), where steps is 1..4.
A price captured from the merchant window is what that vendor charged at the
standing saved with it. It is used as-is while that standing is unchanged,
because it is the client's own number. If the standing later moves, the
capture is stale and the catalog price is discounted again.

Original 1.12, before patch 2.3, was a flat 10% from Honored only. Forever's
server is not in the client tables. This planner follows the 5/10/15/20 curve
Jon asked for. A fresh merchant capture replaces it when the standing matches.
No goblin racial and no PvP-rank discount.
"""

from __future__ import annotations

import math

STANDING_NAME = {
    1: "Hated",
    2: "Hostile",
    3: "Unfriendly",
    4: "Neutral",
    5: "Friendly",
    6: "Honored",
    7: "Revered",
    8: "Exalted",
}


def discount_steps(standing):
    if standing == 5:
        return 1
    if standing == 6:
        return 2
    if standing == 7:
        return 3
    if standing == 8:
        return 4
    return 0


def discount_percent(standing):
    return discount_steps(standing) * 5


def apply_discount(base, steps):
    if base is None:
        return None
    base = int(base)
    if steps <= 0:
        return base
    if steps > 4:
        steps = 4
    return (base * (20 - steps)) // 20


def standing_name(standing):
    if standing is None:
        return ""
    return STANDING_NAME.get(int(standing), "")


def allows(mask, bit):
    if not mask or mask < 0:
        return True
    if not bit:
        return True
    return (mask % (bit * 2)) >= bit


def opposite(side):
    if side == "Horde":
        return "Alliance"
    if side == "Alliance":
        return "Horde"
    return None


def item_name(state, item_id):
    return state["items"].get(item_id) or state["items"].get(str(item_id)) or f"Item {item_id}"


def vendor_quote(state, item_id):
    """Return (unit, info) for a vendor purchase, or (None, None)."""
    catalog = state["vendor"].get(item_id)
    captured = state["captured"].get(item_id)
    if captured and captured.get("unit"):
        faction_id = captured.get("factionId")
        standing_now = None
        if faction_id is not None:
            standing_now = state["standings"].get(faction_id)
        if faction_id is None or standing_now is None or standing_now == captured.get("standingId"):
            standing = captured.get("standingId")
            return captured["unit"], {
                "source": "merchant",
                "base": catalog["price"] if catalog else None,
                "discount": discount_percent(standing) if standing else 0,
                "factionId": faction_id,
                "faction": captured.get("faction") or "",
                "standing": standing_name(standing),
                "assumed": False,
            }
    if not catalog or not catalog.get("price"):
        if captured and captured.get("unit"):
            return captured["unit"], {
                "source": "merchant",
                "base": None,
                "discount": 0,
                "factionId": captured.get("factionId"),
                "faction": captured.get("faction") or "",
                "standing": standing_name(captured.get("standingId")),
                "assumed": False,
            }
        return None, None
    base = int(catalog["price"])
    factions = catalog.get("factions") or []
    if not factions:
        return base, {
            "source": "vendor-nofaction",
            "base": base,
            "discount": 0,
            "factionId": None,
            "faction": "",
            "standing": "Neutral",
            "assumed": True,
        }
    blocked = opposite(state.get("side") or "")
    best = None
    for faction in factions:
        if blocked and faction.get("side") == blocked:
            continue
        standing = state["standings"].get(faction["id"])
        assumed = standing is None
        if standing is None:
            standing = 4
        if standing < 4:
            continue
        unit = apply_discount(base, discount_steps(standing))
        chosen = {
            "source": "vendor-assumed" if assumed else "vendor",
            "base": base,
            "discount": discount_percent(standing),
            "factionId": faction["id"],
            "faction": faction.get("name") or "",
            "standing": standing_name(standing),
            "assumed": assumed,
            "unit": unit,
        }
        if best is None or unit < best["unit"] or (unit == best["unit"] and faction["id"] < best["factionId"]):
            best = chosen
    if not best:
        return None, None
    return best.pop("unit"), best


def buy_quote(state, item_id):
    vendor_unit, info = vendor_quote(state, item_id)
    ah = state["prices"].get(item_id)
    ah_source = (state.get("price_sources") or {}).get(item_id) or "ah"
    if vendor_unit is not None and ah:
        if ah < vendor_unit:
            return ah, {"source": ah_source, "base": None, "discount": 0, "factionId": None, "faction": "", "standing": "", "assumed": False}
        return vendor_unit, info
    if vendor_unit is not None:
        return vendor_unit, info
    if ah:
        return ah, {"source": ah_source, "base": None, "discount": 0, "factionId": None, "faction": "", "standing": "", "assumed": False}
    return None, None


def best_craft(state, item_id, seen):
    if item_id in seen:
        return None, None
    makers = state["made_by"].get(item_id) or []
    if not makers:
        return None, None
    seen.add(item_id)
    best_unit = None
    best_recipe = None
    for recipe in makers:
        count = recipe["count"] or 0
        if count <= 0:
            continue
        total = 0.0
        ok = True
        for reagent_id, reagent_count in recipe["reagents"]:
            unit = leaf_unit(state, reagent_id, seen)
            if unit is None:
                ok = False
                break
            total += unit * reagent_count
        if not ok:
            continue
        each = total / count
        if best_unit is None or each < best_unit or (each == best_unit and recipe["spell"] < best_recipe["spell"]):
            best_unit = each
            best_recipe = recipe
    seen.remove(item_id)
    return best_unit, best_recipe


def leaf_unit(state, item_id, seen):
    buy_unit, _info = buy_quote(state, item_id)
    craft_unit, _recipe = best_craft(state, item_id, seen)
    choices = [unit for unit in (buy_unit, craft_unit) if unit is not None]
    if not choices:
        return None
    return min(choices)


def discount_label(name, info):
    if not info:
        return ""
    source = info.get("source") or ""
    percent = info.get("discount") or 0
    faction = info.get("faction") or ""
    standing = info.get("standing") or ""
    if source == "merchant":
        where = ", ".join(part for part in (standing, faction) if part)
        return f"{name}: merchant price" + (f" ({where})" if where else "")
    if source == "vendor-nofaction":
        return f"{name}: vendor price, faction unknown, no discount"
    if source in ("vendor", "vendor-assumed"):
        assumed = " (standing not saved, treated as Neutral)" if info.get("assumed") else ""
        if percent:
            return f"{name}: {percent}% {standing}, {faction}{assumed}"
        return f"{name}: no discount, {standing}, {faction}{assumed}"
    return ""


def acquire(state, item_id, count, seen, bag, bought, pay, unpriced, notes, discounts):
    if count <= 1e-9:
        return
    name = item_name(state, item_id)
    have = state["inventory"].get(item_id, 0.0)
    orig = state["original"].get(item_id, 0.0)
    from_orig = min(count, orig, have)
    if from_orig > 0:
        state["original"][item_id] = orig - from_orig
        state["inventory"][item_id] = have - from_orig
        bag[item_id] = bag.get(item_id, 0.0) + from_orig
        have -= from_orig
        orig -= from_orig
    from_crafted = min(count - from_orig, max(0.0, have - orig))
    if from_crafted > 0:
        state["inventory"][item_id] = have - from_crafted
    need = count - from_orig - from_crafted
    if need <= 1e-9:
        return
    buy_unit, buy_info = buy_quote(state, item_id)
    craft_unit, craft_recipe = best_craft(state, item_id, seen)
    use_craft = craft_recipe is not None and (buy_unit is None or (craft_unit is not None and craft_unit < buy_unit - 1e-9))
    if use_craft:
        if buy_unit is not None:
            notes.add(f"crafting {name} beats buying it")
        crafts = need / craft_recipe["count"]
        seen.add(item_id)
        for reagent_id, reagent_count in craft_recipe["reagents"]:
            acquire(state, reagent_id, reagent_count * crafts, seen, bag, bought, pay, unpriced, notes, discounts)
        seen.discard(item_id)
        return
    if buy_unit is not None:
        if craft_unit is not None:
            notes.add(f"buying {name} beats crafting it")
        pay[0] += need * buy_unit
        bought[item_id] = bought.get(item_id, 0.0) + need
        label = discount_label(name, buy_info)
        if label:
            discounts.add(label)
        return
    unpriced.add(name)


def chance(recipe, skill):
    if skill < recipe["orange"] or skill >= recipe["grey"]:
        return 0.0
    yellow = recipe["yellow"]
    grey = recipe["grey"]
    if grey <= yellow:
        return 1.0
    value = (grey - skill) / (grey - yellow)
    if value > 1:
        return 1.0
    if value < 0:
        return 0.0
    return value


def color_at(recipe, skill):
    if skill < recipe["yellow"]:
        return "orange"
    if skill < recipe["green"]:
        return "yellow"
    if skill < recipe["grey"]:
        return "green"
    return "grey"


def clone_counts(state):
    return {
        "inventory": dict(state["inventory"]),
        "original": dict(state["original"]),
    }


def restore_counts(state, saved):
    state["inventory"] = saved["inventory"]
    state["original"] = saved["original"]


def cost_crafts(state, recipe, crafts):
    bag, bought = {}, {}
    pay = [0.0]
    unpriced, notes, discounts = set(), set(), set()
    seen = set()
    for reagent_id, reagent_count in recipe["reagents"]:
        acquire(state, reagent_id, reagent_count * crafts, seen, bag, bought, pay, unpriced, notes, discounts)
    made = recipe.get("made") or 0
    count = recipe.get("count") or 0
    if made and count:
        state["inventory"][made] = state["inventory"].get(made, 0.0) + crafts * count
    return {
        "pay": pay[0],
        "bag": bag,
        "bought": bought,
        "unpriced": unpriced,
        "notes": notes,
        "discounts": discounts,
    }


def eligible(recipe, skill, state):
    if recipe.get("skillup") is False:
        return False
    if skill < recipe["orange"] or skill >= recipe["grey"]:
        return False
    if not allows(recipe.get("classMask") or 0, state.get("class_mask") or 0):
        return False
    if not allows(recipe.get("raceMask") or 0, state.get("race_mask") or 0):
        return False
    return chance(recipe, skill) > 0


def iround(value):
    return int(math.floor(value + 0.5))


def plan_profession(state, skill_id, rank, cap):
    recipes = [recipe for recipe in state["recipes"] if recipe["skill"] == skill_id]
    recipes.sort(key=lambda recipe: recipe["spell"])
    prof = next((row for row in state["professions"] if row["id"] == skill_id), None)
    name = prof["name"] if prof else str(skill_id)
    gathering = bool(prof and prof.get("gathering"))
    notes = []
    if gathering and skill_id == 186:
        notes.append("Mining points also come from mining nodes. This path is only smelts and other crafts that grant Mining skill.")
    elif gathering:
        notes.append(f"{name} is a gathering skill. The client tables have no node-by-node craft path, so there is nothing to buy for the points that come from gathering.")
    rank = int(rank or 0)
    cap = int(cap or 0)
    if cap > 300:
        cap = 300
    if rank >= cap:
        return {
            "skill": skill_id,
            "name": name,
            "rank": rank,
            "cap": cap,
            "steps": [],
            "gaps": [],
            "notes": notes + [f"Already at {rank}, the current cap."],
            "total": 0,
            "unpriced": [],
        }
    steps_raw = []
    gaps = []
    skill = rank
    guard = 0
    while skill < cap and guard < 400:
        guard += 1
        best = None
        best_key = None
        best_saved = None
        best_crafts = None
        for recipe in recipes:
            if not eligible(recipe, skill, state):
                continue
            crafts = 1.0 / (chance(recipe, skill) * (recipe["ups"] or 1))
            saved = clone_counts(state)
            result = cost_crafts(state, recipe, crafts)
            restore_counts(state, saved)
            key = (1 if result["unpriced"] else 0, result["pay"], recipe["spell"])
            if best_key is None or key < best_key:
                best = recipe
                best_key = key
                best_saved = result
                best_crafts = crafts
        if best is None:
            gaps.append(skill)
            notes.append(f"No skill-up recipe from {skill} to {cap}.")
            break
        # Commit the chosen craft, then merge with the previous row when it is the same spell.
        committed = cost_crafts(state, best, best_crafts)
        row = {
            "spell": best["spell"],
            "recipe": best["name"],
            "start": skill,
            "end": skill + 1,
            "crafts": best_crafts,
            "color": color_at(best, skill),
            "pay": committed["pay"],
            "bag": committed["bag"],
            "bought": committed["bought"],
            "unpriced": set(committed["unpriced"]),
            "notes": set(committed["notes"]),
            "discounts": set(committed["discounts"]),
            "orange": best["orange"],
            "yellow": best["yellow"],
            "green": best["green"],
            "grey": best["grey"],
            "rankSource": best.get("rankSource") or "",
        }
        if steps_raw and steps_raw[-1]["spell"] == row["spell"]:
            prev = steps_raw[-1]
            prev["end"] = row["end"]
            prev["crafts"] += row["crafts"]
            prev["pay"] += row["pay"]
            for item_id, count in row["bag"].items():
                prev["bag"][item_id] = prev["bag"].get(item_id, 0.0) + count
            for item_id, count in row["bought"].items():
                prev["bought"][item_id] = prev["bought"].get(item_id, 0.0) + count
            prev["unpriced"].update(row["unpriced"])
            prev["notes"].update(row["notes"])
            prev["discounts"].update(row["discounts"])
        else:
            steps_raw.append(row)
        skill += 1
    steps = []
    running = 0
    unpriced = []
    for row in steps_raw:
        cost = iround(row["pay"])
        running += cost
        reagents = []
        item_ids = sorted(set(row["bag"]) | set(row["bought"]))
        for item_id in item_ids:
            reagents.append({
                "id": item_id,
                "name": item_name(state, item_id),
                "fromStock": row["bag"].get(item_id, 0.0),
                "buy": row["bought"].get(item_id, 0.0),
            })
        if row["unpriced"]:
            for missing in sorted(row["unpriced"]):
                if missing not in unpriced:
                    unpriced.append(missing)
        steps.append({
            "spell": row["spell"],
            "recipe": row["recipe"],
            "start": row["start"],
            "end": row["end"],
            "crafts": row["crafts"],
            "color": row["color"],
            "reagents": reagents,
            "cost": cost,
            "running": running,
            "unpriced": sorted(row["unpriced"]),
            "notes": sorted(row["notes"]),
            "discounts": sorted(row["discounts"]),
            "rankSource": row["rankSource"],
        })
    if rank < 300 and cap < 300 and skill >= cap and not gaps:
        notes.append(f"Stopped at {cap}, the current trained cap. The next trainer ranks are 75, 150, 225 and 300.")
    return {
        "skill": skill_id,
        "name": name,
        "rank": rank,
        "cap": cap,
        "steps": steps,
        "gaps": gaps,
        "notes": notes,
        "total": running,
        "unpriced": unpriced,
        "reached": skill,
    }


def prepare_state(data, inventory, prices, standings, captured, side, class_mask, race_mask, price_sources=None):
    made_by = {}
    for recipe in data["recipes"]:
        made = recipe.get("made") or 0
        if made and (recipe.get("count") or 0) > 0:
            made_by.setdefault(made, []).append(recipe)
    for makers in made_by.values():
        makers.sort(key=lambda recipe: recipe["spell"])
    clean_inv = {int(key): float(value) for key, value in (inventory or {}).items() if value}
    return {
        "recipes": data["recipes"],
        "professions": data["professions"],
        "items": {int(key): value for key, value in data["items"].items()},
        "vendor": {int(key): value for key, value in data["vendor"].items()},
        "made_by": made_by,
        "inventory": dict(clean_inv),
        "original": dict(clean_inv),
        "prices": {int(key): int(value) for key, value in (prices or {}).items() if value},
        "price_sources": {int(key): value for key, value in (price_sources or {}).items()},
        "standings": {int(key): int(value) for key, value in (standings or {}).items()},
        "captured": {int(key): value for key, value in (captured or {}).items()},
        "side": side or "",
        "class_mask": class_mask or 0,
        "race_mask": race_mask or 0,
    }


def fresh_counts(state, inventory):
    clean = {int(key): float(value) for key, value in (inventory or {}).items() if value}
    state["inventory"] = dict(clean)
    state["original"] = dict(clean)


def plan_character(data, inventory, professions, prices, standings, captured, side, class_mask, race_mask, price_sources=None):
    state = prepare_state(data, inventory, prices, standings, captured, side, class_mask, race_mask, price_sources)
    plans = []
    gross = {}
    for profession in professions:
        fresh_counts(state, inventory)
        skill_id = profession.get("skillLine") or profession.get("skill")
        if not skill_id:
            skill_id = next((row["id"] for row in data["professions"] if row["name"] == profession.get("name")), None)
        if not skill_id:
            continue
        cap = profession.get("maxRank") or profession.get("cap") or 300
        result = plan_profession(state, int(skill_id), profession.get("rank") or 0, cap)
        plans.append(result)
        for step in result["steps"]:
            for reagent in step["reagents"]:
                gross[reagent["id"]] = gross.get(reagent["id"], 0.0) + reagent["fromStock"] + reagent["buy"]
    shopping = []
    for item_id in sorted(gross):
        need = gross[item_id]
        have = float((inventory or {}).get(item_id) or (inventory or {}).get(str(item_id)) or 0)
        from_stock = min(have, need)
        buy = need - from_stock
        if buy < 1e-9:
            buy = 0.0
        buy_whole = int(math.ceil(buy - 1e-9)) if buy else 0
        unit, info = buy_quote(state, item_id)
        line = (buy_whole * unit) if unit is not None and buy_whole else 0
        shopping.append({
            "id": item_id,
            "name": item_name(state, item_id),
            "need": need,
            "fromStock": from_stock,
            "buy": buy,
            "buyWhole": buy_whole,
            "unit": unit,
            "cost": line,
            "source": (info or {}).get("source") or ("missing" if buy_whole else "stock"),
            "discount": (info or {}).get("discount") or 0,
            "faction": (info or {}).get("faction") or "",
            "standing": (info or {}).get("standing") or "",
            "base": (info or {}).get("base"),
            "assumed": bool((info or {}).get("assumed")),
        })
    return plans, shopping
