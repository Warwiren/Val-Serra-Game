extends RefCounted
## P7.9 — COMPARATIF ARCHITECTURAL DE LA FORGE-ARMURERIE (seul commerce traité ; les autres attendent la décision).
## Même emprise (x 44 -> 58, y 76 -> 88), même hauteur de murs (3,5 -> 7,5 m), même entrée fonctionnelle (x 51, façade sud,
## piédroits à collision des données), même caméra, même éclairage ; collision du bâtiment = celle des données.
##   A : bibliothèque du projet (scenes/p7/archi_p77.gd) : maçonnerie procédurale du Colisée, toit de tuiles procédural.
##   B : modules Quaternius CC0 (Medieval Village : murs de brique, baies cintrées, volets, porte, toit de tuiles, pignons,
##       cheminée ; Fantasy Props : accessoires d'atelier). Maillages fusionnés par matière (peu d'appels de dessin).
##   C : hybride : murs et baies A (cohérence avec le Colisée et la tranche) + toit et pignons, vantaux, cheminée et
##       accessoires Quaternius.
## Accessoires de la cour : posés SUR la plate-forme basse existante à l'ouest (étals « echoppe_no », 0,45 m, x 36 -> 44),
## hors des circulations : aucune collision ajoutée ni retirée. Choix : --forge=A|B|C (sinon le blockout V0.7-B), ou les
## scènes F6 scenes/p7/ville_v07b_forge_{a,b,c}.tscn.

const Archi := preload("res://scenes/p7/archi_p77.gd")
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


## P7.10 : C (C+) retenue comme base de production : c'est la forge par défaut de la V0.7-B ; --forge=0 : blockout.
static func lire_variante(scene) -> String:
	var defaut := "C"
	if scene.get("forge_variante") != null and str(scene.get("forge_variante")) != "":
		defaut = str(scene.get("forge_variante"))
	var v := str(scene._cli.get("forge", defaut)).to_upper()
	return v if v in ["A", "B", "C"] else ""


# ------------------------------------------------------------------------------------------------ construction
func batiment() -> void:
	match variante:
		"A":
			_archi(false)
			_accessoires_archi()
		"B":
			_quaternius()
			_accessoires_quaternius()
		"C":
			_archi(true)
			_atelier_c()


## Entrée fonctionnelle de la forge (données ENTREES) : true si la variante la dessine elle-même.
func entree() -> bool:
	if variante == "B":
		_porte_quaternius()
		return true
	return false


## Après l'entrée en pierre (A, C) : en C, vantaux Quaternius dans l'avant-corps.
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


# ------------------------------------------------------------------------------------------------ A / C : bibliothèque
func _archi(hybride: bool) -> void:
	var pal: Array = Archi.PALETTES["gris_chaud"]
	var d := {"id": "bat_forge_armurerie", "niveaux": [H0, 6.9 if hybride else 6.4, H1], "enduit": pal[0], "volets": Color(0.24, 0.22, 0.20),
		"rdc": "bossage", "etages": "pierre", "corniche": "consoles", "toit_h": 3.0, "volets_style": "aucun",
		"toit": "aucun" if hybride else "2p_x",
		"faces": {
			# C+ : grande baie CINTRÉE éclairée (vitrine de l'armurerie : arc de claveaux, petits bois, lueur de la forge)
			"s": [[[3.0, 2.0, 1.8, 0.4, "baie_cintree"] if hybride else [3.0, 2.4, 2.2, 0.4, "baie"], [11.2, 1.0, 1.6, 0.7, "fenetre_cintree"]], []],
			"e": [[[3.0, 0.9, 1.1, 1.0, "barreaux"], [7.5, 0.9, 1.1, 1.0, "barreaux"]], []],
			"o": [[[6.0, 2.4, 2.6, 0.0, "porte_cochere"]], []],
		}}
	a.batiment(R, H0, d)
	# cheminée de forge : haute souche de pierre, chaperon ; en C, cheminée Quaternius
	if hybride:
		_toit_quaternius(true)
		_cheminee_forge()
		_enseigne_armurerie()
	else:
		var depuis2: int = a.racine.get_child_count()
		a.box(Vector3(55.5, H1 + 2.6, 79.5), Vector3(1.3, 5.2, 1.1), a.macon("mur2", Archi.PIERRE_VILLE * 0.9, H1))
		a.box(Vector3(55.5, H1 + 5.3, 79.5), Vector3(1.55, 0.22, 1.35), a.moulure())
		a.fusionner(depuis2, "forge_cheminee")


func _accessoires_archi() -> void:
	var depuis: int = a.racine.get_child_count()
	var fer: Material = a.fer()
	var bois: Material = a.bois()
	var bois_c: Material = a.plein(Color(0.42, 0.30, 0.20))
	# billot et enclume
	_cyl(Vector3(40.6, COUR_H + 0.3, 84.0), 0.32, 0.6, bois_c)
	a.box(Vector3(40.6, COUR_H + 0.7, 84.0), Vector3(0.7, 0.2, 0.3), fer)
	a.box(Vector3(41.05, COUR_H + 0.72, 84.0), Vector3(0.3, 0.12, 0.18), fer)
	# établi contre le mur ouest de la forge
	a.box(Vector3(43.3, COUR_H + 0.86, 80.5), Vector3(0.8, 0.08, 2.2), bois_c)
	for dz in [-0.95, 0.95]:
		a.box(Vector3(43.3, COUR_H + 0.41, 80.5 + dz), Vector3(0.7, 0.82, 0.1), bois)
	# tonneaux, caisse, seau
	for p in [Vector3(37.4, COUR_H, 86.7), Vector3(38.3, COUR_H, 87.0)]:
		_cyl(p + Vector3(0, 0.45, 0), 0.34, 0.9, bois_c)
		for hb in [0.18, 0.72]:
			_cyl(p + Vector3(0, hb, 0), 0.355, 0.05, fer)
	a.box(Vector3(39.4, COUR_H + 0.3, 87.1), Vector3(0.65, 0.6, 0.65), bois)
	_cyl(Vector3(40.3, COUR_H + 0.17, 85.2), 0.22, 0.34, fer)
	# râtelier d'armes : montants et lames (boîtes)
	a.box(Vector3(37.6, COUR_H + 0.8, 81.5), Vector3(0.12, 1.6, 1.8), bois)
	for dz in [-0.6, -0.2, 0.2, 0.6]:
		a.box(Vector3(37.75, COUR_H + 1.0, 81.5 + dz), Vector3(0.04, 1.2, 0.08), a.plein(Color(0.62, 0.62, 0.64), 0.4, 0.0, 0.6))
	a.fusionner(depuis, "forge_cour")


func _cyl(c: Vector3, r: float, h: float, m: Material) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 12
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = m
	mi.position = c
	a.racine.add_child(mi)


# ------------------------------------------------------------------------------------------------ B : Quaternius
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


## Murs : modules de 2 m (brique irrégulière), hauteur portée de 3,12 à 4 m ; face extérieure sur la limite de l'emprise.
func _quaternius() -> void:
	var depuis: int = a.racine.get_child_count()
	var ky := (H1 - H0) / 3.12
	# [face, rotation, nombre, positions des baies (index de module) -> type]
	var faces := [
		["s", 0.0, 7, {1: "fenetre", 3: "porte", 5: "fenetre"}],
		["e", PI * 0.5, 6, {1: "fenetre", 4: "fenetre"}],
		["o", -PI * 0.5, 6, {3: "porte"}],
		["n", PI, 7, {}],
	]
	for f in faces:
		for i in int(f[2]):
			var u := 1.0 + 2.0 * i
			var p := Vector3.ZERO
			match str(f[0]):
				"s":
					p = Vector3(R.position.x + u, H0, R.end.y - 0.09)
				"n":
					p = Vector3(R.end.x - u, H0, R.position.y + 0.09)
				"e":
					p = Vector3(R.end.x - 0.09, H0, R.end.y - u)
				"o":
					p = Vector3(R.position.x + 0.09, H0, R.position.y + u)
			var typ: String = (f[3] as Dictionary).get(i, "mur")
			var nom := "mv/Wall_UnevenBrick_Straight"
			if typ == "fenetre":
				nom = "mv/Wall_UnevenBrick_Window_Wide_Round"
			elif typ == "porte":
				nom = "mv/Wall_UnevenBrick_Door_Round"
			_modele(nom, p, float(f[1]), Vector3(1.0, ky, 1.0))
			if typ == "fenetre":
				_modele("mv/Window_Wide_Round1", p, float(f[1]), Vector3(1.0, ky, 1.0))
				_modele("mv/WindowShutters_Wide_Round_Open", p, float(f[1]), Vector3(1.0, ky, 1.0))
	# chaînes d'angle
	for c in [[R.position.x, R.end.y, 0.0], [R.end.x, R.end.y, PI * 0.5], [R.end.x, R.position.y, PI], [R.position.x, R.position.y, -PI * 0.5]]:
		_modele("mv/Corner_Exterior_Brick", Vector3(c[0], H0, c[1]), float(c[2]), Vector3(1.0, (H1 - H0) / 3.01, 1.0))
	_toit_quaternius()
	_modele("mv/Prop_Chimney", Vector3(55.5, H1 + 1.2, 79.5), 0.0, Vector3(1.2, 1.5, 1.2))
	_fusion_gltf(depuis, "forge_quaternius")
	# lueur de la forge derrière les baies de la façade sud (plan émissif intérieur, sans lumière ajoutée)
	var lueur = a.plein(Color(1.0, 0.55, 0.22), 0.6, 2.2)
	for x in [R.position.x + 3.0, R.position.x + 11.0]:
		a.box(Vector3(x, H0 + 2.0, R.end.y - 0.45), Vector3(1.6, 1.6, 0.04), lueur)


## Toit de tuiles Quaternius (faîtage est-ouest : versant face caméra), pignons enduits (B et C).
func _toit_quaternius(terre_cuite := false) -> void:
	var kz := (R.size.y + 0.9) / 9.96
	var toit := _modele("mv/Roof_RoundTiles_8x12", Vector3(R.get_center().x, H1, R.get_center().y), PI * 0.5, Vector3(kz, 0.55, (R.size.x + 0.6) / 14.14))
	if terre_cuite:
		# C+ : le toit n'est PAS fusionné (mise à l'échelle non uniforme : les normales restent calculées par le moteur) et
		# reçoit une terre cuite plus chaude et moins saturée que la tuile d'origine (B)
		_terre_cuite(toit)
	for s in [-1.0, 1.0]:
		var x := R.position.x if s < 0.0 else R.end.x
		_modele("mv/Roof_Front_Brick8", Vector3(x, H1, R.get_center().y), -PI * 0.5 * s, Vector3(R.size.y / 8.5, 0.55 * 6.0 / 5.31, 1.0))


## Entrée B : encadrement cintré de brique (couvre les piédroits à collision de l'entrée) et vantaux de bois.
func _porte_quaternius() -> void:
	var depuis: int = a.racine.get_child_count()
	_modele("mv/DoorFrame_Round_Brick", Vector3(PORTE_X, H0, R.end.y + 0.0), 0.0, Vector3(3.3 / 1.6, 3.2 / 2.58, 2.0))
	for s in [-1.0, 1.0]:
		var x := PORTE_X - 1.2 if s < 0.0 else PORTE_X + 1.2
		var n := _modele("mv/Door_8_Round", Vector3(x, H0, R.end.y - 0.05), 0.0, Vector3(1.1, 2.6 / 2.36, 1.0))
		if s > 0.0:
			n.scale.x = -1.1
	_fusion_gltf(depuis, "forge_porte")


func _accessoires_quaternius() -> void:
	var depuis: int = a.racine.get_child_count()
	_modele("fp/Anvil", Vector3(40.6, COUR_H, 84.0), 0.3, Vector3.ONE * 1.25)
	_modele("fp/Workbench", Vector3(43.3, COUR_H, 80.5), PI * 0.5)
	_modele("fp/Whetstone", Vector3(38.6, COUR_H, 79.4), 0.6)
	_modele("fp/Barrel", Vector3(37.4, COUR_H, 86.7), 0.0)
	_modele("fp/Barrel", Vector3(38.3, COUR_H, 87.1), 1.1)
	_modele("fp/Crate_Wooden", Vector3(39.4, COUR_H, 87.1), 0.2)
	_modele("fp/Bucket_Metal", Vector3(40.3, COUR_H, 85.2), 0.0)
	_modele("fp/WeaponStand", Vector3(37.6, COUR_H, 81.5), PI * 0.5)
	_modele("fp/Shield_Wooden", Vector3(R.position.x - 0.02, H0 + 2.1, 84.5), -PI * 0.5)
	_modele("fp/Sword_Bronze", Vector3(R.position.x - 0.03, H0 + 1.7, 85.4), -PI * 0.5)
	_fusion_gltf(depuis, "forge_accessoires")


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
