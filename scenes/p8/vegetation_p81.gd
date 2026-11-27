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
const ARBUSTES := [["Bush_Common", 0.48, 0.66]]
const PLANTES := [["Plant_1", 0.42, 0.6]]                    # Plant_7 écarté : feuillage violet
const FLEURS := [["Flower_3_Group", 0.26, 0.36], ["Flower_3_Group", 0.26, 0.36], ["Flower_4_Group", 0.22, 0.3]]   # Flower_4 : 1 690 triangles, plus rare
const COUVRE_SOL := [["Grass_Common_Short", 0.35, 0.5], ["Grass_Common_Short", 0.4, 0.55], ["Clover_2", 0.45, 0.65]]   # trèfle : 615 triangles, herbe : 155
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
func garnir(r: Rect2, h: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x * 131.0 + r.position.y * 17.0) + 7
	var d0: int = a.racine.get_child_count()
	var y := r.position.y + 0.3
	while y < r.end.y - 0.15:
		var prof := (y - r.position.y) / maxf(0.5, r.size.y)       # 0 au fond, 1 devant
		var x := r.position.x + rng.randf_range(0.2, 0.5)
		while x < r.end.x - 0.2:
			var p := Vector3(x + rng.randf_range(-0.12, 0.12), h, y + rng.randf_range(-0.12, 0.12))
			var t := rng.randf()
			if prof < 0.35:
				if t < 0.7:
					_choix(ARBUSTES, rng, p)
					x += rng.randf_range(0.8, 1.05)
					continue
				_choix(PLANTES, rng, p, 1.3)
			elif prof < 0.75:
				if t < 0.2:
					_choix(ARBUSTES, rng, p, 0.8)
				elif t < 0.86:
					_choix(PLANTES, rng, p, 1.25)
				else:
					_choix(FLEURS, rng, p)
			else:
				_choix(COUVRE_SOL if t < 0.62 else (PLANTES if t < 0.86 else FLEURS), rng, p, 1.2)
			x += rng.randf_range(0.55, 0.8)
		y += rng.randf_range(0.55, 0.7)
	b._forge()._fusion_gltf(d0, "vegetation_massif")


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
