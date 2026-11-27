extends RefCounted
## P8.1-A (L4) — VOCABULAIRE VÉGÉTAL DE LA CITÉ (remplace les amas de sphères vertes, non validés).
## Modèles Quaternius CC0 déjà validés dans la forêt F5 (ValSerra_P49_V07B_PREFLIGHT_GODOT/assets/models, licence dans
## ValSerra_P49_V07B_PREFLIGHT_GODOT/docs/) : arbuste aux feuillages Val'Serra, plantes feuillues, couvre-sol, groupes
## de fleurs ; plantes grimpantes du pack Medieval Village (art/p63/quaternius/mv/Prop_Vine*, CC0). Variations
## d'échelle, de rotation et de mélange par une graine propre à chaque massif ; maillages fusionnés par matière.
## Branché sur Archi.jardiniere (Archi.plantes) : toutes les jardinières de la ville changent ensemble, terre, pots de
## terre cuite et bordure de pierre conservés. --f_vegetation=0 : sphères P7.7.

const NAT := "res://ValSerra_P49_V07B_PREFLIGHT_GODOT/assets/models/"
const QUAT := "res://art/p63/quaternius/"
## [modèle, échelle min, échelle max] : tailles réelles visées (arbuste 0,7 à 1 m, plantes 0,4 à 0,6 m, fleurs 0,5 à
## 0,8 m, couvre-sol 0,2 m)
const ARBUSTES := [["Bush_Common", 0.38, 0.5]]              # P8.1-A2 : 0,6 à 0,8 m (moins haut)
const PLANTES := [["Plant_1", 0.42, 0.6]]                    # Plant_7 écarté : feuillage violet
const FLEURS := [["Flower_3_Group", 0.26, 0.36], ["Flower_3_Group", 0.26, 0.36], ["Flower_4_Group", 0.22, 0.3]]   # Flower_4 : 1 690 triangles, plus rare
const COUVRE_SOL := [["Grass_Common_Short", 0.35, 0.5], ["Grass_Wispy_Short", 0.35, 0.5], ["Clover_2", 0.45, 0.65], ["Fern_1", 0.05, 0.07]]   # trèfle : 615 triangles, herbe : 155
const VIGNES := ["mv/Prop_Vine1", "mv/Prop_Vine2", "mv/Prop_Vine4"]

var b                 # constructeur de la ville (ville_v07b.gd) : fusion des modèles (forge_p79._fusion_gltf)
var a                 # composants (Archi)
var _cache := {}


func _init(builder, archi) -> void:
	b = builder
	a = archi


func _inst(chemin: String, pos: Vector3, rot_y: float, k: float) -> void:
	if not _cache.has(chemin):
		_cache[chemin] = load(chemin + ".gltf")
	var ps: PackedScene = _cache[chemin]
	if ps == null:
		push_warning("P8.1-A : modèle introuvable " + chemin)
		return
	var n: Node3D = ps.instantiate()
	n.position = pos
	n.rotation.y = rot_y
	n.scale = Vector3.ONE * k
	a.racine.add_child(n)


func _choix(liste: Array, rng: RandomNumberGenerator, pos: Vector3, facteur := 1.0) -> void:
	var m: Array = liste[rng.randi() % liste.size()]
	_inst(NAT + str(m[0]), pos, rng.randf_range(0.0, TAU), rng.randf_range(m[1], m[2]) * facteur)


## Massif d'une jardinière (rectangle intérieur r, terre à la hauteur h), rempli rang par rang du fond (nord, côté mur)
## vers l'avant : arbustes au fond, feuillages au milieu, couvre-sol devant ; fleurs en touches rares (≈ 15 %, couleurs
## sourdes du feuillage dominant) ; positions et
## tailles décalées au hasard (graine du massif) : aucune rangée régulière, la terre ne se voit qu'entre les plants.
## `bas` (P8.1-A3, jardins en terrasse du parvis) : aucun arbuste, plantations basses seulement.
func garnir(r: Rect2, h: float, bas := false) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x * 131.0 + r.position.y * 17.0) + 7
	var d0: int = a.racine.get_child_count()
	var y := r.position.y + 0.3
	while y < r.end.y - 0.15:
		var prof := (y - r.position.y) / maxf(0.5, r.size.y)       # 0 au fond, 1 devant
		if bas:
			prof = maxf(prof, 0.4)
		var x := r.position.x + rng.randf_range(0.2, 0.6)
		while x < r.end.x - 0.2:
			var p := Vector3(x + rng.randf_range(-0.15, 0.15), h, y + rng.randf_range(-0.15, 0.15))
			var t := rng.randf()
			if rng.randf() < 0.14:
				x += rng.randf_range(0.5, 0.9)                 # P8.1-A2 : trous naturels (pas de masse continue)
				continue
			if prof < 0.35:
				if t < 0.62:
					_choix(ARBUSTES, rng, p)
					x += rng.randf_range(0.95, 1.3)
					continue
				_choix(PLANTES, rng, p, 1.15)
			elif prof < 0.75:
				if t < 0.16 and not bas:
					_choix(ARBUSTES, rng, p, 0.8)
				elif t < 0.84:
					_choix(PLANTES if t < 0.6 else COUVRE_SOL, rng, p, 1.1)
				else:
					_choix(FLEURS, rng, p)
			else:
				_choix(COUVRE_SOL if t < 0.66 else (PLANTES if t < 0.86 else FLEURS), rng, p, 1.1)
			x += rng.randf_range(0.65, 0.95)
		y += rng.randf_range(0.65, 0.8)
	_teinter(d0, absi(int(r.position.x * 7.0 + r.position.y * 3.0)) % NUANCES.size())
	b._forge()._fusion_gltf(d0, "vegetation_massif")


## P8.1-A2 : nuance de feuillage propre à chaque massif (trois nuances discrètes, couleurs des fleurs inchangées) : deux
## jardinières voisines ne se ressemblent pas. Les matières nuancées sont partagées (cache) : pas d'appel de dessin en plus
## par massif au-delà de la fusion existante.
const NUANCES := [Color(1.0, 1.0, 1.0), Color(0.9, 0.98, 0.84), Color(1.06, 1.0, 0.86)]
var _nuancees := {}


func _teinter(depuis: int, k: int) -> void:
	if k == 0:
		return
	for i in range(depuis, a.racine.get_child_count()):
		for mi in (a.racine.get_child(i) as Node).find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.mesh == null:
				continue
			for s in m.mesh.get_surface_count():
				var m0 := m.get_active_material(s) as StandardMaterial3D
				if m0 == null or m0.resource_name.contains("Flower"):
					continue
				var cle := "%d|%d" % [m0.get_instance_id(), k]
				if not _nuancees.has(cle):
					var mn := m0.duplicate() as StandardMaterial3D
					mn.albedo_color = m0.albedo_color * NUANCES[k]
					_nuancees[cle] = mn
				m.set_surface_override_material(s, _nuancees[cle])


## Plante en pot (pot de terre cuite posé par l'appelant, terre au niveau h) : plante feuillue ou fleurs.
func pot(p: Vector3, graine: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = graine
	var d0: int = a.racine.get_child_count()
	_choix(PLANTES if rng.randf() < 0.5 else FLEURS, rng, p, 0.85)
	b._forge()._fusion_gltf(d0, "vegetation_pot")


## Plante grimpante contre une façade (point au pied, orientation de la façade) : vigne du pack Medieval Village.
func vigne(pied: Vector3, rot_y: float, graine: int, k := 1.0) -> void:
	var d0: int = a.racine.get_child_count()
	_inst(QUAT + VIGNES[graine % VIGNES.size()], pied, rot_y, k)
	b._forge()._fusion_gltf(d0, "vegetation_vigne")
