#!/usr/bin/env bash
# Reconstruit l'arène pilote « Lisière de l'avant-poste » (reproductible).
#   tools/arena/build_arena.sh [python_avec_bpy] [SS=3] [échantillons=40]
# 1. Blender (module bpy 5.2.3) : plans rendus ; 2. passe pixel + palette de l'exploration ;
# 3. copie dans art/arena/lisiere/ ; 4. planche-guide pour l'illustration.
set -euo pipefail
PY="${1:-python3}"; SS="${2:-3}"; SAMPLES="${3:-40}"
TMP="$(mktemp -d)"
"$PY" tools/arena/arena_blender.py "$TMP/rendu" "$SS" "$SAMPLES" | grep "arène rendue"
python3 tools/arena/arena_paint.py "$TMP/rendu" "$TMP/peint" "$SS"
mkdir -p art/arena/lisiere docs/media/arena
cp "$TMP"/peint/{base,loin,lisiere,avant}.png "$TMP/peint/arena.json" art/arena/lisiere/
python3 tools/arena/guide_overlay.py "$TMP/peint" docs/media/arena/guide_illustration.png
cp "$TMP/peint/apercu.png" docs/media/arena/apercu_natif.png
rm -rf "$TMP"
