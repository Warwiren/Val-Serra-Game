extends RefCounted
## P3-07 — Trois variantes de caméra CONTRÔLÉES (doc 07 §03) : un seul levier par variante, tout le reste identique
## (azimut 20°, zooms ×2 / ×2,5 / ×3, suivi P3, collisions, hauteurs, personnages, compagnon, instances).
##   A — référence : plongée 35°, héros centré (visée P3 : 8 px au-dessus des pieds).
##   B — plongée réduite à 28° (VALEUR DE TEST) : la caméra 3D est réellement réorientée ; les sprites gardent leur
##       taille à l'écran (carte verticale mise à l'échelle 1/cos(plongée), correction explicite, voir rapport).
##   C — plongée 35°, héros vers 63 % de la hauteur de l'écran (décentrage de 10 % + visée P3 de 8 px), ramené au centre pendant un
##       dialogue ; les limites de caméra restent appliquées (près des bords, le décentrage cède).
## Ce sont des HYPOTHÈSES de test, pas des choix validés.

const ORDER := ["A", "B", "C"]
const V := {
	"A": {"label": "A — référence (plongée 35°, héros centré)", "pitch_deg": 35.0, "aim_frac": 0.0},
	"B": {"label": "B — plongée réduite (28°, héros centré)", "pitch_deg": 28.0, "aim_frac": 0.0},
	"C": {"label": "C — 35°, héros vers 63 % de la hauteur", "pitch_deg": 35.0, "aim_frac": 0.1},
}


static func get_v(k: String) -> Dictionary:
	return V.get(k, V["A"])


static func next_of(k: String) -> String:
	return ORDER[(ORDER.find(k) + 1) % ORDER.size()]
