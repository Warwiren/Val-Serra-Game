extends RefCounted
## P3 — LOGIQUE DE CAMÉRA commune aux démonstrations A et B (aucun nœud : calculs seulement).
## La caméra est décrite dans le repère ÉCRAN projeté (px natifs, voir world25.gd) : centre + zoom. A l'applique à une
## Camera2D, B la convertit en position de Camera3D orthographique ; le cadrage est donc identique.
## Zooms validés (doc 04 §10) : ×2, ×2,5 (défaut), ×3 ; molette par crans, transition douce, pas de zoom continu.
## Suivi : preset B de P1 (zone morte 18 × 10 px, visée 8 px au-dessus des pieds, lissage critique 5) — choisi parce
## que c'était le réglage prévu pour ×2,5 ; il reste identique aux trois zooms (à valider en jeu).

const ZOOMS := [2.0, 2.5, 3.0]
const DEFAULT_INDEX := 1
const ZOOM_TIME := 0.3
const SMOOTH := 5.0
const DEAD := Vector2(18, 10)
const AIM := Vector2(0, -8)
const AIM_BLEND := 3.0                    # vitesse de retour au centrage (dialogue) et de reprise du décentrage

var index := DEFAULT_INDEX
var zoom := 2.5
var _z_from := 2.5
var _z_t := 1.0
var center := Vector2.ZERO
var focus := Vector2.ZERO
var bounds := Rect2()
var viewport_px := Vector2(1280, 720)
var snap := false                         # centre arrondi au pixel d'écran : activé avec le filtre « nearest » (évite
										  # le scintillement des sprites), désactivé en filtrage linéaire (suivi sous-pixel)
## P3-07, variante C : décentrage vertical en fraction de la hauteur d'écran (0,1 : avec la visée P3, héros vers 63 %).
## Ramené à 0 pendant un dialogue (doc 07 §03 : « ne pas décentrer aveuglément… lors des dialogues »).
var aim_frac := 0.0
var _aim_cur := 0.0
var ui_lock := false                      # dialogue / menu ouvert : la molette ne change pas le zoom
var wheel_ignored := 0                    # compteur (vérification : molette bloquée pendant l'UI)


func set_index(i: int, smooth := true) -> bool:
	i = clampi(i, 0, ZOOMS.size() - 1)
	if i == index:
		return false
	index = i
	_z_from = zoom
	_z_t = 0.0 if smooth else 1.0
	if not smooth:
		zoom = ZOOMS[index]
	return true


## Cran de molette : +1 rapproche (×3), −1 éloigne (×2).
func wheel(step: int) -> bool:
	if ui_lock:
		wheel_ignored += 1
		return false
	return set_index(index + step)


func target_zoom() -> float:
	return ZOOMS[index]


func view_size(z := -1.0) -> Vector2:
	return viewport_px / (zoom if z < 0.0 else z)


func clamp_center(c: Vector2, z := -1.0) -> Vector2:
	if bounds.size == Vector2.ZERO:
		return c
	var half := view_size(z) / 2.0
	var lo := bounds.position + half
	var hi := bounds.end - half
	return Vector2(clampf(c.x, lo.x, hi.x) if hi.x >= lo.x else bounds.get_center().x,
		clampf(c.y, lo.y, hi.y) if hi.y >= lo.y else bounds.get_center().y)


## Recentrage immédiat (apparition, changement d'instance, retour de dialogue) : pas de glissade.
## Visée totale (px natifs) : visée P1 + décentrage de la variante C, converti à l'échelle du zoom courant.
func aim() -> Vector2:
	return AIM + Vector2(0, -_aim_cur * viewport_px.y / zoom)


func snap_to(target: Vector2) -> void:
	focus = target
	_aim_cur = 0.0 if ui_lock else aim_frac
	center = clamp_center(target + aim())


## target = point écran des pieds du personnage (altitude comprise : la caméra monte avec lui dans l'escalier).
func update(target: Vector2, delta: float) -> void:
	if _z_t < 1.0:
		_z_t = minf(1.0, _z_t + delta / ZOOM_TIME)
		zoom = lerpf(_z_from, ZOOMS[index], smoothstep(0.0, 1.0, _z_t))
	var off := target - focus
	if absf(off.x) > DEAD.x:
		focus.x = target.x - signf(off.x) * DEAD.x
	if absf(off.y) > DEAD.y:
		focus.y = target.y - signf(off.y) * DEAD.y
	var want := 0.0 if ui_lock else aim_frac
	_aim_cur = move_toward(_aim_cur, want, aim_frac * AIM_BLEND * delta)   # transition en ≈ 0,33 s
	var goal := clamp_center(focus + aim())
	center = center.lerp(goal, 1.0 - exp(-SMOOTH * delta))
	center = clamp_center(center)


## Centre réellement appliqué (arrondi au pixel d'écran si snap).
func render_center() -> Vector2:
	if not snap:
		return center
	return (center * zoom).round() / zoom


func view_rect() -> Rect2:
	var v := view_size()
	return Rect2(render_center() - v / 2.0, v)


func zooming() -> bool:
	return _z_t < 1.0
