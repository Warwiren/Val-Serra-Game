extends RefCounted
## Val'Serra — V09A / locomotion d'exploration, essai réversible.
## Pas de modification de Actor25 ni des sprites existants.
## Trajectoire sur le plan XZ pour éviter qu'un relief fasse 'consommer' la distance de suivi.

const SAMPLE_METERS := 0.12
const MAX_SAMPLES := 160
const FOLLOW_DEADBAND := 0.14
const FOLLOW_GAIN := 8.5
const FOLLOW_ACCEL := 17.0
const FOLLOW_BRAKE := 22.0

var _points: Array[Vector3] = []
var _tip := Vector3.ZERO


static func horizontal(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


## Limitation de l'accélération et du freinage (unités : m/s²).
## Toutes les transitions sont calculées dans _physics_process ; aucune dépendance au FPS d'affichage.
static func approach_velocity(current: Vector3, desired: Vector3, delta: float, acceleration: float, brake: float) -> Vector3:
	var v := horizontal(current)
	var target := horizontal(desired)
	var rate := brake if target.length_squared() < 0.0001 else acceleration
	return v.move_toward(target, maxf(0.0, rate * delta))


func reset(hero_pos: Vector3, companion_pos: Vector3) -> void:
	_points.clear()
	_points.append(horizontal(companion_pos))
	_points.append(horizontal(hero_pos))
	_tip = horizontal(hero_pos)


## Insère un point tous les 12 cm environ. Le bout du chemin est actualisé à chaque tic.
func record(hero_pos: Vector3) -> void:
	var pos := horizontal(hero_pos)
	if _points.is_empty():
		_points.append(pos)
		_tip = pos
		return
	if pos.distance_to(_points[_points.size() - 1]) >= SAMPLE_METERS:
		_points.append(pos)
		if _points.size() > MAX_SAMPLES:
			_points.remove_at(0)
	_tip = pos


## Renvoie un point situé à 'behind_m' mètres le long du trajet emprunté par Aren.
## Évite que le compagnon coupe le virage en visant seulement "derrière le héros".
func follow_target(behind_m: float) -> Vector3:
	if _points.is_empty():
		return _tip
	var remaining := maxf(0.0, behind_m)
	var from_pos := _tip
	for i in range(_points.size() - 1, -1, -1):
		var to_pos := _points[i]
		var segment := from_pos.distance_to(to_pos)
		if segment >= remaining and segment > 0.00001:
			return from_pos.lerp(to_pos, remaining / segment)
		remaining -= segment
		from_pos = to_pos
	return _points[0]


## Suit le point-cible avec amortissement et une petite zone d'arrêt anti-tremblement.
## Le plafond de rattrapage est distinct de la vitesse normale du héros.
static func follower_velocity(current: Vector3, to_target: Vector3, delta: float, max_speed: float) -> Vector3:
	var offset := horizontal(to_target)
	var distance := offset.length()
	var desired := Vector3.ZERO
	if distance > FOLLOW_DEADBAND:
		var speed := minf(max_speed, (distance - FOLLOW_DEADBAND) * FOLLOW_GAIN)
		desired = offset / distance * speed
	return approach_velocity(current, desired, delta, FOLLOW_ACCEL, FOLLOW_BRAKE)


func sampled_points_count() -> int:
	return _points.size()
