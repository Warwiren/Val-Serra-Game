extends RefCounted
## P3 — CONTRÔLEUR D'EXPLORATION commun aux démonstrations A et B : entrées, zoom, caméra, compagnon sur la trace
## du héros, dialogue / interactions, sorties d'instance, pilote automatique, mesures et HUD de débogage.
## Seuls le déplacement physique du héros, le rendu et l'occultation sont propres à chaque démonstration
## (« adaptateur » : le nœud de la scène, voir demo_a_2d.gd et explore_3d.gd) — conditions de comparaison égales.

const World25 = preload("res://src/explore25/world25.gd")
const Cam25 = preload("res://src/explore25/cam25.gd")
const Routes = preload("res://src/explore25/routes25.gd")

var host: Node                            # adaptateur (scène)
var arch := ""                            # "A — Camera2D" / "B — Camera3D"
var world
var cam
var hero := Vector3()                     # position du héros (plan x, y, altitude h)
var hero_region := ""
var hero_dir := Vector2(0, 1)             # dernière direction écran
var companion := Vector3()
var trail: Array = []                     # points de la trace du héros (Vector3), du plus ancien au plus récent
var trail_len: Array = []                 # longueur cumulée
var dialogue_open := false
var _lines: Array = []
var _line_i := 0
var _armed := {}                          # sorties : réarmées quand on en est sorti
var pending_instance := {}                # demande de changement d'instance (traitée par l'adaptateur)
var options := {"debug": true, "layers": false, "grid": true, "occlusion": 1, "filter_linear": true, "anim": true}
var fps_caps := [0, 30, 60, 144]
var fps_cap_i := 0
# --- pilote et mesures
var pilot: Array = []
var pilot_i := 0
var pilot_name := ""
var pilot_t := 0.0
var pilot_best := INF
var pilot_stall := 0.0
var pilot_done := false
var m := {}                               # mesures du parcours
var _prev_cam := Vector2.INF
var _prev_cam_v := Vector2.ZERO
var _occ_run := 0.0
var _last_h := INF
var _skip_measure := 0
var _dither := 0.0
var _zone := "8 directions"                # tronçon courant du parcours « validation » (mesures par tronçon)
var _occ_from := Vector3()
var hud: CanvasLayer
var _dbg: Label
var _help: Label
var _box: PanelContainer
var _box_text: Label
var _toast: Label
var _toast_t := 0.0
var _fade: ColorRect
var interact_hint := ""


func _init(h: Node, a: String) -> void:
	host = h
	arch = a
	cam = Cam25.new()
	_reset_metrics()


func set_world(w, arrive := Vector3.INF) -> void:
	world = w
	cam.bounds = world.camera_bounds()
	hero = world.spawn if arrive == Vector3.INF else arrive
	hero_region = world.surface_at(Vector2(hero.x, hero.y), hero.z).get("id", "")
	# trace initiale derrière le héros (vers l'entrée : l'ouest pour l'entrée, l'est pour un retour)
	_rebuild_trail([Vector2(-1, 0), Vector2(0, 1)] if arrive == Vector3.INF else [Vector2(1, 0), Vector2(0, 1)])
	_skip_measure = 2
	_armed.clear()
	for t in world.triggers:
		_armed[t["id"]] = not (t["rect"] as Rect2).has_point(Vector2(hero.x, hero.y))
	cam.snap_to(World25.screen(hero))
	_prev_cam = Vector2.INF


## Trace initiale : 2 m derrière le héros, dans la première direction où chaque point est tenable.
func _rebuild_trail(dirs: Array) -> void:
	trail.clear()
	trail_len.clear()
	var hp := Vector2(hero.x, hero.y)
	var chosen := Vector2.ZERO
	for d in dirs:
		var ok := true
		for i in range(1, 21):
			if world.stand(hp + d * 0.1 * i, hero.z).is_empty():
				ok = false
				break
		if ok:
			chosen = d
			break
	for i in range(20, -1, -1):
		var q: Vector2 = hp + chosen * 0.1 * i
		var s2: Dictionary = world.surface_at(q, hero.z)
		_push_trail(Vector3(q.x, q.y, s2.get("h", hero.z)))
	companion = _trail_point(world.follow_gap)


## Place le héros (essais ciblés, captures) : trace, compagnon et caméra recalés, sans glissade.
func warp_to(p: Vector3) -> void:
	var s: Dictionary = world.surface_at(Vector2(p.x, p.y), p.z)
	if s.is_empty():
		# altitude donnée approximative (ex. dans l'escalier) : surface la plus proche sous ce point
		var bd := INF
		for u in world.surfaces_under(Vector2(p.x, p.y)):
			if absf(u["h"] - p.z) < bd:
				bd = absf(u["h"] - p.z)
				s = u
	hero = Vector3(p.x, p.y, s.get("h", p.z))
	hero_region = s.get("id", "")
	_rebuild_trail([Vector2(-1, 0), Vector2(1, 0), Vector2(0, 1), Vector2(0, -1)])
	m["warps"] = m.get("warps", 0) + 1
	_skip_measure = 2
	host.teleport(hero, companion)
	cam.snap_to(World25.screen(hero))
	_prev_cam = Vector2.INF


## Taille de référence de la vue. Sans écran (--headless), la fenêtre virtuelle de Godot n'est pas 1280 × 720 :
## on impose la référence 1280 × 720 pour que les mesures soient celles du jeu affiché.
static func viewport_size(n: Node) -> Vector2:
	if DisplayServer.get_name() == "headless":
		return Vector2(1280, 720)
	return n.get_viewport().get_visible_rect().size


# ------------------------------------------------------------------------------------------------ HUD
func build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 50
	host.add_child(hud)
	_dbg = Label.new()
	_dbg.position = Vector2(10, 8)
	_dbg.add_theme_font_size_override("font_size", 13)
	_dbg.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_dbg.add_theme_constant_override("outline_size", 4)
	hud.add_child(_dbg)
	_help = Label.new()
	_help.position = Vector2(10, 694)
	_help.add_theme_font_size_override("font_size", 12)
	_help.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_help.add_theme_constant_override("outline_size", 4)
	_help.text = "Flèches/ZQSD : marcher · Molette (ou PgPréc/PgSuiv) : zoom ×2/×2,5/×3 · E : parler/examiner · F1 : infos · F2 : couches/collisions · G : grille · O : occultation · T : filtre · N : animations · F3 : limite i/s · P : parcours auto · R : retour à l'entrée"
	hud.add_child(_help)
	_box = PanelContainer.new()
	_box.position = Vector2(240, 560)
	_box.size = Vector2(800, 100)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.12, 0.92)
	sb.border_color = Color(0.85, 0.75, 0.5)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(14)
	_box.add_theme_stylebox_override("panel", sb)
	_box_text = Label.new()
	_box_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_box_text.add_theme_font_size_override("font_size", 18)
	_box.add_child(_box_text)
	_box.visible = false
	hud.add_child(_box)
	_toast = Label.new()
	_toast.position = Vector2(500, 60)
	_toast.add_theme_font_size_override("font_size", 16)
	_toast.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_toast.add_theme_constant_override("outline_size", 5)
	hud.add_child(_toast)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.size = Vector2(4000, 4000)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_fade)


func toast(t: String, d := 1.6) -> void:
	if not options["debug"] and pilot.size() > 0:
		return                                      # captures « propres » (--nodebug) : pas de bandeau
	_toast.text = t
	_toast_t = d


func fade_to(a: float, t := 0.25) -> Tween:
	var tw := host.create_tween()
	tw.tween_property(_fade, "color:a", a, t)
	return tw


# ------------------------------------------------------------------------------------------------ entrées
func handle_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_wheel(1)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_wheel(-1)
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.physical_keycode:
			KEY_PAGEUP, KEY_KP_ADD, KEY_EQUAL:
				_wheel(1)
			KEY_PAGEDOWN, KEY_KP_SUBTRACT, KEY_MINUS:
				_wheel(-1)
			KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				interact()
			KEY_ESCAPE:
				if dialogue_open:
					_close_dialogue()
			KEY_F1:
				options["debug"] = not options["debug"]
			KEY_F2:
				options["layers"] = not options["layers"]
				host.apply_options()
			KEY_G:
				options["grid"] = not options["grid"]
				host.apply_options()
			KEY_O:
				options["occlusion"] = (options["occlusion"] + 1) % 3
				toast("Occultation : " + ["aucune aide", "silhouette", "silhouette + transparence locale"][options["occlusion"]])
				host.apply_options()
			KEY_T:
				options["filter_linear"] = not options["filter_linear"]
				cam.snap = not options["filter_linear"]
				toast("Filtre des sprites : " + ("linéaire (projet)" if options["filter_linear"] else "au plus proche (nearest)"))
				host.apply_options()
			KEY_N:
				options["anim"] = not options["anim"]
				toast("Animation de l'eau : " + ("ON" if options["anim"] else "OFF"))
				host.apply_options()
			KEY_F3:
				fps_cap_i = (fps_cap_i + 1) % fps_caps.size()
				Engine.max_fps = fps_caps[fps_cap_i]
				toast("Limite : " + (str(fps_caps[fps_cap_i]) + " i/s" if fps_caps[fps_cap_i] > 0 else "aucune"))
			KEY_P:
				start_pilot("temoin" if world.mode == "temoin" else world.mode)
			KEY_R:
				host.respawn()


func _wheel(s: int) -> void:
	if cam.wheel(s):
		toast("Zoom ×%s" % str(cam.target_zoom()).replace(".", ","), 0.9)
		m["zoom_changes"] = m.get("zoom_changes", 0) + 1


func key_dir() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
		v.x -= 1
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
		v.x += 1
	if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W):
		v.y -= 1
	if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S):
		v.y += 1
	return v


# ------------------------------------------------------------------------------------------------ interactions
func _nearby() -> Dictionary:
	var hp := Vector2(hero.x, hero.y)
	if not world.npc.is_empty():
		var n: Dictionary = world.npc
		if hp.distance_to(Vector2(n["p"].x, n["p"].y)) <= n["range"] and absf(hero.z - n["p"].z) < 0.5:
			return {"kind": "npc", "lines": n["lines"], "label": "E  Parler"}
	for p in world.pois:
		if hp.distance_to(Vector2(p["p"].x, p["p"].y)) <= p["range"] and absf(hero.z - p["p"].z) < 0.5:
			return {"kind": "poi", "lines": [p["text"]], "label": "E  Examiner", "id": p["id"]}
	return {}


func interact() -> void:
	if dialogue_open:
		_line_i += 1
		if _line_i >= _lines.size():
			_close_dialogue()
		else:
			_box_text.text = _lines[_line_i]
		return
	var n := _nearby()
	if n.is_empty():
		return
	_lines = n["lines"]
	_line_i = 0
	dialogue_open = true
	cam.ui_lock = true
	_box.visible = true
	_box_text.text = _lines[0]
	m["interactions"] = m.get("interactions", []) + [n.get("id", n["kind"])]


func _close_dialogue() -> void:
	dialogue_open = false
	cam.ui_lock = false
	_box.visible = false


# ------------------------------------------------------------------------------------------------ trace et compagnon
func _push_trail(p: Vector3) -> void:
	if trail.is_empty():
		trail.append(p)
		trail_len.append(0.0)
		return
	var last: Vector3 = trail[-1]
	var d := Vector2(p.x - last.x, p.y - last.y).length()
	if d < 0.04:
		return
	trail.append(p)
	trail_len.append(trail_len[-1] + d)
	if trail.size() > 400:
		trail.pop_front()
		trail_len.pop_front()


## Point de la trace situé à une distance « gap » (le long du chemin) derrière le héros.
func _trail_point(gap: float) -> Vector3:
	if trail.size() < 2:
		return trail[0] if trail.size() > 0 else hero
	var target: float = trail_len[-1] - gap
	for i in range(trail.size() - 1, 0, -1):
		if trail_len[i - 1] <= target:
			var t: float = (target - trail_len[i - 1]) / maxf(0.0001, trail_len[i] - trail_len[i - 1])
			return (trail[i - 1] as Vector3).lerp(trail[i], t)
	return trail[0]


# ------------------------------------------------------------------------------------------------ image
func process(delta: float) -> void:
	if world == null:
		return
	var sdir := key_dir()
	if pilot.size() > 0 and not pilot_done:
		sdir = _pilot_dir(delta)
	if dialogue_open:
		sdir = Vector2.ZERO
	var dir: Vector2 = World25.input_to_plan(sdir)
	var on_ramp: bool = world.surface_at(Vector2(hero.x, hero.y), hero.z).get("ramp", false)
	var asd: Dictionary = world.assist(dir, on_ramp)
	dir = asd["dir"]
	var before := hero
	var st: Dictionary = host.step_hero(dir, delta)      # déplacement propre à l'architecture
	hero = st["p"]
	hero_region = st.get("id", "")
	var moved := Vector2(hero.x - before.x, hero.y - before.y).length()
	if sdir != Vector2.ZERO:
		hero_dir = World25.plan_to_screen_dir(dir) if moved > 0.0001 else sdir.normalized()
	_push_trail(hero)
	var comp_before := companion
	var ct := _trail_point(world.follow_gap)
	# le compagnon ne recule jamais vers le héros quand celui-ci fait demi-tour sur place
	companion = ct
	var cmoved := Vector2(companion.x - comp_before.x, companion.y - comp_before.y)
	host.animate(moved, hero_dir if moved > 0.0001 else Vector2.ZERO, cmoved.length(),
		World25.plan_to_screen_dir(cmoved) if cmoved.length() > 0.0001 else Vector2.ZERO, delta)
	# caméra
	cam.viewport_px = viewport_size(host)
	cam.update(World25.screen(hero), delta)
	host.apply_camera(cam.render_center(), cam.zoom)
	# sorties d'instance
	var hp := Vector2(hero.x, hero.y)
	for t in world.triggers:
		var inside := (t["rect"] as Rect2).has_point(hp)
		if inside and _armed.get(t["id"], true) and pending_instance.is_empty():
			pending_instance = t
			m["exits"] = m.get("exits", []) + [t["id"]]
			if pilot_i < pilot.size() and pilot[pilot_i].get("exit", false):
				_next_step(true)
		_armed[t["id"]] = not inside
	var nb := _nearby()
	interact_hint = nb.get("label", "") if not dialogue_open else ""
	_measure(delta, before, st)
	_hud(delta)


func _hud(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0:
			_toast.text = ""
	_dbg.visible = options["debug"]
	if not options["debug"]:
		return
	var lvl: int = world.level_of(hero.z)
	var under: Array = world.surfaces_under(Vector2(hero.x, hero.y))
	var ids := []
	for u in under:
		ids.append("%s h=%.2f" % [u["id"], u["h"]])
	_dbg.text = "%s   ·   %s   ·   %d i/s%s\nx %.2f  y %.2f  h %.2f m   ·   niveau %s   ·   surface : %s\nsous le héros : %s\nzoom ×%s%s   ·   vue %.1f × %.1f m (plan de l'écran)   ·   occultation : %s   ·   filtre : %s%s%s" % [
		arch, world.path.get_file() + (" (micro-test)" if world.mode == "micro" else ""), Engine.get_frames_per_second(),
		("  (limite %d)" % Engine.max_fps) if Engine.max_fps > 0 else "",
		hero.x, hero.y, hero.z, "+1" if lvl == 1 else "0", hero_region, ", ".join(ids) if ids.size() > 0 else "—",
		str(cam.target_zoom()).replace(".", ","), " (transition)" if cam.zooming() else "",
		cam.view_size().x / World25.PPM, cam.view_size().y / World25.PPM,
		["aucune aide", "silhouette", "silhouette + transparence"][options["occlusion"]],
		"linéaire" if options["filter_linear"] else "nearest",
		("\n" + interact_hint) if interact_hint != "" else "",
		("\nparcours auto « %s » : étape %d/%d" % [pilot_name, pilot_i + 1, pilot.size()]) if pilot.size() > 0 and not pilot_done else ""]


# ------------------------------------------------------------------------------------------------ pilote
func start_pilot(name: String) -> void:
	pilot = Routes.route(name)
	if name == "captures":
		pilot = []
		for c in Routes.capture_points(world.mode):
			pilot.append({"do": "warp", "to": Vector3(c[1], c[2], c[3])})
			for zi in 3:
				pilot.append({"do": "zoom", "i": zi, "smooth": false})
				pilot.append({"do": "wait", "t": 1.2})
				pilot.append({"do": "snap", "id": "%s_x%s" % [c[0], ["2", "2-5", "3"][zi]]})
		pilot.append({"do": "zoom", "i": 1, "smooth": false})
	if name in ["obs6", "obs6_zooms"]:
		# doc 07 §05 : six points d'observation identiques ; ×2,5 seul (comparaison A/B/C) ou les trois zooms
		pilot = []
		for c in Routes.obs_points():
			pilot.append({"do": "warp", "to": Vector3(c[1], c[2], c[3])})
			for zi in ([1] if name == "obs6" else [0, 1, 2]):
				pilot.append({"do": "zoom", "i": zi, "smooth": false})
				pilot.append({"do": "wait", "t": 1.3})
				pilot.append({"do": "snap", "id": "%s_x%s" % [c[0], ["2", "2-5", "3"][zi]]})
				pilot.append({"do": "analyse", "id": "%s_x%s" % [c[0], ["2", "2-5", "3"][zi]]})
		pilot.append({"do": "zoom", "i": 1, "smooth": false})
	pilot_name = name
	pilot_i = 0
	pilot_t = 0.0
	pilot_best = INF
	pilot_stall = 0.0
	pilot_done = pilot.is_empty()
	_reset_metrics()
	m["route"] = name
	toast("Parcours automatique : " + name)


## Direction d'entrée simulée : 8 directions comme au clavier (approche finale analogique, < 0,8 m).
func _pilot_dir(delta: float) -> Vector2:
	if pilot_i >= pilot.size():
		pilot_done = true
		m["done"] = true
		return Vector2.ZERO
	var s: Dictionary = pilot[pilot_i]
	pilot_t += delta
	var hp := Vector2(hero.x, hero.y)
	match s["do"]:
		"go":
			var g: Vector2 = s["to"]
			var d := g - hp
			var dist := d.length()
			if dist < s.get("tol", 0.3):
				_next_step(true)
				return Vector2.ZERO
			if dist < pilot_best - 0.02:
				pilot_best = dist
				pilot_stall = 0.0
			else:
				pilot_stall += delta
			if pilot_stall > 2.0:
				m["stuck"] = m.get("stuck", []) + ["%s (%.2f m)" % [s.get("id", str(g)), dist]]
				_next_step(false)
				return Vector2.ZERO
			var sd: Vector2 = World25.plan_to_screen_dir(d.normalized())
			if dist > 0.8:
				# clavier : 8 directions seulement ; on alterne les deux touches voisines dans la bonne proportion
				# (diffusion d'erreur, comme un joueur qui corrige sa trajectoire) pour suivre une ligne droite
				var a := sd.angle()
				var a0 := floorf(a / (PI / 4.0)) * (PI / 4.0)
				var f := (a - a0) / (PI / 4.0)
				_dither += f
				var use := a0
				if _dither >= 0.5:
					use = a0 + PI / 4.0
					_dither -= 1.0
				sd = Vector2.from_angle(use)
				sd = Vector2(roundf(sd.x), roundf(sd.y))
			return sd
		"push":
			if pilot_t >= s["t"]:
				var r := {"id": s["id"], "x": hero.x, "y": hero.y, "h": hero.z, "region": hero_region}
				r["ok"] = _probe_ok(s)
				m["probes"] = m.get("probes", []) + [r]
				_next_step(true)
				return Vector2.ZERO
			return s["dir"]
		"wheel":
			_wheel(s["n"])
			_next_step(true)
		"talk":
			interact()
			if not dialogue_open:
				m["talk_failed"] = m.get("talk_failed", []) + [s.get("id", "")]
			_next_step(true)
		"next":
			if pilot_t > 0.35:
				interact()
				_next_step(true)
		"wait":
			if pilot_t >= s["t"]:
				_next_step(true)
		"snap":
			host.capture(s["id"])
			_next_step(true)
		"analyse":
			if host.has_method("analyse"):
				host.analyse(s["id"])
			_next_step(true)
		"zoom":
			cam.set_index(s["i"], s.get("smooth", false))
			_next_step(true)
		"fps":
			Engine.max_fps = s["n"]
			_next_step(true)
		"warp":
			warp_to(s["to"])
			_next_step(true)
		"mark":
			_zone = s["id"]
			_next_step(true)
		_:
			_next_step(true)
	return Vector2.ZERO


func _probe_ok(s: Dictionary) -> bool:
	var exp: Dictionary = s.get("expect", {})
	if exp.has("h"):
		if absf(hero.z - exp["h"]) > 0.05:
			return false
	if exp.has("max_x") and hero.x > exp["max_x"]:
		return false
	if exp.has("min_y") and hero.y < exp["min_y"]:
		return false
	if exp.has("max_y") and hero.y > exp["max_y"]:
		return false
	if exp.has("min_x") and hero.x < exp["min_x"]:
		return false
	if exp.has("max_h") and hero.z > exp["max_h"]:
		return false
	if exp.has("min_h") and hero.z < exp["min_h"]:
		return false
	if exp.has("dry") and hero.x > 21.0 and hero.x < 26.0 and hero_region != "pont":
		return false
	if exp.has("clear"):
		var c: Array = exp["clear"]
		if Vector2(hero.x, hero.y).distance_to(Vector2(c[0], c[1])) < c[2] - 0.02:
			return false
	return true


func _next_step(ok: bool) -> void:
	var s: Dictionary = pilot[pilot_i]
	if s["do"] == "go" and s.has("id"):
		m["reached"] = m.get("reached", []) + [{"id": s["id"], "ok": ok, "t": snappedf(m.get("time", 0.0), 0.01),
			"x": snappedf(hero.x, 0.01), "y": snappedf(hero.y, 0.01), "h": snappedf(hero.z, 0.01)}]
	pilot_i += 1
	pilot_t = 0.0
	pilot_best = INF
	pilot_stall = 0.0


# ------------------------------------------------------------------------------------------------ mesures
func _reset_metrics() -> void:
	m = {"arch": arch, "frames": 0, "time": 0.0, "dt_max": 0.0, "dh_max": 0.0, "h_jumps": 0, "off_model": 0,
		"comp_off": 0, "occluded_frames": 0, "occluded_max_s": 0.0, "cam_jerks": 0, "cam_acc_max": 0.0,
		"view_outside": 0, "levels": [], "regions": [], "blocked_frames": 0, "fps_samples": []}
	_prev_cam = Vector2.INF
	_last_h = INF
	_occ_run = 0.0


func _measure(delta: float, before: Vector3, st: Dictionary) -> void:
	if _skip_measure > 0:
		_skip_measure -= 1
		_prev_cam = Vector2.INF
		return
	m["frames"] += 1
	m["time"] += delta
	m["dt_max"] = maxf(m["dt_max"], delta)
	if m["frames"] % 30 == 0:
		m["fps_samples"].append(Engine.get_frames_per_second())
		m["draw_calls_max"] = maxi(m.get("draw_calls_max", 0), int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		m["primitives_max"] = maxi(m.get("primitives_max", 0), int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
		m["video_mem_mb"] = snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1)
		m["static_mem_mb"] = snappedf(OS.get_static_memory_usage() / 1048576.0, 0.1)
		m["process_ms_max"] = maxf(m.get("process_ms_max", 0.0), snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.01))
		m["physics_ms_max"] = maxf(m.get("physics_ms_max", 0.0), snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.01))
	var dh := absf(hero.z - before.z)
	m["dh_max"] = maxf(m["dh_max"], dh)
	if dh > 0.1:
		m["h_jumps"] += 1
		m["h_jump_at"] = m.get("h_jump_at", []) + ["(%.2f, %.2f) %.2f -> %.2f, étape %d" % [hero.x, hero.y, before.z, hero.z, pilot_i]]
	if st.get("blocked", false):
		m["blocked_frames"] += 1
	# cohérence avec le modèle de monde (pour B : la physique Godot doit rester sur des surfaces praticables)
	if world.surface_at(Vector2(hero.x, hero.y), hero.z).is_empty():
		m["off_model"] += 1
	if world.surface_at(Vector2(companion.x, companion.y), companion.z).is_empty():
		m["comp_off"] += 1
	var lvl: int = world.level_of(hero.z)
	if m["levels"].is_empty() or m["levels"][-1] != lvl:
		m["levels"].append(lvl)
	if m["regions"].is_empty() or m["regions"][-1] != hero_region:
		if hero_region != "":
			m["regions"].append(hero_region)
	var occ: bool = host.hero_occluded()
	if occ:
		if _occ_run == 0.0:
			_occ_from = hero
		m["occluded_frames"] += 1
		_occ_run += delta
		m["occluded_max_s"] = maxf(m["occluded_max_s"], _occ_run)
	else:
		if _occ_run >= 0.5:
			m["occlusions"] = m.get("occlusions", []) + [{"s": snappedf(_occ_run, 0.01), "zone": _zone, "carte": world.path.get_file(),
				"de": [snappedf(_occ_from.x, 0.1), snappedf(_occ_from.y, 0.1)], "a": [snappedf(before.x, 0.1), snappedf(before.y, 0.1)]}]
		_occ_run = 0.0
	_measure_cadrage(delta, before)
	# caméra : à-coups (variation de vitesse > 100 px d'écran/s d'une image à l'autre), accélération maximale
	var c: Vector2 = cam.render_center() * cam.zoom
	if _prev_cam != Vector2.INF and delta > 0.0 and not cam.zooming():
		var v := (c - _prev_cam) / delta
		if (v - _prev_cam_v).length() > 100.0:
			m["cam_jerks"] += 1
			m["cam_jerk_at"] = m.get("cam_jerk_at", []) + ["%s (%.1f, %.1f) ×%s, tronçon « %s », étape %d" % [world.path.get_file(), hero.x, hero.y, str(cam.zoom), _zone, pilot_i]]
		m["cam_acc_max"] = maxf(m["cam_acc_max"], (v - _prev_cam_v).length() / delta)
		_prev_cam_v = v
	elif cam.zooming():
		_prev_cam_v = Vector2.ZERO
	_prev_cam = c
	if not world.view_inside_decor(cam.view_rect()):
		m["view_outside"] += 1
		if m["view_outside"] <= 3 or m["view_outside"] % 50 == 0:
			m["view_outside_at"] = m.get("view_outside_at", []) + ["%s (%.1f, %.1f) ×%.2f" % [world.path.get_file(), hero.x, hero.y, cam.zoom]]


## Validation caméra — CONFORT DE CADRAGE, mesuré à chaque image de marche :
##  • place du héros dans la hauteur de l'écran (0 = haut, 1 = bas) ;
##  • anticipation : distance d'écran entre le héros et le bord du cadre DANS LE SENS DE LA MARCHE (px d'écran) et sa
##    traduction en secondes de marche (temps avant qu'un obstacle entrant dans le cadre n'atteigne le héros) ;
##  • par direction d'écran (8 secteurs) et par tronçon du parcours.
const DIR8 := ["droite", "bas-droite", "bas", "bas-gauche", "gauche", "haut-gauche", "haut", "haut-droite"]


func _measure_cadrage(delta: float, before: Vector3) -> void:
	var view: Rect2 = cam.view_rect()
	var hs: Vector2 = World25.screen(hero)
	var frac: float = (hs.y - view.position.y) / view.size.y
	var c: Dictionary = m.get("cadrage", {})
	if c.is_empty():
		c = {"heros_y_min": 1.0, "heros_y_max": 0.0, "heros_y_somme": 0.0, "images": 0, "images_marche": 0,
			"heros_pres_du_bord": 0, "par_direction": {}, "par_troncon": {}}
		m["cadrage"] = c
	c["images"] += 1
	c["heros_y_min"] = minf(c["heros_y_min"], frac)
	c["heros_y_max"] = maxf(c["heros_y_max"], frac)
	c["heros_y_somme"] += frac
	var fx: float = (hs.x - view.position.x) / view.size.x
	if frac < 0.15 or frac > 0.88 or fx < 0.1 or fx > 0.9:
		c["heros_pres_du_bord"] += 1
	var mv: Vector2 = hs - World25.screen(before)
	if delta <= 0.0 or mv.length() / delta < 8.0 or cam.zooming():
		return
	var d: Vector2 = mv.normalized()
	var t: float = INF
	if d.x > 0.001:
		t = minf(t, (view.end.x - hs.x) / d.x)
	elif d.x < -0.001:
		t = minf(t, (view.position.x - hs.x) / d.x)
	if d.y > 0.001:
		t = minf(t, (view.end.y - hs.y) / d.y)
	elif d.y < -0.001:
		t = minf(t, (view.position.y - hs.y) / d.y)
	var px: float = t * cam.zoom
	var sec: float = t / (mv.length() / delta)
	c["images_marche"] += 1
	var k: String = DIR8[posmod(int(roundf(d.angle() / (PI / 4.0))), 8)]
	for pair in [[c["par_direction"], k], [c["par_troncon"], _zone]]:
		var e: Dictionary = pair[0].get(pair[1], {"n": 0, "px": 0.0, "px_min": INF, "s": 0.0, "s_min": INF})
		e["n"] += 1
		e["px"] += px
		e["px_min"] = minf(e["px_min"], px)
		e["s"] += sec
		e["s_min"] = minf(e["s_min"], sec)
		pair[0][pair[1]] = e


func summary() -> Dictionary:
	var out := m.duplicate(true)
	if out.has("cadrage"):
		var c: Dictionary = out["cadrage"]
		c["heros_y_moyen_pct"] = snappedf(100.0 * c["heros_y_somme"] / maxi(1, c["images"]), 0.1)
		c["heros_y_min_pct"] = snappedf(100.0 * c["heros_y_min"], 0.1)
		c["heros_y_max_pct"] = snappedf(100.0 * c["heros_y_max"], 0.1)
		for k0 in ["heros_y_somme", "heros_y_min", "heros_y_max"]:
			c.erase(k0)
		for grp in ["par_direction", "par_troncon"]:
			for k in c[grp]:
				var e: Dictionary = c[grp][k]
				c[grp][k] = {"images": e["n"], "anticipation_px_moy": snappedf(e["px"] / e["n"], 1), "anticipation_px_min": snappedf(e["px_min"], 1),
					"anticipation_s_moy": snappedf(e["s"] / e["n"], 0.01), "anticipation_s_min": snappedf(e["s_min"], 0.01)}
	var fs: Array = out["fps_samples"]
	if fs.size() > 0:
		var s := 0.0
		for f in fs:
			s += f
		out["fps_avg"] = snappedf(s / fs.size(), 0.1)
		out["fps_min"] = fs.min()
	out.erase("fps_samples")
	out["time"] = snappedf(out["time"], 0.01)
	out["cam_acc_max"] = snappedf(out["cam_acc_max"], 1)
	out["dh_max"] = snappedf(out["dh_max"], 0.001)
	out["wheel_ignored_in_ui"] = cam.wheel_ignored
	out["zoom_final"] = cam.target_zoom()
	out["occluded_max_s"] = snappedf(out["occluded_max_s"], 0.01)
	return out
