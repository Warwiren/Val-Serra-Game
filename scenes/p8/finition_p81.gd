extends RefCounted
## P8.1-A — FINITION DU QUARTIER (avant les PNJ) : remplacement des restes de blockout VISIBLES depuis les parcours, par
## lots (docs/P8_1A_FINITION.md). Affichage seulement : chaque collision est créée par les MÊMES appels que le blockout
## (mêmes boîtes, mêmes couches), seules les matières et le décor changent. Rien n'est ajouté au plan.
## Lots : « sols » (L1 : sols, terrasses, masses de terrain, garde-corps). Options : --finition=0 (tous les lots
## coupés : état P8.0-C), --f_<lot>=0 (un lot coupé).
## Matières : celles des références validées (dallage de la grande place P7.8, soutènement sali et taille du quartier
## civique P7.12), par la bibliothèque archi_p77 (cache commun).

const Archi := preload("res://scenes/p7/archi_p77.gd")
const TEINTE_DALLAGE := Color(1.12, 1.09, 1.04)          # = place_p78.TEINTE_DALLAGE (grande place)

var b                 # constructeur de la ville (scenes/p7/ville_v07b.gd)
var sc                # scène (colisee.gd)
var a                 # composants (Archi) : ceux de la tranche, maillages sous sc.root
var _m := {}


func _init(builder) -> void:
	b = builder
	sc = builder.sc
	a = builder._tr().a


## Le lot est-il actif ? (--finition=0 coupe tout ; --f_<lot>=0 coupe un lot)
func actif(lot: String) -> bool:
	return str(sc._cli.get("finition", "1")) != "0" and str(sc._cli.get("f_" + lot, "1")) != "0"


# ------------------------------------------------------------------------------------------------ matières
func _pierre(nom: String, base: String, teinte: Color, regl: Dictionary, base_y := 0.0, hole := true) -> ShaderMaterial:
	var cle := "p81|%s|%s" % [nom, base_y]
	if a._mats.has(cle):
		return a._mats[cle]
	var mt := (a.macon(base, teinte, base_y, "monde", hole) as ShaderMaterial).duplicate() as ShaderMaterial
	for k in regl:
		mt.set_shader_parameter(k, regl[k])
	a._mats[cle] = mt
	return mt


## Dallage des rues et des parvis : celui de la grande place, un peu plus sali et plus sombre au niveau bas (rues),
## plus clair sur les terrasses hautes (comme le dallage civique).
func dallage(h: float) -> ShaderMaterial:
	var t := TEINTE_DALLAGE * (0.96 if h < 1.0 else (1.0 if h < 6.0 else 1.06))
	t.a = 1.0
	return _pierre("dallage_%d" % int(round(h * 4.0)), "dallage2", t, {"salissure": 0.35 if h < 1.0 else 0.25}, h, false)


## Sol hors les murs (sol de décor sous toute la carte) : même dallage, sombre et sali (lecture d'un sol lointain).
func sol_loin(h: float) -> ShaderMaterial:
	return _pierre("sol_loin", "dallage2", Color(0.86, 0.82, 0.76), {"salissure": 0.6}, h, false)


## Soutènement : contrefort sali du quartier civique (P7.12), base au pied du mur.
func soutenement(base_y: float) -> ShaderMaterial:
	return _pierre("soutenement_%d" % int(round(base_y * 4.0)), "contrefort", Color(1.16, 1.12, 1.06), {"salissure": 0.5, "coulures": 0.45}, base_y)


## Pierre de taille des couronnements et chaperons (taille_b du quartier civique).
func taille() -> ShaderMaterial:
	return _pierre("taille", "mur2", Color(1.38, 1.31, 1.20), {"assises": Vector3(3.0, 3.0, 3.0), "long_bloc": 4.0, "var_long": 0.0,
		"joint": 0.0, "salissure": 0.2, "coulures": 0.15, "mousse": 0.0, "fissures": 0.0, "rapieces": 0.0, "irregulier": 0.0, "usure": 0.35,
		"k_mousse": 0.0})


# ------------------------------------------------------------------------------------------------ L1 : sols et soutènements
## Entité « floor » des données (hors tranche) : même collision que le blockout (dalle de 0,3 m), dessus en dallage.
## Sol de décor (role « decor ») : même collision (couche NOWALK, débord de 80 m), sol lointain.
func sol(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var h: float = e["h"]
	if e.get("role", "") == "decor":
		var c := Vector3(r.get_center().x, h - 0.17, r.get_center().y)
		var size := Vector3(r.size.x + 80.0, 0.3, r.size.y + 80.0)
		sc._static_box(c, size, sc.L_NOWALK)
		var md: MeshInstance3D = a.box(c - Vector3(0, 0.02, 0), size, sol_loin(h))
		md.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		return
	var th := 0.3
	sc._static_box(sc._rect_center(r, h - th, h), Vector3(r.size.x, th, r.size.y), sc.L_FLOOR)
	var mi: MeshInstance3D = a.box(sc._rect_center(r, h - th, h), Vector3(r.size.x, th, r.size.y), dallage(h))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Bloc « terrasse » des données (hors tranche, place et civique) : même collision, corps en soutènement, dessus dallé,
## couronnement de pierre de taille sur la face sud (face caméra).
func terrasse(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var h0: float = e["h0"]
	var h1: float = e["h1"]
	sc._static_box(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), sc.L_FLOOR)
	corps_terrasse(r, h0, h1 - 0.02)
	a.box(sc._rect_center(r, h1 - 0.02, h1), Vector3(r.size.x, 0.02, r.size.y), dallage(h1))


## Corps d'une terrasse (murs de soutènement) de h0 à h, couronnement au sommet de la face sud.
func corps_terrasse(r: Rect2, h0: float, h: float) -> void:
	a.box(sc._rect_center(r, h0, h), Vector3(r.size.x, h - h0, r.size.y), soutenement(h0))
	if h - h0 > 0.6:
		var cb: MeshInstance3D = a.box(Vector3(r.get_center().x, h - 0.11, r.end.y + 0.06), Vector3(r.size.x + 0.04, 0.22, 0.14), taille())
		cb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Masses de terrain (V0.7-A) : flancs en soutènement, dessus dallé, cordon de pierre de taille au sommet de la face sud.
## Mêmes boîtes que ville_v07a._masses (aucune collision : le relief praticable vient des sols et terrasses des données).
func masses(liste: Array) -> void:
	for m in liste:
		var q: Array = m[0]
		var h: float = float(m[1]) - 0.006
		var r := Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1])
		a.box(sc._rect_center(r, -1.0, h), Vector3(r.size.x, h + 1.0, r.size.y), soutenement(0.0))
		a.box(Vector3(r.get_center().x, h - 0.005, r.get_center().y), Vector3(r.size.x, 0.01, r.size.y), dallage(h + 0.01))
		if r.size.x < 200.0:
			a.box(Vector3(r.get_center().x, h - 0.12, r.end.y + 0.12), Vector3(r.size.x, 0.24, 0.24), taille())


## Garde-corps « gc_ » des données non traités par le quartier civique : même collision ; parapet de soutènement plein et
## chaperon de pierre de taille (au lieu du muret gris et de la main courante claire du blockout).
func garde_corps(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var h0: float = e["h0"]
	var h1: float = e["h1"]
	sc._static_box(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), sc.L_OBST)
	a.box(sc._rect_center(r, h0, h0 + 0.85), Vector3(r.size.x, 0.85, r.size.y), soutenement(h0))
	a.box(sc._rect_center(r.grow(0.06), h0 + 0.85, h0 + 1.0), Vector3(r.size.x + 0.12, 0.15, r.size.y + 0.12), taille())
