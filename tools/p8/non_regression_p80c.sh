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
# P8.1-A3 (+4) : continuité de l'escamotage sur l'aller-retour forge-Colisée (Aren jamais masqué, aucun clignotement,
# aucune disparition entière, au plus 36 bascules, part de hauteur retirée moyenne <= 0,55) et sur les trajets de la
# porte sud (Aren jamais masqué, aucun clignotement) ; bannières (aucune devant une baie) ; cohérence des façades (0).
# P8.1-A4 (+3) : porte du Colisée (halle stable), enceinte sud (bascules perceptibles), retour Colisée -> ville (ville gardée).
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

# P8.1-A3 : continuité visuelle mesurable (tools/p8/escamotage_p81a3.gd)
continuite() { # continuite <journal> <bascules max> <disparitions max> <part max>
	python3 - "$SORTIE/$1" "$2" "$3" "$4" <<'EOF'
import json, sys
l = [x for x in open(sys.argv[1], errors="replace") if x.startswith("ESCAMOTAGE_A3")]
if not l:
    print("pas de mesure"); sys.exit(1)
d = json.loads(l[-1][l[-1].index("{"):])
print("bascules=%d, disparitions_entieres=%d, part_retiree=%.2f, aren_masque=%d" % (d["bascules_total"], d["disparitions_entieres"],
    d["part_hauteur_retiree_moy"], d["aren_masque_images"]))
ok = d["aren_masque_images"] == 0 and not d["clignotements_lt_1s"] and not d["bloque"] and d["bascules_total"] <= int(sys.argv[2]) \
    and d["disparitions_entieres"] <= int(sys.argv[3]) and d["part_hauteur_retiree_moy"] <= float(sys.argv[4])
sys.exit(0 if ok else 1)
EOF
}
lancer continuite_forge.log --fixed-fps 60 --script res://tools/p8/escamotage_p81a3.gd -- --route=p81a3_aller_retour
r=$(continuite continuite_forge.log 36 0 0.55); bilan "continuité forge-Colisée (aller-retour, A3)" $? "$r"
lancer continuite_porte.log --fixed-fps 60 --script res://tools/p8/escamotage_p81a3.gd -- --route=p7_v07b_trajets
r=$(continuite continuite_porte.log 999 999 1.0); bilan "continuité porte sud (trajets, A3)" $? "$r"
# P8.1-A4 : porte du Colisée (halle du quai : structure jamais escamotée, au plus 6 bascules perceptibles), enceinte sud
# (au plus 12 bascules perceptibles), retours Colisée -> ville (ville gardée : moins de 400 ms sans rendu, arrivée et
# déclencheurs conformes ; journaux du test portail ci-dessus)
lancer continuite_porte_colisee.log --fixed-fps 60 --script res://tools/p8/escamotage_p81a3.gd -- --route=p81a4_porte_colisee
r=$(python3 - "$SORTIE/continuite_porte_colisee.log" <<'EOF'
import json, sys
l = [x for x in open(sys.argv[1], errors="replace") if x.startswith("ESCAMOTAGE_A3")]
d = json.loads(l[-1][l[-1].index("{"):]) if l else {}
v = [x for x in open(sys.argv[1], errors="replace") if x.startswith("VOLUME bat_echoppe_no_o")]
print("perceptibles=%s, aren_masque=%s, volume de la halle : %s" % (d.get("bascules_perceptibles"), d.get("aren_masque_images"), "aucune bascule" if not v else v[0].strip()))
sys.exit(0 if d and d["aren_masque_images"] == 0 and not d["clignotements_lt_1s"] and d["bascules_perceptibles"] <= 6 and not v else 1)
EOF
); bilan "porte du Colisée : halle stable (A4)" $? "$r"
lancer continuite_enceinte.log --fixed-fps 60 --script res://tools/p8/escamotage_p81a3.gd -- --route=p81a4_enceinte
r=$(python3 - "$SORTIE/continuite_enceinte.log" <<'EOF'
import json, sys
l = [x for x in open(sys.argv[1], errors="replace") if x.startswith("ESCAMOTAGE_A3")]
d = json.loads(l[-1][l[-1].index("{"):]) if l else {}
print("perceptibles=%s, bascules=%s, aren_masque=%s" % (d.get("bascules_perceptibles"), d.get("bascules_total"), d.get("aren_masque_images")))
sys.exit(0 if d and d["aren_masque_images"] == 0 and not d["clignotements_lt_1s"] and d["bascules_perceptibles"] <= 12 else 1)
EOF
); bilan "enceinte sud : continuité (A4)" $? "$r"
r=$(python3 - "$SORTIE/ville_portail_A.log" <<'EOF'
import json, sys
t = open(sys.argv[1], errors="replace").read().split("\n")
ch = [json.loads(x[x.index("{"):]) for x in t if x.startswith("P8A4 CHARGEMENT")]
ar = [json.loads(x[x.index("{"):]) for x in t if x.startswith("P6 arrivee_portail")]
retours = [c["noir_ms"] for c in ch if c["vers"].startswith("ville")]
ok = len(ch) >= 4 and len(retours) >= 2 and all(x < 400 for x in retours) and len(ar) >= 4 \
    and all(a["zone"] == "ville" and abs(a["x"] - 30.45) < 0.05 and a["declencheurs_armes"].get("portail_colisee_public") for a in ar if a["zone"] == "ville")
print("retours en ville (ms, sans rendu) : %s" % retours)
sys.exit(0 if ok else 1)
EOF
); bilan "retour Colisée -> ville : ville gardée (A4)" $? "$r"
lancer bannieres.log --script res://tools/p8/bannieres_p81a3.gd
r=$(grep -o '"devant_une_baie":[0-9]*' "$SORTIE/bannieres.log"); grep -q '"devant_une_baie":0' "$SORTIE/bannieres.log"; bilan "bannières (aucune devant une baie)" $? "$r"
lancer coherence.log --script res://tools/p8/coherence_facades_p81a2.gd
grep -q '"conflits":0' "$SORTIE/coherence.log" && grep -q '"portes_hors_sol":0' "$SORTIE/coherence.log" && grep -q '"soubassements_traversants":0' "$SORTIE/coherence.log" && grep -q '"obstacles_devant":0' "$SORTIE/coherence.log"
bilan "cohérence des façades (0 superposition, 0 porte hors sol)" $? ""

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
