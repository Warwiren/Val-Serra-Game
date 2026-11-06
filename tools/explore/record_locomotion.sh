#!/usr/bin/env bash
# Vidéos et mesures de locomotion de l'exploration HD-2D (reproductible).
#   tools/explore/record_locomotion.sh [dossier_sortie]
# Produit :
#   locomotion_manuel.mp4 / .json : parcours CLAVIER (vraies touches simulées, sans autoplay), 30 i/s
#   demo_auto.mp4                 : démo automatique (A* simplifié), dialogue, contact du monstre, combat
#   mesures_{30,60,144}ips.json   : mêmes mesures à trois cadences (indépendance au nombre d'images/s)
# Nécessite godot (4.5) dans le PATH ; sans écran, xvfb-run et ffmpeg.
set -euo pipefail
OUT="${1:-docs/media/exploration/locomotion}"
mkdir -p "$OUT"
RUN="godot"
if [ -z "${DISPLAY:-}" ]; then RUN="xvfb-run -a -s '-screen 0 1280x720x24' godot --rendering-driver opengl3"; fi
TMP="$(mktemp -d)"

for f in 30 60 144; do
  godot --headless --fixed-fps "$f" --path . -- --start=hd2d-zone --course=manuel \
    --course-out="$OUT/mesures_${f}ips.json" | grep -E "COURSE (VERDICT|CRITÈRE)" || true
done

eval "$RUN --fixed-fps 30 --write-movie '$TMP/manuel.avi' --path . -- --start=hd2d-zone --course=manuel --course-out='$OUT/locomotion_manuel.json'" >/dev/null 2>&1 || true
ffmpeg -loglevel error -y -i "$TMP/manuel.avi" -c:v libx264 -pix_fmt yuv420p -crf 20 "$OUT/locomotion_manuel.mp4"

eval "$RUN --fixed-fps 30 --write-movie '$TMP/demo.avi' --quit-after 2100 --path . -- --start=hd2d-zone --autoplay" >/dev/null 2>&1 || true
ffmpeg -loglevel error -y -i "$TMP/demo.avi" -c:v libx264 -pix_fmt yuv420p -crf 22 "$OUT/demo_auto.mp4"
rm -rf "$TMP"
echo "Sorties dans $OUT"
