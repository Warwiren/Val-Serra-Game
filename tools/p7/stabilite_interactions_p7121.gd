extends SceneTree
## P7.12.1 — Stabilité du cadrage pendant les interactions (examens) dans la ville V0.7-B, sur ses trois niveaux.
## Lance la ville avec le parcours p7_7121_interactions et mesure, pour chaque examen, l'écart maximal du centre de la
## caméra (px d'écran natifs, au zoom courant) entre la position stabilisée juste avant l'ouverture et chaque image
## pendant l'examen puis après la fermeture. Attendu : 0 (aucun recentrage vertical).
## godot --headless --path . --script res://tools/p7/stabilite_interactions_p7121.gd -- [--camera_ville=A|B] [--visee_dialogue=1]

var n := 0
var sc
var ouvert := false
var ref := Vector2.ZERO
var ref3 := Vector3.ZERO
var ecarts := []
var ecart := 0.0
var ecart3 := 0.0
var apres := 0
var prev := Vector2.ZERO
var prev3 := Vector3.ZERO


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.has("--route=p7_7121_interactions"):
		print("Ajouter -- --route=p7_7121_interactions --quit")
	change_scene_to_file("res://scenes/p7/ville_v07b.tscn")


func _process(_d: float) -> bool:
	n += 1
	if sc == null:
		if current_scene != null and current_scene.get("s") != null and current_scene.s != null:
			sc = current_scene
		return false
	var s = sc.s
	var c: Vector2 = s.cam.center * s.cam.zoom
	var c3: Vector3 = sc.cam.global_position
	var o: bool = s.dialogue_open
	if o and not ouvert:
		ref = prev
		ref3 = prev3
		ecart = 0.0
		ecart3 = 0.0
		apres = 0
	if ouvert or apres > 0:
		ecart = maxf(ecart, (c - ref).length())
		ecart3 = maxf(ecart3, (c3 - ref3).length())
	if ouvert and not o:
		apres = 60
	if apres > 0:
		apres -= 1
		if apres == 0:
			ecarts.append([snappedf(ecart, 0.01), snappedf(ecart3, 0.001), Vector3(s.hero.x, s.hero.y, s.hero.z).snappedf(0.1)])
	ouvert = o
	prev = c
	prev3 = c3
	if s.pilot_done or n > 60 * 120:
		var mx := 0.0
		for e in ecarts:
			mx = maxf(mx, float(e[0]))
		print("STABILITE ", JSON.stringify({"interactions": ecarts.size(), "ecart_max_px": snappedf(mx, 0.01), "detail": str(ecarts)}))
		quit()
	return false
