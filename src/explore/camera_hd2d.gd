extends Camera2D
## P1 — CAMÉRA D'EXPLORATION HD-2D à configurations comparables (A / B / C), changeables EN JEU sans rechargement.
## La projection du décor ne change pas (plongée 35°, rotation 20°, rendue dans les images) : seuls le cadrage,
## l'échelle et le suivi varient. Réutilisable pour toute carte : follow() à chaque image + set_bounds().
##   A — actuelle (référence) : ×2, centre sur les pieds du héros, lissage natif de Camera2D (vitesse 4).
##   B — intermédiaire        : ×2,5, zone morte, lissage critique (pas de dépassement), limites lissées.
##   C — rapprochée           : ×3, zone morte réduite, cadrage sur le buste, légère anticipation dans le sens
##                              de la marche (on voit ce qui arrive), lissage critique.
## Par défaut : A (inchangé tant que le choix n'est pas validé).

const PRESETS := {
	"A": {"label": "A — actuelle (×2)", "zoom": 2.0, "smooth": 4.0, "dead": Vector2.ZERO, "aim": Vector2.ZERO,
		"lead": 0.0, "native": true},
	"B": {"label": "B — intermédiaire (×2,5)", "zoom": 2.5, "smooth": 5.0, "dead": Vector2(18, 10),
		"aim": Vector2(0, -8), "lead": 0.0, "native": false},
	"C": {"label": "C — rapprochée (×3)", "zoom": 3.0, "smooth": 6.0, "dead": Vector2(8, 5),
		"aim": Vector2(0, -14), "lead": 22.0, "native": false},
}
const ORDER := ["A", "B", "C"]

var preset := "A"
var bounds := Rect2()
var _focus := Vector2.ZERO          # point suivi (zone morte appliquée), px natifs
var _lead := Vector2.ZERO           # anticipation lissée
var _center := Vector2.ZERO         # centre caméra lissé (B, C)
var _zoom_tw: Tween


func _init() -> void:
	name = "CameraHD2D"


func set_bounds(r: Rect2) -> void:
	bounds = r
	limit_left = int(r.position.x)
	limit_top = int(r.position.y)
	limit_right = int(r.end.x)
	limit_bottom = int(r.end.y)


func cfg() -> Dictionary:
	return PRESETS[preset]


## Change de configuration sans recharger : le cadre repart de la position actuelle (pas de saut).
func apply(p: String, target := Vector2.INF) -> void:
	if not PRESETS.has(p):
		return
	var from := get_screen_center_position() if is_inside_tree() else position
	preset = p
	var c := cfg()
	if _zoom_tw != null:
		_zoom_tw.kill()
	if is_inside_tree() and target != Vector2.INF:
		_zoom_tw = create_tween()                # transition douce de l'échelle (0,35 s), le suivi continue
		_zoom_tw.tween_property(self, "zoom", Vector2.ONE * float(c["zoom"]), 0.35).set_trans(Tween.TRANS_SINE)
	else:
		zoom = Vector2.ONE * float(c["zoom"])
	position_smoothing_enabled = c["native"]
	position_smoothing_speed = c["smooth"]
	limit_smoothed = not c["native"]
	if target != Vector2.INF:
		_focus = target
		_center = from if is_inside_tree() else target + Vector2(c["aim"])
	_lead = Vector2.ZERO
	if not c["native"]:
		position = _clamp_center(_center)


## Recentrage immédiat (apparition, retour de combat) : aucune glissade depuis l'origine.
func snap_to(target: Vector2) -> void:
	_focus = target
	_lead = Vector2.ZERO
	_center = _clamp_center(target + Vector2(cfg()["aim"]))
	position = target.round() if cfg()["native"] else _center
	if is_inside_tree():
		reset_smoothing()


## À appeler à chaque image avec la position du héros (pieds) et sa direction de marche (normalisée ou nulle).
func follow(target: Vector2, move_dir: Vector2, delta: float) -> void:
	var c := cfg()
	if c["native"]:
		position = target.round()               # A : exactement le comportement d'origine
		return
	# zone morte (rectangle autour du point suivi) : le cadre ne bouge que si le héros en sort
	var dead: Vector2 = c["dead"]
	var off := target - _focus
	if absf(off.x) > dead.x:
		_focus.x = target.x - signf(off.x) * dead.x
	if absf(off.y) > dead.y:
		_focus.y = target.y - signf(off.y) * dead.y
	# anticipation : décalage vers la direction de marche, lissé lentement (pas d'à-coup aux changements de sens)
	# (à l'arrêt, l'anticipation est CONSERVÉE : le cadre ne revient pas en glissant quand on lâche les touches)
	var want_lead := Vector2(move_dir.x, move_dir.y * 0.6) * float(c["lead"]) if move_dir != Vector2.ZERO else _lead
	_lead = _lead.lerp(want_lead, 1.0 - exp(-2.5 * delta))
	var goal := _clamp_center(_focus + Vector2(c["aim"]) + _lead)
	# lissage exponentiel indépendant de la cadence (critique : jamais de dépassement ni d'oscillation)
	_center = _center.lerp(goal, 1.0 - exp(-float(c["smooth"]) * delta))
	position = _center


## Centre maximal autorisé pour que la vue reste dans la carte (évite que la cible « tire » contre la limite).
func _clamp_center(p: Vector2) -> Vector2:
	if bounds.size == Vector2.ZERO:
		return p
	var half := view_size() / 2.0
	var lo := bounds.position + half
	var hi := bounds.end - half
	return Vector2(clampf(p.x, lo.x, maxf(lo.x, hi.x)) if hi.x >= lo.x else bounds.get_center().x,
		clampf(p.y, lo.y, maxf(lo.y, hi.y)) if hi.y >= lo.y else bounds.get_center().y)


## Surface visible du monde (px natifs) dans la configuration courante.
func view_size() -> Vector2:
	return (get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)) / zoom


static func next_of(p: String) -> String:
	return ORDER[(ORDER.find(p) + 1) % ORDER.size()]
