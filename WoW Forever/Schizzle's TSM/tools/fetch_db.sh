#!/usr/bin/env bash
# Downloads the WoW Forever client tables the builder reads (wago.tools, product wowf).
set -euo pipefail
BUILD="${BUILD:-1.60.1.70790}"
DIR="$(cd "$(dirname "$0")" && pwd)/db"; mkdir -p "$DIR"
for t in ItemSparse Item SkillLineAbility SpellEffect SpellReagents SpellName ItemEffect ItemXItemEffect SkillLine; do
  curl -fsSL "https://wago.tools/db2/$t/csv?build=$BUILD" -o "$DIR/$t.csv"
done
echo "saved to $DIR"
