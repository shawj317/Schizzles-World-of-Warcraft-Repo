#!/usr/bin/env python3
"""Check Schizzle's MoP Classic import strings offline.

Decodes every WeakAura, Plater, and Details! string, compiles their Lua with
Lua 5.1 (the MoP Classic client language), and checks the TradeSkillMaster
group strings against the counts in the project READMEs.

Copyright (c) 2026 Jon Shaw (Schizzle)
https://github.com/shawj317/schizzles-mop-classic
"""

from __future__ import annotations

import math
import os
import re
import subprocess
import sys
import tempfile
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIBSERIALIZE = Path(
    os.environ.get(
        "LIBSERIALIZE_LUA",
        "/usr/local/share/schizzles-mop-classic/LibSerialize.lua",
    )
)

# LibDeflate EncodeForPrint alphabet: a-z, A-Z, 0-9, "(", ")".
_6BIT = {}
for _index, _char in enumerate(
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789()"
):
    _6BIT[ord(_char)] = _index

PROFESSIONS = {
    "alchemy": (281, 36),
    "blacksmithing": (763, 18),
    "enchanting": (383, 20),
    "engineering": (302, 14),
    "herbalism": (77, 7),
    "inscription": (596, 22),
    "jewelcrafting": (706, 22),
    "leatherworking": (871, 16),
    "mining": (80, 6),
    "skinning": (68, 6),
    "tailoring": (646, 16),
    "cooking": (422, 11),
    "fishing": (84, 6),
    "first-aid": (25, 2),
    "archaeology": (11, 1),
}
PETS = {
    "high-value": 45,
    "vendor": 100,
    "profession": 21,
    "world-drops": 39,
    "raid-dungeon": 32,
    "pandaria": 35,
    "holiday-events": 56,
    "supplies": 1,
}
ITEM_TOKEN = re.compile(r"^[ip]:\d+$")

PLATER_MODS = {
    "schizzles-plater-mod-01-stance-aware-threat.txt": "Schizzle's Stance-Aware Threat",
    "schizzles-plater-mod-02-target-focus-highlight.txt": "Schizzle's Target & Focus Highlight",
    "schizzles-plater-mod-03-interrupt-ready-glow.txt": "Schizzle's Interrupt Ready Glow",
    "schizzles-plater-mod-04-execute-touch-of-death.txt": "Schizzle's Execute & Touch of Death",
    "schizzles-plater-mod-05-threat-percent.txt": "Schizzle's Threat %",
}


class CheckError(Exception):
    pass


def expect(condition: bool, message: str) -> None:
    if not condition:
        raise CheckError(message)


def decode_for_print(encoded: str) -> bytes:
    """Inverse of LibDeflate:EncodeForPrint."""
    encoded = re.sub(r"^[\x00-\x20]+", "", encoded)
    encoded = re.sub(r"[\x00-\x20]+$", "", encoded)
    expect(len(encoded) > 1, "encoded string is too short")
    out = bytearray()
    index = 0
    length = len(encoded)
    while index <= length - 4:
        try:
            parts = [_6BIT[ord(encoded[index + offset])] for offset in range(4)]
        except KeyError as exc:
            raise CheckError(f"invalid import character {chr(exc.args[0])!r}") from exc
        cache = parts[0] + parts[1] * 64 + parts[2] * 4096 + parts[3] * 262144
        first = cache % 256
        cache = (cache - first) // 256
        second = cache % 256
        third = (cache - second) // 256
        out.extend((first, second, third))
        index += 4
    cache = 0
    bit_length = 0
    place = 1
    while index < length:
        try:
            value = _6BIT[ord(encoded[index])]
        except KeyError as exc:
            raise CheckError(f"invalid import character {chr(exc.args[0])!r}") from exc
        cache += value * place
        bit_length += 6
        place *= 64
        index += 1
    while bit_length >= 8:
        byte = cache % 256
        out.append(byte)
        cache = (cache - byte) // 256
        bit_length -= 8
    return bytes(out)


def inflate_import(text: str) -> bytes:
    body = text[6:] if text.startswith("!WA:2!") else text
    try:
        return zlib.decompress(decode_for_print(body), -15)
    except zlib.error as exc:
        raise CheckError(f"deflate decompress failed: {exc}") from exc


def unescape_ace(text: str) -> str:
    out: list[str] = []
    index = 0
    while index < len(text):
        if text[index] == "~":
            expect(index + 1 < len(text), "truncated AceSerializer escape")
            marker = text[index + 1]
            if marker == "|":
                out.append("~")
            elif marker == "}":
                out.append("^")
            elif marker == "?":
                out.append(chr(127))
            else:
                out.append(chr(ord(marker) - 64))
            index += 2
        else:
            out.append(text[index])
            index += 1
    return "".join(out)


def parse_ace_value(text: str, index: int):
    expect(text.startswith("^", index), f"expected ^ at {index}")
    kind = text[index + 1]
    index += 2
    if kind == "S":
        end = index
        while end < len(text) and text[end] != "^":
            end += 2 if text[end] == "~" else 1
        return unescape_ace(text[index:end]), end
    if kind == "N":
        end = text.find("^", index)
        if end < 0:
            end = len(text)
        raw = text[index:end]
        if raw in ("inf", "-inf", "nan") or any(char in raw for char in ".eE"):
            return float(raw), end
        return int(raw), end
    if kind == "F":
        # Exact float: ^F<mantissa>^f<exponent>, with exponent already shifted by -53.
        end = text.find("^", index)
        expect(text.startswith("^f", end), "float is missing its exponent")
        mantissa = int(text[index:end])
        index = end + 2
        end = text.find("^", index)
        if end < 0:
            end = len(text)
        return math.ldexp(mantissa, int(text[index:end])), end
    if kind == "B":
        return True, index
    if kind == "b":
        return False, index
    if kind == "Z":
        return None, index
    if kind == "T":
        table = {}
        while not text.startswith("^t", index):
            key, index = parse_ace_value(text, index)
            value, index = parse_ace_value(text, index)
            table[key] = value
        return table, index + 2
    raise CheckError(f"unknown AceSerializer type {kind!r}")


def parse_ace(blob: bytes) -> dict:
    text = blob.decode("latin1")
    expect(text.startswith("^1"), "AceSerializer payload is not version 1")
    value, end = parse_ace_value(text, 2)
    expect(text[end:] in ("", "^^"), f"trailing AceSerializer data {text[end:end + 20]!r}")
    expect(isinstance(value, dict), "AceSerializer payload is not a table")
    return value


def parse_tsm(path: Path) -> tuple[list[str], list[str]]:
    text = path.read_text()
    expect("\n" not in text and "\r" not in text, f"{path.name} is not a single line")
    text = text.strip()
    expect(text.startswith("group:"), f"{path.name} does not start with group:")
    groups: list[str] = []
    items: list[str] = []
    for token in text.split(","):
        if token.startswith("group:"):
            groups.append(token[len("group:") :])
        elif ITEM_TOKEN.fullmatch(token):
            items.append(token)
        else:
            raise CheckError(f"{path.name} has an unexpected token {token[:80]!r}")
    return groups, items


def compile_lua(chunks: list[tuple[str, str]]) -> int:
    if not chunks:
        return 0
    with tempfile.TemporaryDirectory(prefix="schizzle-lua-") as directory:
        directory_path = Path(directory)
        checker = directory_path / "check.lua"
        checker.write_text(
            "\n".join(
                [
                    "local index = 1",
                    "local compiled = 0",
                    "while arg[index] do",
                    "  local handle = assert(io.open(arg[index]))",
                    "  local source = handle:read('*a')",
                    "  handle:close()",
                    "  local fn, err = loadstring(source)",
                    "  if not fn then",
                    "    fn, err = loadstring('return (' .. source .. ')')",
                    "  end",
                    "  if not fn then",
                    "    io.stderr:write(arg[index] .. '\\n' .. tostring(err) .. '\\n')",
                    "    os.exit(1)",
                    "  end",
                    "  compiled = compiled + 1",
                    "  index = index + 1",
                    "end",
                    "print(compiled)",
                    "",
                ]
            )
        )
        paths = []
        for number, (label, source) in enumerate(chunks):
            file_path = directory_path / f"chunk-{number}.lua"
            file_path.write_text(source)
            # The label is recorded beside the chunk so a syntax error names it.
            (directory_path / f"chunk-{number}.label").write_text(label)
            paths.append(str(file_path))
        result = subprocess.run(
            ["lua5.1", str(checker), *paths],
            check=False,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            message = (result.stderr or result.stdout).strip()
            failed = message.splitlines()[0] if message else ""
            label = ""
            if failed.startswith(str(directory_path)):
                label_path = Path(failed).with_suffix(".label")
                if label_path.exists():
                    label = label_path.read_text().strip() + ": "
            raise CheckError(f"Lua 5.1 compile failed: {label}{message}")
        return int(result.stdout.strip())


def check_tsm() -> str:
    profession_dir = ROOT / "schizzles-tsm" / "groups" / "professions"
    pet_dir = ROOT / "schizzles-tsm" / "groups" / "pets"
    union: set[str] = set()
    for name, (item_count, group_count) in PROFESSIONS.items():
        groups, items = parse_tsm(profession_dir / f"schizzles-tsm-{name}.txt")
        unique = set(items)
        expect(len(groups) == group_count, f"{name} has {len(groups)} groups, expected {group_count}")
        expect(len(unique) == item_count, f"{name} has {len(unique)} items, expected {item_count}")
        expect(len(unique) == len(items), f"{name} repeats an item inside the group")
        overlap = unique & union
        expect(not overlap, f"{name} overlaps another profession ({len(overlap)} items)")
        union |= unique

    all_groups, all_items = parse_tsm(profession_dir / "schizzles-tsm-all-professions.txt")
    expect(len(all_groups) == 203, f"all-professions has {len(all_groups)} groups, expected 203")
    expect(set(all_items) == union, "all-professions items differ from the per-profession files")
    expect(len(all_items) == 5315, f"all-professions has {len(all_items)} items, expected 5315")
    expect(
        all(path.startswith("Schizzle's TSM`") for path in all_groups),
        "all-professions is not nested under Schizzle's TSM",
    )

    pet_union: set[str] = set()
    for name, item_count in PETS.items():
        groups, items = parse_tsm(pet_dir / f"schizzles-tsm-pets-{name}.txt")
        unique = set(items)
        expect(len(groups) == 1, f"pet group {name} has {len(groups)} groups, expected 1")
        expect(len(unique) == item_count, f"pet group {name} has {len(unique)} items, expected {item_count}")
        expect(len(unique) == len(items), f"pet group {name} repeats an item")
        pet_union |= unique

    pet_groups, pet_items = parse_tsm(pet_dir / "schizzles-tsm-battle-pets-all.txt")
    expect(len(pet_groups) == 8, f"all battle pets has {len(pet_groups)} groups, expected 8")
    expect(set(pet_items) == pet_union, "all battle pets differ from the subgroup files")
    expect(len(pet_items) == 329, f"all battle pets has {len(pet_items)} items, expected 329")
    species = sum(1 for item in pet_items if item.startswith("p:"))
    companions = sum(1 for item in pet_items if item.startswith("i:"))
    expect(species == 227 and companions == 102, f"battle pets are {species} species and {companions} items")
    expect(
        all(path.startswith("Schizzle's TSM`Battle Pets`") for path in pet_groups),
        "battle pets are not nested under Schizzle's TSM > Battle Pets",
    )
    expect(not (pet_union & union), "a battle pet item is also in a profession group")
    return (
        f"TSM: 5315 profession items in 203 groups, 329 battle pets "
        f"(227 species, 102 items), no duplicate or overlapping items"
    )


def check_plater_and_details() -> str:
    chunks: list[tuple[str, str]] = []
    profile = parse_ace(inflate_import((ROOT / "schizzles-plater-profile" / "schizzles-plater-profile.txt").read_text()))
    expect(
        profile.get("profile_name") == "Schizzle's Monk Plater Profile",
        f"Plater profile name is {profile.get('profile_name')!r}",
    )

    mod_dir = ROOT / "schizzles-plater-profile" / "schizzles-plater-mods"
    hook_count = 0
    for filename, mod_name in PLATER_MODS.items():
        mod = parse_ace(inflate_import((mod_dir / filename).read_text()))
        expect(mod.get("1") == mod_name, f"{filename} name is {mod.get('1')!r}")
        expect(mod.get("4") == "Schizzle (Jon)", f"{filename} author is {mod.get('4')!r}")
        hooks = mod.get("9")
        expect(isinstance(hooks, dict) and hooks, f"{filename} has no hooks")
        for hook_name, source in hooks.items():
            expect(isinstance(source, str) and source.strip(), f"{filename} hook {hook_name} is empty")
            chunks.append((f"{filename}:{hook_name}", source))
            hook_count += 1

    details = parse_ace(
        inflate_import(
            (ROOT / "schizzles-brewmaster-details-profile" / "schizzles-brewmaster-details-profile.txt").read_text()
        )
    )
    instances = details["profile"]["instances"]
    expect(set(instances) == {1, 2}, f"Details windows are {sorted(instances)}")
    for window_id in (1, 2):
        window = instances[window_id]
        position = window["posicao"]["normal"]
        expect(position["w"] == 232 and position["h"] == 176, f"window {window_id} is not 232x176")
        row = window["row_info"]
        expect(row["height"] == 18, f"window {window_id} bar height is {row['height']}")
        expect(row["font_size"] == 9, f"window {window_id} font size is {row['font_size']}")
        expect(row["font_face"] == "Fira Sans Condensed Medium", f"window {window_id} font is {row['font_face']!r}")
        expect(row["texture"] == "Details Flat", f"window {window_id} texture is {row['texture']!r}")
    expect(
        details["globaData"]["parser_options"]["tank_avoidance"] is True,
        "Details tank avoidance recording is off",
    )

    display = parse_ace(
        inflate_import(
            (ROOT / "schizzles-brewmaster-details-profile" / "schizzles-tank-mitigation-details-display.txt").read_text()
        )
    )
    expect(display.get("name") == "Tank Mitigation", f"custom display name is {display.get('name')!r}")
    expect(display.get("author") == "Jon", f"custom display author is {display.get('author')!r}")
    for field in ("script", "total_script", "percent_script", "tooltip"):
        source = display.get(field)
        expect(isinstance(source, str) and source.strip(), f"Tank Mitigation {field} is empty")
        chunks.append((f"tank-mitigation:{field}", source))

    compiled = compile_lua(chunks)
    expect(compiled == hook_count + 4, f"compiled {compiled} Lua chunks, expected {hook_count + 4}")
    return (
        f"Plater: profile plus {len(PLATER_MODS)} mods, {hook_count} hooks compiled; "
        f"Details: two 232x176 windows, tank avoidance on, Tank Mitigation display compiled"
    )


def check_weakaura() -> str:
    expect(LIBSERIALIZE.is_file(), f"LibSerialize is not installed at {LIBSERIALIZE}")
    blob = inflate_import(
        (ROOT / "schizzles-monk-rotation-weakaura" / "schizzles-monk-rotation-weakaura.txt").read_text()
    )
    with tempfile.TemporaryDirectory(prefix="schizzle-wa-") as directory:
        directory_path = Path(directory)
        blob_path = directory_path / "weakaura.bin"
        blob_path.write_bytes(blob)
        driver = directory_path / "check.lua"
        driver.write_text(
            "\n".join(
                [
                    "local LibSerialize = dofile(arg[1])",
                    "local handle = assert(io.open(arg[2], 'rb'))",
                    "local data = handle:read('*a')",
                    "handle:close()",
                    "local ok, aura = LibSerialize:Deserialize(data)",
                    "if not ok then error(aura) end",
                    "local display = aura.d",
                    "if type(display) ~= 'table' then error('missing display table') end",
                    "if display.id ~= \"Schizzle's Monk Rotation WeakAura\" then",
                    "  error('group id is ' .. tostring(display.id))",
                    "end",
                    "if aura.s ~= '5.22.1' then error('WeakAuras version is ' .. tostring(aura.s)) end",
                    "local children = aura.c",
                    "if type(children) ~= 'table' then error('missing children') end",
                    "local child_count = 0",
                    "for _ in pairs(children) do child_count = child_count + 1 end",
                    "if child_count ~= 22 then error('aura count is ' .. child_count) end",
                    "local version_line",
                    "local compiled = 0",
                    "local function consider(source)",
                    "  if type(source) ~= 'string' or #source < 20 then return end",
                    "  if not (source:find('function', 1, true) or source:find('aura_env', 1, true) or source:find('SchizzleMonk', 1, true)) then",
                    "    return",
                    "  end",
                    "  local fn, err = loadstring(source)",
                    "  if not fn then fn, err = loadstring('return (' .. source .. ')') end",
                    "  if not fn then error(err .. '\\n' .. source:sub(1, 160)) end",
                    "  compiled = compiled + 1",
                    "  local found = source:match('[^\\n]*local VERSION[^\\n]*')",
                    "  if found then version_line = found end",
                    "end",
                    "local function walk(value)",
                    "  if type(value) == 'string' then",
                    "    consider(value)",
                    "  elseif type(value) == 'table' then",
                    "    for _, child in pairs(value) do walk(child) end",
                    "  end",
                    "end",
                    "walk(aura)",
                    "if version_line ~= 'local VERSION = 5' then",
                    "  error('engine version line is ' .. tostring(version_line))",
                    "end",
                    "if compiled < 1 then error('no WeakAura Lua compiled') end",
                    "print(display.id)",
                    "print(child_count)",
                    "print(compiled)",
                    "print(version_line)",
                    "",
                ]
            )
        )
        result = subprocess.run(
            ["lua5.1", str(driver), str(LIBSERIALIZE), str(blob_path)],
            check=False,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            raise CheckError((result.stderr or result.stdout).strip())
        lines = [line for line in result.stdout.splitlines() if line]
        expect(len(lines) == 4, f"unexpected WeakAura checker output: {lines}")
        group_id, child_count, compiled, version_line = lines
        return (
            f"WeakAuras: {group_id}, {child_count} auras, {compiled} Lua chunks compiled, {version_line}"
        )


def main() -> int:
    try:
        reports = [check_tsm(), check_weakaura(), check_plater_and_details()]
    except (CheckError, OSError, KeyError, ValueError, subprocess.SubprocessError) as exc:
        print(f"verify_imports: {exc}", file=sys.stderr)
        return 1
    for report in reports:
        print(report)
    print("verify_imports: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
