extends RefCounted
## P3 — Animation des personnages, commune à A (AnimatedSprite2D) et B (AnimatedSprite3D) : mêmes images, mêmes
## règles (4 directions pour Aren, profil retourné pour les autres ; marche pilotée par la distance parcourue).
## Les sprites existants sont réutilisés tels quels (proportions conservées) ; les pieds = milieu du bas de l'image.

const BASE := "res://art/p45/chars/%s/"           # P4.5 (anciens dossiers retirés)
## P4 : dossier de sprites imposé pour une clé (ex. "ilya" -> art/p4/chars/ilya/) ; vide = dossiers d'origine.
static var overrides := {}
## P4.5 : 0,42 m par image de marche -> un cycle (2 pas, 4 images) tous les 1,7 m, soit ~2 cycles/s à 3,6 m/s ; la
## cadence suit la vitesse RÉELLE (distance parcourue), donc pas de glissement des pieds aux vitesses plus lentes.
const STRIDE_M := 0.42                     # repli (personnages sans marche.json : le garde)
const IDLE_FPS := 4.0
## P4.8 : au-delà de cette vitesse (course, Maj), la cadence n'augmente plus qu'en racine de la vitesse (sinon 7 pas/s).
const RUN_FROM_M_S := 2.4                      # attente : 8 images à 4 i/s (cycle de 2 s : respiration, poids, mèche)

var key := ""
var four := false
var frames: SpriteFrames
var anim := ""
var flip := false
var frame := 0
var _dist := 0.0
var _dir := "face"
var _still := 0.0
var stride_m := STRIDE_M                   # distance parcourue par image de marche
var _base := ""


static func make(k: String) -> RefCounted:
	var a = load("res://src/explore25/actor25.gd").new()
	a._build(k)
	return a


func _build(k: String) -> void:
	key = k
	var base: String = overrides.get(k, BASE % k)
	_base = base
	four = ResourceLoader.exists(base + "walk_face_0.png")
	frames = SpriteFrames.new()
	frames.remove_animation("default")
	if four:
		for d in ["face", "back", "left", "right"]:
			frames.add_animation("idle_" + d)
			frames.add_frame("idle_" + d, load(base + "idle_%s.png" % d))
			var n := 1
			while ResourceLoader.exists(base + "idle_%s_%d.png" % [d, n]):    # P4.5 : attente animée (8 images)
				frames.add_frame("idle_" + d, load(base + "idle_%s_%d.png" % [d, n]))
				n += 1
			frames.add_animation("walk_" + d)
			var w := 0
			while w < 8 and ResourceLoader.exists(base + "walk_%s_%d.png" % [d, w]):   # P4.8 : 4 ou 8 images
				frames.add_frame("walk_" + d, load(base + "walk_%s_%d.png" % [d, w]))
				w += 1
	else:
		frames.add_animation("idle_right")
		frames.add_frame("idle_right", load(base + "idle.png"))
		frames.add_animation("walk_right")
		if ResourceLoader.exists(base + "walk_0.png"):
			for i in 4:
				frames.add_frame("walk_right", load(base + "walk_%d.png" % i))
		else:
			frames.add_frame("walk_right", load(base + "idle.png"))
	for a in frames.get_animation_names():
		frames.set_animation_speed(a, 0.0)
		frames.set_animation_loop(a, true)
	anim = "idle_face" if four else "idle_right"


## P4.8 — pieds sans glissement : la longueur du pas DESSINÉE (marche.json, pixels de sprite) est convertie en mètres
## avec le facteur de taille k du personnage ; un cycle (2 pas) couvre toutes les images de marche.
func set_scale_k(k: float) -> void:
	var path := _base + "marche.json"
	if not FileAccess.file_exists(path):
		return
	var m: Dictionary = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
	var n := frames.get_frame_count("walk_face") if four else 4
	if float(m.get("step_px", 0.0)) > 0.0 and n > 0:
		stride_m = float(m["step_px"]) * k / 20.0 * 2.0 / n      # 20 = World25.PPM (pixels natifs par mètre)


## moved_m : distance parcourue cette image ; sdir : direction de marche À L'ÉCRAN (ou nulle).
func step(moved_m: float, sdir: Vector2, delta: float) -> void:
	if moved_m > 0.0005 and sdir != Vector2.ZERO:
		_still = 0.0
		var v := moved_m / maxf(delta, 0.001)
		_dist += moved_m if v <= RUN_FROM_M_S else moved_m * sqrt(RUN_FROM_M_S / v)
		if four:
			_dir = ("right" if sdir.x > 0 else "left") if absf(sdir.x) > absf(sdir.y) * 1.1 else ("face" if sdir.y > 0 else "back")
		elif absf(sdir.x) > 0.2:
			flip = sdir.x < 0
		var was_idle := not anim.begins_with("walk")
		anim = ("walk_" + _dir) if four else "walk_right"
		if was_idle:
			_dist = stride_m * 0.5              # premier pas : jambe avant levée tout de suite (pas de glissement)
		frame = int(_dist / stride_m) % frames.get_frame_count(anim)
	else:
		_still += delta
		if _still > 0.1:
			anim = ("idle_" + _dir) if four else "idle_right"
			# attente : repart de la pose neutre à l'arrêt, puis respire (les pieds ne bougent jamais)
			frame = int((_still - 0.1) * IDLE_FPS) % frames.get_frame_count(anim)


func face_toward(sdir: Vector2) -> void:
	if four:
		_dir = ("right" if sdir.x > 0 else "left") if absf(sdir.x) > absf(sdir.y) else ("face" if sdir.y > 0 else "back")
		if anim != "idle_" + _dir:
			anim = "idle_" + _dir
			frame = 0                  # l'image de marche en cours n'existe pas dans le repos (texture nulle)
			_still = 0.1               # l'attente animée reprend de la pose neutre
	elif absf(sdir.x) > 0.01:
		flip = sdir.x < 0


func texture() -> Texture2D:
	return frames.get_frame_texture(anim, frame)
