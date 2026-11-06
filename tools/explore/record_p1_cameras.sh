#!/usr/bin/env bash
# P1 — vidéos et mesures de comparaison des caméras (zone de test agrandie), reproductible.
#   tools/explore/record_p1_cameras.sh [dossier_sortie]
# Produit :
#   p1_cameras_ABC.mp4            : MÊME parcours clavier court (touches simulées, 30 i/s fixes), A puis B puis C (960×540)
#   p1_cameras_cote_a_cote.mp4    : les trois synchronisées image par image (2×2 : A, B, C), même parcours
#   mesures_{30,60,144}ips.json   : mesures du parcours complet (caméra, collisions, groupe, dialogue)
# Nécessite godot (4.5) dans le PATH ; sans écran, xvfb-run et ffmpeg.
set -euo pipefail
OUT="${1:-docs/media/p1_camera}"
mkdir -p "$OUT"
RUN="godot"
if [ -z "${DISPLAY:-}" ]; then RUN="xvfb-run -a -s '-screen 0 1280x720x24' godot --rendering-driver opengl3"; fi
TMP="$(mktemp -d)"

for f in 30 60 144; do  # mesures sans rendu (la fenêtre est ramenée à 1280×720 par le parcours)
  godot --headless --fixed-fps "$f" --path . -- --start=p1-zone --course=p1 \
    --course-out="$OUT/mesures_${f}ips.json" | grep -E "P1 (VERDICT|.*ÉCHEC)" || true
done

for p in A B C; do
  eval "$RUN --fixed-fps 30 --write-movie '$TMP/$p.avi' --path . -- --start=p1-zone --course=p1 --course-short --cam=$p" >/dev/null 2>&1 || true
  ffmpeg -loglevel error -y -i "$TMP/$p.avi" -c:v libx264 -pix_fmt yuv420p -crf 23 "$TMP/$p.mp4"
  rm -f "$TMP/$p.avi"
done
printf "file '%s'\n" "$TMP/A.mp4" "$TMP/B.mp4" "$TMP/C.mp4" > "$TMP/list.txt"
ffmpeg -loglevel error -y -f concat -safe 0 -i "$TMP/list.txt" -vf scale=960:540 -c:v libx264 -preset slow -crf 30 -pix_fmt yuv420p "$OUT/p1_cameras_ABC.mp4"
ffmpeg -loglevel error -y -i "$TMP/A.mp4" -i "$TMP/B.mp4" -i "$TMP/C.mp4" \
  -filter_complex "[0]scale=640:360[a];[1]scale=640:360[b];[2]scale=640:360[c];color=c=0x101018:s=640x360[k];[a][b][c][k]xstack=inputs=4:layout=0_0|w0_0|0_h0|w0_h0:shortest=1" \
  -c:v libx264 -preset slow -crf 28 -pix_fmt yuv420p "$OUT/p1_cameras_cote_a_cote.mp4"
rm -rf "$TMP"
echo "Sorties dans $OUT"
