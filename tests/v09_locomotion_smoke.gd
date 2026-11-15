extends SceneTree
## Usage (depuis la racine du projet Godot 4.7.2) :
## godot --headless --path . --script res://tests/v09_locomotion_smoke.gd
const L = preload("res://src/explore25/locomotion_v09.gd")
var failures := 0


func _test(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("V09A ECHEC : " + label)
	else:
		print("V09A OK : " + label)


func _initialize() -> void:
	# Vitesse visée et freinage ; aucun changement de vitesse maximale.
	var v := Vector3.ZERO
	for i in 60:
		v = L.approach_velocity(v, Vector3(2.2, 0, 0), 1.0 / 60.0, 19.0, 22.0)
	_test(absf(v.x - 2.2) < 0.001, "vitesse marche 2,2 m/s")
	v = L.approach_velocity(v, Vector3.ZERO, 1.0 / 60.0, 19.0, 22.0)
	_test(v.x < 2.2 and v.x > 0.0, "freinage progressif")
	for i in 30:
		v = L.approach_velocity(v, Vector3.ZERO, 1.0 / 60.0, 19.0, 22.0)
	_test(v.length() < 0.001, "arrêt complet sans dérive")

	# Le point suivi doit être derrière, sur le trajet d'Aren, pas juste un vecteur dans le dos.
	var trail = L.new()
	trail.reset(Vector3(0, 0, 0), Vector3(-1.4, 0, 0))
	_test(absf(trail.follow_target(1.28).x + 1.28) < 0.01, "séparation initiale de 1,28 m")
	for i in 30:
		trail.record(Vector3(float(i) * 0.06, 0, 0))
	var target: Vector3 = trail.follow_target(1.28)
	_test(target.x < 1.74 and target.x > 0.35, "point suivi sur la trajectoire")
	for i in 30:
		trail.record(Vector3(1.74, 0, float(i) * 0.06))
	target = trail.follow_target(1.28)
	_test(absf(target.x - 1.74) < 0.10, "suivi du coude à 90 degrés")

	var comp_v := L.follower_velocity(Vector3.ZERO, Vector3(1.0, 0.0, 0.0), 1.0 / 60.0, 4.25)
	_test(comp_v.x > 0.0 and comp_v.x < 4.25, "Ilya démarre sans saut de vitesse")
	_test(L.follower_velocity(Vector3.ZERO, Vector3(0.07, 0, 0), 1.0 / 60.0, 4.25).is_zero_approx(), "zone d'arrêt anti-tremblement")

	print("V09A : %d échec(s)" % failures)
	quit(1 if failures > 0 else 0)
