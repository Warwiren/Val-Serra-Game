#!/bin/bash
# P8.0-C — Série complète de non-régression (sans rendu : --headless), une ligne OK / ÉCHEC par contrôle.
# À lancer depuis la racine du projet :   bash tools/p8/non_regression_p80c.sh
# Variable GODOT pour un autre exécutable (défaut : godot). Journaux dans $SORTIE (défaut : un dossier temporaire).
# Durée : environ 25 min sur un processeur courant. Code de sortie 0 si tout est OK.
#
# Contrôles : chargement de la scène F5 ; 76 tests unitaires ; tutoriel (e2e ouverture et saut) ; sondes du Colisée ;
# sondes, trajets et portail ville <-> Colisée en caméra A et B ; stabilité des examens E (0 px) en lumière A et B ;
# escamotage (Aren jamais masqué, aucun clignotement) ; cadrage (Aren jamais masqué) ; profils de lumière A / B et F4 ;
# tests « smoke » de la forêt, des animations, des sols et du combat.
# Empreintes de scène (comparaison avant / après un nettoyage) : voir tools/p8/empreinte_scene_p80c.gd.

GODOT=${GODOT:-godot}
SORTIE=${SORTIE:-$(mktemp -d)}
mkdir -p "$SORTIE"
VILLE=res://scenes/p7/ville_v07b.tscn
ECHECS=0

bilan() {   # bilan <nom> <0|1> <détail>
	if [ "$2" = "0" ]; then echo "OK      $1  $3"; else echo "ÉCHEC   $1  $3"; ECHECS=$((ECHECS + 1)); fi
}

lancer() {  # lancer <journal> <arguments godot...>
	local j="$SORTIE/$1"; shift
	timeout 1800 "$GODOT" --headless --path . "$@" > "$j" 2>&1
	if grep -qE "SCRIPT ERROR|Parse Error|Failed to load script" "$j"; then return 1; fi
	return 0
}

# Lit la dernière ligne « P3 MESURES » d'un journal et applique un critère (sondes, bloque).
mesures() { # mesures <journal> <sondes|trajet>
	python3 - "$SORTIE/$1" "$2" <<'EOF'
import json, sys
t = open(sys.argv[1], errors="replace").read().split("\n")
m = [l for l in t if l.startswith("P3 MESURES")]
if not m:
    print("pas de mesures"); sys.exit(1)
d = json.loads(m[-1][m[-1].index("{"):])
if sys.argv[2] == "sondes":
    p = d.get("probes", [])
    ok = sum(1 for x in p if x.get("ok"))
    print("%d/%d sondes" % (ok, len(p))); sys.exit(0 if p and ok == len(p) else 1)
st = d.get("stuck", [])
print("terminé=%s, étapes bloquées=%d" % (d.get("done"), len(st))); sys.exit(0 if d.get("done") and not st else 1)
EOF
}

lancer f5.log --quit-after 60; bilan "scène F5 (forêt) chargée" $? ""

lancer unitaires.log --script res://tests/run_tests.gd
r=$(grep -E "test\(s\)" "$SORTIE/unitaires.log" | tail -1); grep -q " 0 échec" <<< "$r"; bilan "tests unitaires" $? "$r"

lancer e2e_ouverture.log --script res://tests/e2e_p6_ouverture.gd -- --tuto-rapide
grep -q "RÉSULTAT : RÉUSSI" "$SORTIE/e2e_ouverture.log"; bilan "tutoriel (e2e ouverture)" $? ""
lancer e2e_saut.log --script res://tests/e2e_p6_saut_tutoriel.gd
grep -q "RÉSULTAT : RÉUSSI" "$SORTIE/e2e_saut.log"; bilan "saut du tutoriel (e2e)" $? ""

lancer p6_sondes.log --fixed-fps 60 res://scenes/p6/colisee.tscn -- --route=p6_sondes --quit --neuf --etat=tutorial_available --out="$SORTIE/p6"
d=$(mesures p6_sondes.log sondes); bilan "sondes du Colisée" $? "$d"

for cam in A B; do
	lancer ville_sondes_$cam.log --fixed-fps 60 $VILLE -- --route=p7_v07b_sondes --quit --camera_ville=$cam
	d=$(mesures ville_sondes_$cam.log sondes); bilan "ville : sondes, caméra $cam" $? "$d"
	lancer ville_trajets_$cam.log --fixed-fps 60 $VILLE -- --route=p7_v07b_trajets --quit --camera_ville=$cam
	d=$(mesures ville_trajets_$cam.log trajet); bilan "ville : trajets, caméra $cam" $? "$d"
	lancer ville_portail_$cam.log --fixed-fps 60 $VILLE -- --route=p7_v07_portail --quit --camera_ville=$cam
	d=$(mesures ville_portail_$cam.log trajet); rc=$?; n=$(grep -c "^P6 portail" "$SORTIE/ville_portail_$cam.log")
	[ $rc -eq 0 ] && [ "$n" -ge 4 ]; bilan "portail ville <-> Colisée, caméra $cam" $? "$d, $n passages"
done

for l in a b; do
	lancer stabilite_$l.log --script res://tools/p7/stabilite_interactions_p7121.gd -- --route=p7_7121_interactions --quit --lumiere=$l
	r=$(grep -oE '"ecart_max_px":[0-9.]+' "$SORTIE/stabilite_$l.log"); [ "$r" = '"ecart_max_px":0.0' ]; bilan "examens E sans saut de caméra, lumière $l" $? "$r"
	lancer lumiere_$l.log --script res://tools/p8/lumiere_ab_p80c.gd -- --lumiere=$l
	grep -q '"ok":true' "$SORTIE/lumiere_$l.log"; bilan "profils de lumière et F4 (départ $l)" $? ""
done

lancer escamotage.log --script res://tools/p7/escamotage_p7122.gd -- --route=p7_7122_aller_retour
grep -q '"aren_masque_images":0' "$SORTIE/escamotage.log" && grep -q '"clignotements_lt_1s":\[\]' "$SORTIE/escamotage.log"
bilan "escamotage (Aren jamais masqué, aucun clignotement)" $? ""

lancer cadrage.log --script res://tools/p8/cadrage_p80a.gd -- --route=p80a_cadrage
python3 - "$SORTIE/cadrage.log" <<'EOF'
import json, sys
l = [x for x in open(sys.argv[1], errors="replace") if x.startswith("CADRAGE_P80A")]
d = json.loads(l[-1][l[-1].index("{"):]) if l else {"parcours": {}}
sys.exit(0 if d["parcours"] and all(p["aren_masque_pct"] == 0 for p in d["parcours"].values()) and not d.get("bloque") else 1)
EOF
bilan "cadrage de la ville (Aren jamais masqué, aucun blocage)" $? ""

for t in v11_collisions_smoke v09_locomotion_smoke v09b5_anim_smoke v09c_ilya_smoke p52_sol_smoke p53b_pilote_smoke p5_combat_smoke; do
	lancer $t.log --fixed-fps 60 --script res://tests/$t.gd
	r=$(grep -E ": [0-9]+ échec" "$SORTIE/$t.log" | tail -1); grep -q ": 0 échec" <<< "$r"; bilan "$t" $? "$r"
done

echo "journaux : $SORTIE"
if [ $ECHECS -eq 0 ]; then echo "NON-RÉGRESSION : TOUT EST OK"; else echo "NON-RÉGRESSION : $ECHECS ÉCHEC(S)"; fi
exit $ECHECS
