extends RefCounted
## P7.10 — BOUTIQUE DE FOURNITURES (lot suivant la forge, langage hybride C retenu). Même ville que la forge, autre
## silhouette : maison de marchand HAUTE et ÉTROITE, pignon face à la place (la forge est basse, longue, faîtage parallèle
## à la façade), rez-de-chaussée de pierre appareillée (la forge : bossage et pierre jusqu'au toit), étages enduits miel,
## volets verts, toit de tuiles Quaternius en terre cuite C+ (même matière que la forge), potence de grenier avec palan et
## caisse suspendue (signe des fournitures), auvent vert sur l'entrée, étal adossé au commerce voisin.
## Emprise, collision (bloc des données x 76 -> 88, y 76 -> 88) et entrée fonctionnelle (x 78, façade sud) INCHANGÉES ; les
## étages et le toit sont de l'affichage seul. Seule collision ajoutée : l'étal (boîte basse contre le mur ouest de
## bat_commerce_e2, hors du passage de la porte). --boutique=0 : blockout.

const Archi := preload("res://scenes/p7/archi_p77.gd")
const R := Rect2(76.0, 76.0, 12.0, 12.0)
const H0 := 3.5
const NIVEAUX := [3.5, 7.0, 9.9, 12.4]
const TOIT_KY := 0.7                    # pente plus raide que la forge (0,55) : pignon élancé
const ETAL := Rect2(79.15, 89.7, 0.85, 2.95)

var sc
var a
var fo                                  # forge (helpers Quaternius : _modele, _fusion_gltf, _terre_cuite)
var actif := true


func _init(scene, archi, forge) -> void:
	sc = scene
	a = archi
	fo = forge
	actif = str(scene._cli.get("boutique", "1")) != "0"


func batiment() -> void:
	var top: float = NIVEAUX[NIVEAUX.size() - 1]
	var pal: Array = Archi.PALETTES["miel"]
	var d := {"id": "bat_boutique_fournitures", "niveaux": NIVEAUX, "enduit": pal[0], "volets": pal[1],
		"rdc": "pierre", "etages": "enduit", "corniche": "simple", "toit_h": 3.0, "volets_style": "pleins", "toit": "aucun",
		"faces": {
			# sud : seule la travée ouest (x 76 -> 80) est dégagée sous 9,5 m (bat_commerce_e2 devant) ; dernier étage entier,
			# porte de grenier au centre sous la potence
			"s": [[], [[2.0, 1.1, 1.6, 0.8, "fenetre"]], [[2.2, 1.0, 1.5, 0.6, "fenetre"], [6.0, 1.2, 2.1, 0.05, "porte_deco"], [9.8, 1.0, 1.5, 0.6, "fenetre"]]],
			"o": [[], [[3.0, 1.0, 1.6, 0.8, "fenetre"], [9.0, 1.0, 1.6, 0.8, "fenetre"]], [[3.0, 1.0, 1.5, 0.6, "fenetre"], [9.0, 1.0, 1.5, 0.6, "fenetre"]]],
		},
		"balcons": [["s", 1.2, 2.8, 1, 0.3, "balconnet"]]}
	a.batiment(R, H0, d)
	_toit(top)
	_potence(top)
	_auvent()
	_etal()


## Toit à deux versants, faîtage nord-sud (pignon au sud), terre cuite C+ ; pignons de brique Quaternius.
func _toit(top: float) -> void:
	var c := R.get_center()
	var toit: Node3D = fo._modele("mv/Roof_RoundTiles_8x12", Vector3(c.x, top, c.y), 0.0, Vector3((R.size.x + 0.6) / 9.95, TOIT_KY, (R.size.y + 0.9) / 14.13))
	fo._terre_cuite(toit)
	var depuis: int = a.racine.get_child_count()
	for s in [-1.0, 1.0]:
		var y := R.position.y if s < 0.0 else R.end.y
		fo._modele("mv/Roof_Front_Brick8", Vector3(c.x, top, y), 0.0 if s < 0.0 else PI, Vector3(R.size.x / 8.5, TOIT_KY * 6.0 / 5.31, 1.0))
	fo._fusion_gltf(depuis, "boutique_pignons")
	# souche de cheminée sur le versant ouest (silhouette)
	var d2: int = a.racine.get_child_count()
	a.cheminee([78.6, 79.0], top + 0.6, top + 3.6)
	a.fusionner(d2, "boutique_cheminee")


## Potence de grenier au sommet du pignon : poutre en saillie, jambe de force, poulie, corde, caisse suspendue.
func _potence(top: float) -> void:
	var depuis: int = a.racine.get_child_count()
	var x := 82.0
	var y := R.end.y
	var bois: Material = a.plein(Color(0.36, 0.25, 0.16))
	var v := top + 2.55
	a.box(Vector3(x, v, y + 0.7), Vector3(0.22, 0.24, 1.6), bois)                        # poutre
	var j: MeshInstance3D = a.box(Vector3(x, v - 0.5, y + 0.38), Vector3(0.14, 1.0, 0.14), bois)
	j.basis = Basis(Vector3(1, 0, 0), -0.6)                                                 # jambe de force
	a.box(Vector3(x, v - 0.2, y + 1.35), Vector3(0.1, 0.26, 0.26), a.fer())               # poulie
	a.box(Vector3(x, v - 1.25, y + 1.35), Vector3(0.03, 1.9, 0.03), a.plein(Color(0.62, 0.55, 0.42)))   # corde
	a.box(Vector3(x, v - 2.4, y + 1.35), Vector3(0.62, 0.5, 0.62), a.plein(Color(0.52, 0.38, 0.24)))  # caisse
	for dy in [-0.16, 0.16]:
		a.box(Vector3(x, v - 2.4 + dy, y + 1.35), Vector3(0.66, 0.05, 0.66), a.plein(Color(0.30, 0.21, 0.13)))
	a.fusionner(depuis, "boutique_potence")


## Auvent de toile verte rayée sur l'entrée et la vitrine de la travée ouest (x 76,2 -> 79,9), à 6 m : ne masque ni la
## porte ni Aren ; lambrequin festonné.
func _auvent() -> void:
	var depuis: int = a.racine.get_child_count()
	var y := R.end.y
	var v := 6.15
	var vert: Material = a.plein(Color(0.25, 0.44, 0.30))
	var creme: Material = a.plein(Color(0.86, 0.82, 0.70))
	var n := 7
	var w := 3.7 / n
	for i in n:
		var b: MeshInstance3D = a.box(Vector3(76.2 + w * (i + 0.5), v - 0.3, y + 0.62), Vector3(w + 0.002, 0.04, 1.3), vert if i % 2 == 0 else creme)
		b.basis = Basis(Vector3(1, 0, 0), 0.45)
		a.box(Vector3(76.2 + w * (i + 0.5), v - 0.72, y + 1.2), Vector3(w * 0.9, 0.22, 0.03), creme if i % 2 == 0 else vert)
	for xb in [76.25, 79.85]:
		a.box(Vector3(xb, v - 0.3, y + 0.62), Vector3(0.04, 0.04, 1.3), a.fer())
	a.fusionner(depuis, "boutique_auvent")


## Étal de fournitures adossé au mur ouest de bat_commerce_e2 (collision basse ajoutée, hors du passage de la porte :
## x 79,15 -> 80, la porte s'arrête à 78,9) : table, caisses, sacs, tonneau ; lanterne murale.
func _etal() -> void:
	var r := ETAL
	sc._static_box(sc._rect_center(r, H0, H0 + 0.9), Vector3(r.size.x, 0.9, r.size.y), sc.L_OBST)
	var d0: int = a.racine.get_child_count()
	var cx := r.get_center().x
	fo._modele("fp/Table_Large", Vector3(cx, H0, 90.88), PI * 0.5, Vector3(0.75, 1.0, 0.75))
	fo._modele("fp/Crate_Wooden", Vector3(cx, H0 + 0.81, 90.2), 0.15, Vector3.ONE * 0.5)
	fo._modele("fp/Crate_Wooden", Vector3(cx, H0 + 0.81, 90.85), -0.1, Vector3.ONE * 0.42)
	fo._modele("fp/Barrel", Vector3(cx + 0.05, H0, 92.3), 0.0, Vector3.ONE * 0.8)
	fo._modele("fp/Lantern_Wall", Vector3(80.0, H0 + 1.75, 91.0), -PI * 0.5, Vector3.ONE * 0.8)
	fo._fusion_gltf(d0, "boutique_etal_modeles")
	# sacs (grain, toile) sur la table
	var d1: int = a.racine.get_child_count()
	var toile: Material = a.plein(Color(0.72, 0.64, 0.48))
	for p in [[91.4, 0.36], [91.78, 0.3]]:
		a.box(Vector3(cx - 0.05, H0 + 0.81 + float(p[1]) * 0.5, float(p[0])), Vector3(0.42, float(p[1]), 0.34), toile)
	a.fusionner(d1, "boutique_etal_sacs")
