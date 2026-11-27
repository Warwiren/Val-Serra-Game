extends RefCounted
## FORGE-ARMURERIE de la ville V0.7-B et UTILITAIRES DE MODÈLES Quaternius partagés (_modele, _fusion_gltf, _terre_cuite :
## forge D, boutique P7.11, bordures P7.13, quartier civique P7.12).
## Variantes : D = refonte P7.10.1 APPROUVÉE (scenes/p7/forge_p7101.gd, défaut) ; C = C+ de P7.10 (hybride : murs de la
## bibliothèque archi_p77 + toit, pignons, vantaux et accessoires Quaternius), conservée pour la comparaison avant / après ;
## --forge=0 : blockout. Même emprise (x 44 -> 58, y 76 -> 88), même entrée (x 51), collision = celle des données.
## P8.0-C : variantes A (bibliothèque seule) et B (Quaternius seul) du comparatif P7.9 retirées (clos depuis P7.10 ;
## code dans l'historique Git, commit 588e90c).

const Archi := preload("res://scenes/p7/archi_p77.gd")
const Refonte := preload("res://scenes/p7/forge_p7101.gd")
const QUAT := "res://art/p63/quaternius/"
const R := Rect2(44.0, 76.0, 14.0, 12.0)
const H0 := 3.5
const H1 := 7.5
const COUR_H := 3.95                 # dessus de la plate-forme des étals (3,5 + 0,45)
const PORTE_X := 51.0

var sc
var a
var variante := ""
var _cache := {}


func _init(scene, archi, v: String) -> void:
	sc = scene
	a = archi
	variante = v


## P7.10.1 : D (refonte artistique de C+, scenes/p7/forge_p7101.gd) est la forge par défaut de la V0.7-B ; C = C+ de P7.10
## (comparaison avant / après) ; --forge=0 : blockout.
static func lire_variante(scene) -> String:
	var defaut := "D"
	if scene.get("forge_variante") != null and str(scene.get("forge_variante")) != "":
		defaut = str(scene.get("forge_variante"))
	var v := str(scene._cli.get("forge", defaut)).to_upper()
	return v if v in ["C", "D"] else ""


# ------------------------------------------------------------------------------------------------ construction
func batiment() -> void:
	match variante:
		"C":
			_archi()
			_atelier_c()
		"D":
			Refonte.new(self).construire()


## Entrée fonctionnelle de la forge (données ENTREES) : true si la variante la dessine elle-même.
func entree() -> bool:
	if variante == "D":
		return true                                       # P7.10.1 : entrée dessinée par la refonte (forge_p7101.gd)
	return false


## Après l'entrée en pierre (C) : en C, vantaux Quaternius dans l'avant-corps.
func apres_entree(e: Dictionary) -> void:
	if variante != "C":
		return
	var L: float = e["largeur"]
	var depuis: int = a.racine.get_child_count()
	for s in [-1.0, 1.0]:
		var x := PORTE_X - L * 0.5 + 0.04 if s < 0.0 else PORTE_X + L * 0.5 - 0.04
		var n := _modele("mv/Door_8_Round", Vector3(x, H0, R.end.y + 0.1), 0.0 if s < 0.0 else PI, Vector3(L * 0.5 / 1.09, 2.5 / 2.36, 1.0))
		if s > 0.0:
			n.scale.z = -1.0
	_fusion_gltf(depuis, "forge_vantaux")


# ------------------------------------------------------------------------------------------------ C : bibliothèque + Quaternius
func _archi() -> void:
	var pal: Array = Archi.PALETTES["gris_chaud"]
	var d := {"id": "bat_forge_armurerie", "niveaux": [H0, 6.9, H1], "enduit": pal[0], "volets": Color(0.24, 0.22, 0.20),
		"rdc": "bossage", "etages": "pierre", "corniche": "consoles", "toit_h": 3.0, "volets_style": "aucun",
		"toit": "aucun",
		"faces": {
			# C+ : grande baie CINTRÉE éclairée (vitrine de l'armurerie : arc de claveaux, petits bois, lueur de la forge)
			"s": [[[3.0, 2.0, 1.8, 0.4, "baie_cintree"], [11.2, 1.0, 1.6, 0.7, "fenetre_cintree"]], []],
			"e": [[[3.0, 0.9, 1.1, 1.0, "barreaux"], [7.5, 0.9, 1.1, 1.0, "barreaux"]], []],
			"o": [[[6.0, 2.4, 2.6, 0.0, "porte_cochere"]], []],
		}}
	a.batiment(R, H0, d)
	_toit_quaternius()
	_cheminee_forge()
	_enseigne_armurerie()


# ------------------------------------------------------------------------------------------------ utilitaires Quaternius (partagés)
func _modele(chemin: String, pos: Vector3, rot_y := 0.0, k := Vector3.ONE) -> Node3D:
	if not _cache.has(chemin):
		_cache[chemin] = load(QUAT + chemin + ".gltf")
	var ps: PackedScene = _cache[chemin]
	if ps == null:
		push_warning("P7.9 : modèle introuvable " + chemin)
		return Node3D.new()
	var n: Node3D = ps.instantiate()
	n.position = pos
	n.rotation.y = rot_y
	n.scale = k
	a.racine.add_child(n)
	return n


## Fusion par matière des maillages des modèles ajoutés depuis `depuis` (transforms appliqués) : un maillage par
## matière, au lieu d'un par pièce de module (même principe que Archi.fusionner).
func _fusion_gltf(depuis: int, nom: String) -> void:
	var noeuds := []
	for i in range(depuis, a.racine.get_child_count()):
		noeuds.append(a.racine.get_child(i))
	var groupes := {}
	var inv := (a.racine as Node3D).global_transform.affine_inverse()
	for n in noeuds:
		for mi in (n as Node).find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.mesh == null:
				continue
			var tr: Transform3D = inv * m.global_transform
			for s in m.mesh.get_surface_count():
				var mat: Material = m.get_active_material(s)
				var k := mat.get_instance_id() if mat != null else 0
				if not groupes.has(k):
					var st := SurfaceTool.new()
					st.begin(Mesh.PRIMITIVE_TRIANGLES)
					groupes[k] = {"st": st, "mat": mat}
				(groupes[k]["st"] as SurfaceTool).append_from(m.mesh, s, tr)
	for n in noeuds:
		a.racine.remove_child(n)
		(n as Node).queue_free()
	var mesh := ArrayMesh.new()
	for k in groupes:
		var g: Dictionary = groupes[k]
		(g["st"] as SurfaceTool).commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, g["mat"])
	var out := MeshInstance3D.new()
	out.name = nom
	out.mesh = mesh
	a.racine.add_child(out)


## Toit de tuiles Quaternius (faîtage est-ouest : versant face caméra), pignons enduits (C).
func _toit_quaternius() -> void:
	var kz := (R.size.y + 0.9) / 9.96
	var toit := _modele("mv/Roof_RoundTiles_8x12", Vector3(R.get_center().x, H1, R.get_center().y), PI * 0.5, Vector3(kz, 0.55, (R.size.x + 0.6) / 14.14))
	# C+ : le toit n'est PAS fusionné (mise à l'échelle non uniforme : les normales restent calculées par le moteur) et
	# reçoit une terre cuite plus chaude et moins saturée que la tuile d'origine
	_terre_cuite(toit)
	for s in [-1.0, 1.0]:
		var x := R.position.x if s < 0.0 else R.end.x
		_modele("mv/Roof_Front_Brick8", Vector3(x, H1, R.get_center().y), -PI * 0.5 * s, Vector3(R.size.y / 8.5, 0.55 * 6.0 / 5.31, 1.0))


# ------------------------------------------------------------------------------------------------ C+ (P7.10)
## Terre cuite C+ : copie des matières de tuiles du modèle, albédo plus chaud et désaturé (rouge baissé, vert et bleu
## relevés), rugosité forte, relief normal adouci (les tuiles restent lisibles à 22 m sans paraître noires).
var _tc := {}
func _terre_cuite(n: Node) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for s in m.mesh.get_surface_count():
			var m0: Material = m.get_active_material(s)
			if not (m0 is StandardMaterial3D):
				continue
			var sm := m0 as StandardMaterial3D
			if not str(sm.albedo_texture.resource_path if sm.albedo_texture else "").contains("RoundTiles"):
				continue
			if not _tc.has(m0.get_instance_id()):
				var m1 := sm.duplicate() as StandardMaterial3D
				m1.albedo_color = Color(0.84, 1.0, 1.06)
				m1.roughness = 0.9
				if m1.normal_enabled:
					m1.normal_scale = 0.6
				_tc[m0.get_instance_id()] = m1
			m.set_surface_override_material(s, _tc[m0.get_instance_id()])


## Cheminée de forge : souche de pierre sur le versant sud, au-dessus du faîtage (silhouette lisible depuis la place),
## chaperon, gueule sombre et lueur discrète.
func _cheminee_forge() -> void:
	var depuis: int = a.racine.get_child_count()
	var x := 55.6
	var z := 84.2
	var pierre: Material = a.macon("mur2", Archi.PIERRE_VILLE * 0.92, H1)
	a.box(Vector3(x, H1 + 2.7, z), Vector3(1.25, 5.4, 1.1), pierre)
	a.box(Vector3(x, H1 + 5.45, z), Vector3(1.5, 0.18, 1.35), a.moulure())
	a.box(Vector3(x, H1 + 5.62, z), Vector3(0.9, 0.16, 0.75), a.plein(Color(0.08, 0.07, 0.07)))
	for dx in [-0.42, 0.42]:
		a.box(Vector3(x + dx, H1 + 5.75, z), Vector3(0.16, 0.26, 0.9), a.moulure())
	a.fusionner(depuis, "forge_cheminee")


## Enseigne de l'armurerie, face à la caméra : potence de fer, panneau de bois, bouclier et deux épées croisées
## (modèles Quaternius déjà importés). Remplace l'enseigne générique de l'entrée.
func _enseigne_armurerie() -> void:
	var depuis: int = a.racine.get_child_count()
	var x := 54.5
	var y := R.end.y
	var fer: Material = a.fer()
	a.box(Vector3(x, H0 + 3.15, y + 0.6), Vector3(0.07, 0.07, 1.2), fer)                      # bras de la potence
	a.box(Vector3(x, H0 + 2.95, y + 0.05), Vector3(0.1, 0.5, 0.1), fer)                       # scellement
	for dx in [-0.42, 0.42]:
		a.box(Vector3(x + dx * 0.9, H0 + 3.0, y + 1.0), Vector3(0.025, 0.3, 0.025), fer)        # chaînettes
	a.box(Vector3(x, H0 + 2.42, y + 1.0), Vector3(1.05, 0.82, 0.07), a.plein(Color(0.36, 0.24, 0.15)))
	a.box(Vector3(x, H0 + 2.42, y + 0.97), Vector3(1.15, 0.92, 0.04), fer)                    # cadre
	a.fusionner(depuis, "forge_enseigne")
	var d2: int = a.racine.get_child_count()
	for s in [-1.0, 1.0]:
		var ep := _modele("fp/Sword_Bronze", Vector3(x + s * 0.05, H0 + 2.25, y + 1.06), 0.0, Vector3.ONE * 0.85)
		ep.rotation = Vector3(0, 0, s * 0.62)
	_modele("fp/Shield_Wooden", Vector3(x, H0 + 2.42, y + 1.05), 0.0, Vector3.ONE * 0.95)
	_fusion_gltf(d2, "forge_enseigne_armes")


## Atelier extérieur (cour, sur la plate-forme existante : aucune collision ajoutée) : appentis de planches sur poteaux
## contre le mur ouest, foyer de forge ouvert à braises, enclume, bac de trempe, établi, meule, râtelier d'armes,
## réserve de tonneaux et de caisses ; bouclier et épée au mur.
func _atelier_c() -> void:
	var depuis: int = a.racine.get_child_count()
	var bois: Material = a.plein(Color(0.40, 0.28, 0.18))
	var planches: Material = a.plein(Color(0.46, 0.34, 0.24))
	var pierre: Material = a.macon("socle2", Archi.PIERRE_VILLE, COUR_H)
	# plate-forme de la cour (bloc des données bat_echoppe_no, inchangé) : parement de pierre et dallage par-dessus le blockout
	a.box(Vector3(40.0, (3.5 + COUR_H) * 0.5, 82.0), Vector3(8.04, COUR_H - 3.5 + 0.02, 12.04), a.macon("socle2", Archi.PIERRE_VILLE, 3.5))
	a.box(Vector3(40.0, COUR_H + 0.015, 82.0), Vector3(8.0, 0.03, 12.0), a.macon("dallage2", Archi.PIERRE_VILLE * 0.95, COUR_H))
	a.box(Vector3(40.0, COUR_H + 0.05, 88.0), Vector3(8.1, 0.1, 0.3), a.moulure())              # bordure sur la place
	# appentis : 2 poteaux, sablière, toit de planches en pente vers l'ouest (x 39,4 -> 44 ; y 77 -> 83,4)
	for zp in [77.3, 83.1]:
		a.box(Vector3(39.6, COUR_H + 1.25, zp), Vector3(0.2, 2.5, 0.2), bois)
	a.box(Vector3(39.6, COUR_H + 2.52, 80.2), Vector3(0.22, 0.18, 6.2), bois)
	var toit: MeshInstance3D = a.box(Vector3(41.75, COUR_H + 2.92, 80.2), Vector3(5.2, 0.1, 6.6), planches)
	toit.basis = Basis(Vector3(0, 0, 1), 0.17)
	var x := 39.4
	while x < 44.0:
		var c: MeshInstance3D = a.box(Vector3(x + 0.27, COUR_H + 2.55 + (x - 39.2) * 0.172, 80.2), Vector3(0.06, 0.06, 6.62), a.plein(Color(0.30, 0.21, 0.14)))
		c.basis = Basis(Vector3(0, 0, 1), 0.17)
		x += 0.55
	# foyer ouvert : socle de pierre, braises, hotte de pierre contre le mur
	a.box(Vector3(42.9, COUR_H + 0.45, 79.0), Vector3(1.6, 0.9, 1.4), pierre)
	a.box(Vector3(42.9, COUR_H + 0.92, 79.0), Vector3(1.2, 0.06, 1.0), a.plein(Color(1.0, 0.42, 0.12), 0.6, 2.6))
	a.box(Vector3(43.6, COUR_H + 1.9, 79.0), Vector3(0.6, 1.9, 1.5), pierre)
	a.fusionner(depuis, "forge_atelier")
	var d2: int = a.racine.get_child_count()
	_modele("fp/Anvil", Vector3(41.4, COUR_H, 81.0), 0.2, Vector3.ONE * 1.25)
	_modele("fp/Barrel", Vector3(42.9, COUR_H, 82.6), 0.0)                                    # bac de trempe
	_modele("fp/Workbench", Vector3(40.6, COUR_H, 77.7), 0.0)
	_modele("fp/Whetstone", Vector3(38.3, COUR_H, 79.4), 0.6)
	_modele("fp/WeaponStand", Vector3(37.3, COUR_H, 82.6), PI * 0.5)
	_modele("fp/Bucket_Metal", Vector3(40.4, COUR_H, 83.0), 0.0)
	_modele("fp/Barrel", Vector3(37.3, COUR_H, 86.6), 0.0)
	_modele("fp/Barrel", Vector3(38.2, COUR_H, 87.1), 1.1)
	_modele("fp/Crate_Wooden", Vector3(39.2, COUR_H, 87.2), 0.2)
	_modele("fp/Crate_Wooden", Vector3(37.4, COUR_H + 0.0, 85.4), 0.7)
	_modele("fp/Shield_Wooden", Vector3(R.position.x - 0.02, H0 + 2.1, 85.0), -PI * 0.5)
	_modele("fp/Sword_Bronze", Vector3(R.position.x - 0.03, H0 + 1.7, 85.9), -PI * 0.5)
	_fusion_gltf(d2, "forge_atelier_accessoires")
