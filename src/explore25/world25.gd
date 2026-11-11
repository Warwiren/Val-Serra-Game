extends RefCounted
## P3 — MODÈLE DE MONDE 2.5D commun aux deux démonstrations (A : Node2D/Camera2D, B : Node3D/Camera3D orthographique).
## Repère unique (doc 06 §01) : x vers la droite et y vers le bas du PLAN (mètres), h = altitude (mètres), distinct
## de la coordonnée écran. Les deux rendus lisent ces mêmes données et la même projection orthographique :
## plongée 35°, azimut 20°, 20 px natifs par mètre (métrique historique du projet).
##   écran.x = (x·cos20 + y·sin20) · 20
##   écran.y = ((−x·sin20 + y·cos20) · sin35 − h · cos35) · 20
## En 3D (Godot) : X = x, Y = h, Z = y ; la caméra regarde selon −B avec B = (−sin20·cos35, sin35, cos20·cos35).
## Sources : gabarits_blockout_v01.json (doc 06, inchangé) + ajustements_p3_v01.json (compléments tracés).

const PPM := 20.0
const PITCH := 0.6108652381980153        # 35° (référence ; la plongée courante est `pitch`, réglable par variante P3-07)
static var pitch := PITCH
const YAW := 0.3490658503988659          # 20°
const EPS := 0.002
const SPEC := "res://data/explore25/gabarits_blockout_v01.json"
const ADJ := "res://data/explore25/ajustements_p3_v01.json"
## Sous-ensemble du micro-test comparatif A/B (doc 05 §06, doc 06 §08) : deux surfaces, un escalier, un occultant.
const MICRO_IDS := ["terrain_bas", "terrasse_haute", "escalier", "arbre_test"]

var path := ""
var mode := "temoin"                     # "temoin" | "micro" | "instance"
var spec: Dictionary = {}
var adj: Dictionary = {}
var step_h := 0.25
var actor_r := 0.28
var speed := 3.6
var follow_gap := 1.0
var stair_assist := 0.3
var extent := Rect2()                    # aire de la carte (plan, m)
var decor := Rect2()                     # sol de décor visible (non praticable)
var regions: Array = []                  # {id, rect, holes: [Rect2], h, ramp: {} | {y_bottom, y_top, h_bottom, h_top}}
var solids: Array = []                   # {id, kind: "circle" | "rect", c, r, rect, h0, h1}
var elements: Array = []                 # descripteurs de rendu (lus par les deux démonstrations)
var triggers: Array = []                 # sorties d'instance {id, rect, to, arrive}
var pois: Array = []                     # points d'interaction {id, p: Vector3, r, range, text, lines}
var npc: Dictionary = {}
var checkpoints := {}                    # id -> Vector3(x, y, h)
var spawn := Vector3()
var max_h := 0.0
var notes: Array = []                    # ajustements appliqués, pour le rapport et l'overlay
var view_extra: Array = []               # P3-07 : points (x, y, h) de paysage que le cadre a le droit de montrer
var rails: Array = []                     # garde-corps (posés après les régions : ils ont besoin de savoir où est le tablier)


# ------------------------------------------------------------------------------------------------ projection
static func screen(p: Vector3) -> Vector2:
	var u := p.x * cos(YAW) + p.y * sin(YAW)
	var d := -p.x * sin(YAW) + p.y * cos(YAW)
	return Vector2(u, d * sin(pitch) - p.z * cos(pitch)) * PPM


static func depth(x: float, y: float) -> float:
	return -x * sin(YAW) + y * cos(YAW)


## Direction horizontale (plan) vers la caméra.
static func toward_cam() -> Vector2:
	return Vector2(-sin(YAW), cos(YAW))


## Direction d'entrée À L'ÉCRAN (x droite, y bas, clavier 8 directions) -> direction au sol dans le plan.
## « Haut » fait monter le personnage verticalement à l'écran, quel que soit l'azimut.
static func input_to_plan(v: Vector2) -> Vector2:
	var r := Vector2(cos(YAW), sin(YAW))
	var f := Vector2(sin(YAW), -cos(YAW))
	var w := r * v.x - f * v.y
	return w.normalized() if w.length() > 0.0001 else Vector2.ZERO


## Direction au sol (plan) -> direction à l'écran (pour l'orientation des sprites, le pilote).
static func plan_to_screen_dir(w: Vector2) -> Vector2:
	var s := screen(Vector3(w.x, w.y, 0)) - screen(Vector3.ZERO)
	return s.normalized() if s.length() > 0.0001 else Vector2.ZERO


static func g3(p: Vector3) -> Vector3:
	return Vector3(p.x, p.z, p.y)


static func cam_right() -> Vector3:
	return Vector3(cos(YAW), 0, sin(YAW))


static func cam_back() -> Vector3:
	return Vector3(-sin(YAW) * cos(pitch), sin(pitch), cos(YAW) * cos(pitch))


static func cam_up() -> Vector3:
	return cam_back().cross(cam_right())


# ------------------------------------------------------------------------------------------------ chargement
static func load_world(file := SPEC, m := "temoin") -> RefCounted:
	var w = load("res://src/explore25/world25.gd").new()
	w._load(file, m)
	return w


func _load(file: String, m: String) -> void:
	path = file
	mode = m
	spec = JSON.parse_string(FileAccess.open(file, FileAccess.READ).get_as_text())
	if spec.has("ajustements"):
		adj = spec["ajustements"]
		mode = "instance"
	else:
		adj = JSON.parse_string(FileAccess.open(ADJ, FileAccess.READ).get_as_text())
	var par: Dictionary = adj.get("parametres", {})
	step_h = par.get("pas_franchissable_m", step_h)
	actor_r = par.get("rayon_personnage_m", actor_r)
	speed = par.get("vitesse_m_s", speed)
	follow_gap = par.get("ecart_compagnon_m", follow_gap)
	stair_assist = par.get("assistance_escalier", stair_assist)
	var ex: Array = spec["world"]["extent_m"]
	extent = Rect2(0, 0, ex[0], ex[1])
	var dm: Array = adj.get("decor_marge", [-14, -14, ex[0] + 14, ex[1] + 14])
	decor = Rect2(dm[0], dm[1], dm[2] - dm[0], dm[3] - dm[1])
	for c in spec.get("checkpoints", []):
		checkpoints[c["id"]] = Vector3(c["xy_m"][0], c["xy_m"][1], c["height_m"])
	var assets: Array = []
	for a in spec["assets"]:
		if mode == "micro" and not MICRO_IDS.has(a["id"]):
			continue
		assets.append(a)
	var stair_rects: Array = []
	for a in assets:
		if a["category"] == "transition":
			var b: Array = a["bounds_xy_m"]
			stair_rects.append(Rect2(b[0], b[1], b[2] - b[0], b[3] - b[1]))
	var water_x := []
	for a in assets:
		_asset(a, stair_rects)
		if a["category"] == "water":
			water_x = [a["bounds_xy_m"][0], a["bounds_xy_m"][2]]
	for r in adj.get("regions_ajoutees", []):
		if _keep(r):
			var q: Array = r["rect"]
			var reg := _region(r["id"], Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1]), r["h"])
			reg["holes"] = _holes_for(reg["rect"], reg["h"], stair_rects)
			regions.append(reg)
			elements.append({"type": "floor", "id": r["id"], "rect": reg["rect"], "h": r["h"], "role": "sol0", "holes": reg["holes"]})
			notes.append("région ajoutée : " + r["id"])
	for reg in regions:
		max_h = maxf(max_h, maxf(reg["h"], reg["ramp"].get("h_top", reg["h"])))
	_cover_camera()
	_decor_ground(water_x)
	for e in rails:
		_border_box(e, true)
		elements.append(e)
	var hts: Dictionary = adj.get("hauteurs", {})
	for b in adj.get("bordures", []):
		if not _keep(b):
			continue
		var s: Array = b["seg"]
		var hh: float = b.get("haut", hts.get({"haie": "haie_m", "muret": "muret_terrasse_m", "mur": "mur_fond_terrasse_m"}.get(b["type"], "haie_m"), 0.7))
		var e := {"type": "border", "id": b["id"], "a": Vector2(s[0], s[1]), "b": Vector2(s[2], s[3]), "h": b["h"], "height": hh, "role": b["type"]}
		_border_box(e, b["type"] != "haie" and not b.get("exterieur", false), b.get("cote_h", b["h"]))
		elements.append(e)
	for o in adj.get("obstacles", []):
		if not _keep(o):
			continue
		var q: Array = o["rect"]
		var r2 := Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1])
		solids.append({"id": o["id"], "kind": "rect", "rect": r2, "h0": o["h"], "h1": o["h"] + o["haut"]})
		elements.append({"type": "block", "id": o["id"], "rect": r2, "h0": o["h"], "h1": o["h"] + o["haut"], "role": "caisse"})
	if adj.has("pnj") and _has_region_at(Vector2(adj["pnj"]["xy"][0], adj["pnj"]["xy"][1])):
		var n: Dictionary = adj["pnj"]
		npc = {"id": n["id"], "p": Vector3(n["xy"][0], n["xy"][1], n["h"]), "r": n["r"], "range": n["portee_m"],
			"lines": n["repliques"], "sprite": n.get("sprite", "pnj")}
		solids.append({"id": n["id"], "kind": "circle", "c": Vector2(n["xy"][0], n["xy"][1]), "r": n["r"], "h0": n["h"], "h1": n["h"] + 1.8})
	for p in adj.get("poi", []):
		if not _keep(p):
			continue
		var pp := Vector3(p["xy"][0], p["xy"][1], p["h"])
		pois.append({"id": p["id"], "p": pp, "r": p["r"], "range": p["portee_m"], "text": p["texte"]})
		solids.append({"id": p["id"], "kind": "circle", "c": Vector2(pp.x, pp.y), "r": p["r"], "h0": pp.z, "h1": pp.z + 1.0})
		elements.append({"type": "post", "id": p["id"], "c": Vector2(pp.x, pp.y), "r": p["r"], "h": pp.z, "height": 1.0, "role": "borne"})
	var en: Dictionary = adj.get("entree", {})
	if en.has("xy"):
		spawn = Vector3(en["xy"][0], en["xy"][1], en["h"])
		if en.has("porte"):
			elements.append(_gate("entree", en["porte"], en["h"]))
	for s in adj.get("sorties", []):
		if not _keep(s):
			continue
		var q: Array = s["rect"]
		var arr: Array = s.get("arrivee", [])
		triggers.append({"id": s["id"], "rect": Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1]), "to": s["vers"],
			"arrive": Vector3(arr[0], arr[1], arr[2]) if arr.size() == 3 else Vector3.INF})
		elements.append(_gate(s["id"], s["porte"], 0.0))
	for reg in regions:
		max_h = maxf(max_h, maxf(reg["h"], reg["ramp"].get("h_top", reg["h"])))
	if mode == "micro":
		notes.append("micro-test : " + ", ".join(MICRO_IDS) + " (+ ajustements communs)")


const THICK := {"haie": 0.5, "muret": 0.3, "mur": 0.4, "garde_corps": 0.12}


## Volume d'une bordure (segment axial) : côté praticable (muret, mur, garde-corps) ou extérieur (haie). Le volume
## devient un SOLIDE du modèle : la collision logique (A) et physique (B) coïncident avec ce qu'on voit.
func _border_box(e: Dictionary, inward: bool, side_h := INF) -> void:
	if side_h == INF:
		side_h = e["h"]
	var a: Vector2 = e["a"]
	var b: Vector2 = e["b"]
	var t: float = THICK.get(e["role"], 0.3)
	var n := (b - a).normalized().orthogonal()
	var mid := (a + b) / 2.0
	var plus := not surface_at(mid + n * 0.2, side_h).is_empty()
	var minus := not surface_at(mid - n * 0.2, side_h).is_empty()
	var side := 0.0
	if plus != minus:
		side = (1.0 if plus else -1.0) * (1.0 if inward else -1.0)
	var c0 := a + n * side * t * 0.5
	var c1 := b + n * side * t * 0.5
	var r := Rect2(c0, Vector2.ZERO).expand(c1).grow_individual(
		t * 0.5 if absf(n.x) > 0.5 else 0.0, t * 0.5 if absf(n.y) > 0.5 else 0.0,
		t * 0.5 if absf(n.x) > 0.5 else 0.0, t * 0.5 if absf(n.y) > 0.5 else 0.0)
	e["rect"] = r
	solids.append({"id": e["id"], "kind": "rect", "rect": r, "h0": e["h"], "h1": e["h"] + e["height"]})


func _keep(d: Dictionary) -> bool:
	if mode == "micro" and d.get("temoin_seul", false):
		return false
	if mode != "micro" and d.get("micro_seul", false):
		return false
	return true


func _region(id: String, r: Rect2, h: float) -> Dictionary:
	return {"id": id, "rect": r, "holes": [], "h": h, "ramp": {}}


func _holes_for(r: Rect2, h: float, stair_rects: Array) -> Array:
	var out: Array = []
	if absf(h) > 0.001:
		return out
	for s in stair_rects:
		if r.intersects(s):
			out.append(r.intersection(s))
	return out


func _has_region_at(p: Vector2) -> bool:
	for reg in regions:
		if _in_region(reg, p):
			return true
	return false


func _gate(id: String, seg: Array, h: float) -> Dictionary:
	return {"type": "gate", "id": id, "a": Vector2(seg[0], seg[1]), "b": Vector2(seg[2], seg[3]), "h": h, "height": 2.6, "role": "porte"}


func _asset(a: Dictionary, stair_rects: Array) -> void:
	var hts: Dictionary = adj.get("hauteurs", {})
	match a["category"]:
		"surface":
			var poly: Array = a["polygon_xy_m"]
			var r := _rect_of(poly, a["id"])
			var h: float = a["height_m"]
			var reg := _region(a["id"], r, h)
			reg["holes"] = _holes_for(r, h, stair_rects)
			if not reg["holes"].is_empty():
				notes.append("%s : emprise de l'escalier retirée du sol praticable" % a["id"])
			regions.append(reg)
			if h > 0.001:
				elements.append({"type": "block", "id": a["id"], "rect": r, "h0": 0.0, "h1": h, "role": "terrasse"})
			else:
				elements.append({"type": "floor", "id": a["id"], "rect": r, "h": h, "role": "sol0", "holes": reg["holes"]})
		"transition":
			var b: Array = a["bounds_xy_m"]
			var r := Rect2(b[0], b[1], b[2] - b[0], b[3] - b[1])
			var st: Dictionary = adj.get("escalier", {})
			var lb: float = st.get("palier_bas_m", 0.22)
			var lt: float = st.get("palier_haut_m", 0.22)
			var reg := _region(a["id"], r, a["bottom_h_m"])
			reg["ramp"] = {"y_bottom": r.end.y - lb, "y_top": r.position.y + lt, "h_bottom": a["bottom_h_m"], "h_top": a["top_h_m"]}
			regions.append(reg)
			# limons (côtés de la volée, 12 cm) : solides, pour que le bord visible de l'escalier arrête aussi le héros
			for lx in [r.position.x, r.end.x - 0.12]:
				solids.append({"id": a["id"] + "_limon", "kind": "rect", "rect": Rect2(lx, r.position.y + lt, 0.12, r.size.y - lt - lb),
					"h0": a["bottom_h_m"], "h1": a["top_h_m"] + 0.2})
			elements.append({"type": "stairs", "id": a["id"], "rect": r, "h0": a["bottom_h_m"], "h1": a["top_h_m"],
				"risers": a["risers"], "tread": a["tread_depth_m"], "land_bottom": lb, "land_top": lt, "role": "escalier"})
		"water":
			var b: Array = a["bounds_xy_m"]
			var ry: Array = adj.get("riviere_visuelle_y", [b[1], b[3]])
			elements.append({"type": "water", "id": a["id"], "rect": Rect2(b[0], ry[0], b[2] - b[0], ry[1] - ry[0]), "h": a["water_level_h_m"], "role": "eau"})
			notes.append("rivière prolongée visuellement (décor) de y = %s à %s" % [ry[0], ry[1]])
		"bank":
			var b: Array = a["bounds_xy_m"]
			var ry: Array = adj.get("riviere_visuelle_y", [b[1], b[3]])
			# berge : pente du sol (h de départ) vers l'eau ; le côté « eau » est celui qui touche la rivière
			var water_side := 1.0 if a["id"].ends_with("ouest") else -1.0
			elements.append({"type": "bank", "id": a["id"], "rect": Rect2(b[0], ry[0], b[2] - b[0], ry[1] - ry[0]),
				"h_top": a["height_from_h_m"], "h_bottom": a["water_level_h_m"], "water_side": water_side, "role": "berge"})
		"crossing":
			var b: Array = a["bounds_xy_m"]
			var r := Rect2(b[0], b[1], b[2] - b[0], b[3] - b[1])
			regions.append(_region(a["id"], r, a["deck_h_m"]))
			elements.append({"type": "deck", "id": a["id"], "rect": r, "h": a["deck_h_m"], "role": "pont"})
			var gx: Array = adj.get("garde_corps_pont_x", [b[0], b[2]])
			var rh: float = hts.get("garde_corps_pont_m", 0.9)
			for yy in [r.position.y, r.end.y]:
				rails.append({"type": "rail", "id": a["id"] + ("_arriere" if yy == r.position.y else "_avant"),
					"a": Vector2(gx[0], yy), "b": Vector2(gx[1], yy), "h": a["deck_h_m"], "height": rh, "role": "garde_corps"})
		"occluder":
			var c := Vector2(a["foot_center_xy_m"][0], a["foot_center_xy_m"][1])
			var rr: float = a["root_collision_radius_m"]
			solids.append({"id": a["id"], "kind": "circle", "c": c, "r": rr, "h0": 0.0, "h1": hts.get("arbre_tronc_m", 2.4)})
			elements.append({"type": "tree", "id": a["id"], "c": c, "r": rr, "h": 0.0, "trunk_h": hts.get("arbre_tronc_m", 2.4),
				"foliage_r": a["foliage_overhang_m"], "foliage_h": hts.get("arbre_feuillage_centre_m", 3.7), "role": "arbre"})
		"building-placeholder":
			var f: Array = a["footprint_xy_m"]
			var r := Rect2(f[0], f[1], f[2] - f[0], f[3] - f[1])
			var h0: float = a["height_level_m"]
			var wh: float = hts.get("maison_murs_m", 2.6)
			solids.append({"id": a["id"], "kind": "rect", "rect": r, "h0": h0, "h1": h0 + wh})
			elements.append({"type": "house", "id": a["id"], "rect": r, "h0": h0, "h1": h0 + wh, "roof": hts.get("maison_toit_m", 1.4), "role": "maison"})


func _rect_of(poly: Array, id: String) -> Rect2:
	var r := Rect2(Vector2(poly[0][0], poly[0][1]), Vector2.ZERO)
	for q in poly:
		r = r.expand(Vector2(q[0], q[1]))
	assert(poly.size() == 4, "%s : seuls les polygones rectangulaires sont gérés par le prototype" % id)
	return r


## Sol de décor non praticable autour de l'aire de jeu, interrompu par la rivière (sinon il la recouvrirait).
## Le décor doit couvrir toutes les vues permises par les limites de caméra (y compris les coins du rectangle
## écran, qui tombent loin de la carte à cause de l'azimut) : on l'agrandit au besoin (+2 m).
func _cover_camera() -> void:
	var b := camera_bounds()
	# petite instance : la vue la plus large (×2 à 1280 × 720 = 640 × 360 px natifs) déborde des limites ; elle est
	# alors centrée, il faut donc couvrir cette vue entière
	var vmax := Vector2(640, 360)
	b = b.merge(Rect2(b.get_center() - vmax / 2.0, vmax))
	var r := decor
	for c in [b.position, Vector2(b.end.x, b.position.y), Vector2(b.position.x, b.end.y), b.end]:
		r = r.expand(screen_to_plan(c, 0.0))
	r = r.grow(2.0)
	if r != decor:
		notes.append("sol de décor agrandi de %s à %s (vues aux coins)" % [str(decor), str(r)])
		decor = r
	for e in elements:
		if e["type"] in ["water", "bank"]:
			var er: Rect2 = e["rect"]
			e["rect"] = Rect2(er.position.x, decor.position.y, er.size.x, decor.size.y)


func _decor_ground(water_x: Array) -> void:
	var parts: Array = []
	if water_x.size() == 2:
		var x0: float = water_x[0] - 1.0         # berges de 1 m de chaque côté (doc 06 §05)
		var x1: float = water_x[1] + 1.0
		parts.append(Rect2(decor.position, Vector2(x0 - decor.position.x, decor.size.y)))
		parts.append(Rect2(Vector2(x1, decor.position.y), Vector2(decor.end.x - x1, decor.size.y)))
	else:
		parts.append(decor)
	for i in parts.size():
		elements.push_front({"type": "floor", "id": "decor_%d" % i, "rect": parts[i], "h": 0.0, "role": "decor", "holes": []})


# ------------------------------------------------------------------------------------------------ navigation
func _in_region(reg: Dictionary, p: Vector2) -> bool:
	if not (reg["rect"] as Rect2).grow(EPS).has_point(p):
		return false
	for hole in reg["holes"]:
		if (hole as Rect2).grow(-EPS).has_point(p):
			return false
	return true


func region_h(reg: Dictionary, p: Vector2) -> float:
	var rp: Dictionary = reg["ramp"]
	if rp.is_empty():
		return reg["h"]
	var t := clampf((rp["y_bottom"] - p.y) / (rp["y_bottom"] - rp["y_top"]), 0.0, 1.0)
	return lerpf(rp["h_bottom"], rp["h_top"], t)


## Surface praticable sous p, à une altitude proche de h_ref (un même point du plan peut porter deux niveaux).
func surface_at(p: Vector2, h_ref: float) -> Dictionary:
	var best := {}
	var bd := INF
	for reg in regions:
		if not _in_region(reg, p):
			continue
		var h := region_h(reg, p)
		var dh := absf(h - h_ref)
		if dh <= step_h and dh < bd:
			bd = dh
			best = {"h": h, "id": reg["id"], "ramp": not reg["ramp"].is_empty()}
	return best


## Toutes les surfaces sous p (quel que soit le niveau) — overlay de débogage, tests.
func surfaces_under(p: Vector2) -> Array:
	var out: Array = []
	for reg in regions:
		if _in_region(reg, p):
			out.append({"id": reg["id"], "h": region_h(reg, p)})
	return out


func level_of(h: float) -> int:
	return 1 if h > 0.6 else 0


## Position tenable : le disque du personnage repose entièrement sur des surfaces continues et ne touche aucun solide.
func stand(p: Vector2, h_ref: float) -> Dictionary:
	var s := surface_at(p, h_ref)
	if s.is_empty():
		return {}
	for i in 8:
		var o := Vector2.from_angle(TAU * i / 8.0) * actor_r
		var s2 := surface_at(p + o, s["h"])
		if s2.is_empty():
			return {}
	for so in solids:
		if s["h"] < so["h0"] - step_h or s["h"] > so["h1"]:
			continue
		if so["kind"] == "circle":
			if p.distance_to(so["c"]) < so["r"] + actor_r:
				return {}
		else:
			# distance au rectangle (coins arrondis : on glisse autour d'un angle au lieu de s'y accrocher)
			var rr: Rect2 = so["rect"]
			var q := Vector2(clampf(p.x, rr.position.x, rr.end.x), clampf(p.y, rr.position.y, rr.end.y))
			if p.distance_to(q) < actor_r:
				return {}
	return s


## Déplacement avec glissement le long des obstacles (sous-pas de 5 cm). Renvoie {p, h, id, blocked}.
func move(p: Vector2, h: float, dv: Vector2) -> Dictionary:
	var n := maxi(1, int(ceil(dv.length() / 0.05)))
	var step := dv / n
	var cur := p
	var ch := h
	var cid := ""
	var blocked := false
	for i in n:
		# direction voulue, puis ses composantes, puis des directions voisines (±35°, ±70°) : glissement le long
		# des obstacles ronds et des angles
		var tries := [step, Vector2(step.x, 0), Vector2(0, step.y),
			step.rotated(0.61) * 0.82, step.rotated(-0.61) * 0.82, step.rotated(1.22) * 0.34, step.rotated(-1.22) * 0.34]
		var moved := false
		for t in tries:
			if t.length() < 0.00001:
				continue
			var s := stand(cur + t, ch)
			if not s.is_empty():
				cur += t
				ch = s["h"]
				cid = s["id"]
				moved = true
				if t != step:
					blocked = true
				break
		if not moved:
			blocked = true
			break
	if cid == "":
		var s0 := surface_at(cur, ch)
		cid = s0.get("id", "")
	return {"p": cur, "h": ch, "id": cid, "blocked": blocked}


## Assistance d'escalier (choix du prototype) : sur une rampe orientée selon y, la composante latérale est réduite
## pour que « haut » à l'écran (incliné de 20° par l'azimut) ne pousse pas le héros contre le limon.
func assist(dir: Vector2, on_ramp: bool) -> Dictionary:
	if not on_ramp or absf(dir.y) < 0.55:
		return {"dir": dir, "on": false}
	var l := dir.length()
	var d2 := Vector2(dir.x * stair_assist, dir.y).normalized() * l
	return {"dir": d2, "on": true}


func trigger_at(p: Vector2) -> Dictionary:
	for t in triggers:
		if (t["rect"] as Rect2).has_point(p):
			return t
	return {}


## Rectangle écran (px natifs) que la vue ne doit pas quitter : l'aire de la carte projetée (sol et niveau haut),
## élargie d'une petite marge ; le décor (decor_marge) la recouvre entièrement.
func camera_bounds(margin_px := 24.0) -> Rect2:
	var r := Rect2(screen(Vector3(extent.position.x, extent.position.y, 0)), Vector2.ZERO)
	for x in [extent.position.x, extent.end.x]:
		for y in [extent.position.y, extent.end.y]:
			for hh in [0.0, max_h + 1.8]:
				r = r.expand(screen(Vector3(x, y, hh)))
	for p in view_extra:
		r = r.expand(screen(p))
	return r.grow(margin_px)


## P3-07 : élargit les limites de caméra vers un paysage non jouable (sans toucher au praticable) et agrandit le décor
## en conséquence.
func extend_view(pts: Array) -> void:
	view_extra = pts
	_cover_camera()


## Vérifie qu'un rectangle écran (px natifs) ne montre que du décor : ses 4 coins, ramenés au sol h = 0, sont
## dans le sol de décor (test « pas de vide aux limites »).
func view_inside_decor(view: Rect2) -> bool:
	for c in [view.position, Vector2(view.end.x, view.position.y), Vector2(view.position.x, view.end.y), view.end]:
		var q := screen_to_plan(c, 0.0)
		if not decor.grow(0.01).has_point(q):
			return false
	return true


## Inverse de la projection pour une altitude donnée.
static func screen_to_plan(s: Vector2, h: float) -> Vector2:
	var u := s.x / PPM
	var d := (s.y / PPM + h * cos(pitch)) / sin(pitch)
	return Vector2(u * cos(YAW) - d * sin(YAW), u * sin(YAW) + d * cos(YAW))
