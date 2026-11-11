#!/bin/bash
# Val'Serra — mesure GPU des variantes de caméra A et C (Godot 4.7.2) ; équivalent Linux/macOS de mesure_gpu.bat.
# Usage : tools/perf/mesure_gpu.sh /chemin/vers/godot   → mesures_gpu/RESUME_GPU.md
set -u
GODOT="${1:?chemin de l'exécutable Godot 4.7.2}"
PROJ="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$PROJ/mesures_gpu"
mkdir -p "$OUT"
run() {  # variante rendu paysage étiquette [options Godot…]
	local v="$1" r="$2" p="$3" t="$4"; shift 4
	echo "  variante $v — rendu $r — paysage $p ($t)"
	"$GODOT" --path "$PROJ" --rendering-method "$r" --resolution 1280x720 "$@" "res://scenes/explore25/camera_variante_$v.tscn" \
		-- --route=temoin --quit --nodebug --paysage="$p" --tag="$t" --out="$OUT" > "$OUT/journal_${v}_${p}_${t}.txt" 2>&1
}
run C forward_plus     3d    fplus       --disable-vsync
run A forward_plus     3d    fplus       --disable-vsync
run C gl_compatibility 3d    compat      --disable-vsync
run A gl_compatibility 3d    compat      --disable-vsync
run C forward_plus     aucun fplus       --disable-vsync
run C forward_plus     3d    fplus_ecran --disable-vsync --fullscreen
run C forward_plus     3d    fplus_vsync
"$GODOT" --headless --path "$PROJ" --script res://tools/perf/resume_gpu.gd -- --dir="$OUT"
echo "Fichier à renvoyer : $OUT/RESUME_GPU.md"
