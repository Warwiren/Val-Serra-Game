extends "res://tools/p49/banc_v07.gd"
## V11 (20/11/2026) — forêt F5 : collisions du décor (rochers, buissons hauts), Vorgane, brouillard retiré.
##   godot --headless --path . --fixed-fps 60 --script res://tests/v11_collisions_smoke.gd

var failures := 0


func _test(ok: bool, label: String) -> void:
	if ok:
		print("V11 OK : " + label)
	else:
		failures += 1
		push_error("V11 ECHEC : " + label)


## pousse Aren vers +z (ou -z) depuis (x, z0) pendant `frames` images ; renvoie sa position finale
func _pousse(x: float, z0: float, dz: float, frames: int) -> Vector3:
	_place(x, z0)
	await _frames(10)
	_steer(Vector3(0, 0, dz))
	await _frames(frames)
	_stop()
	await _frames(5)
	return _hero().global_position


func _run() -> void:
	load("res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.gd").set("demarrage_v09c6", true)
	change_scene_to_file(SCENE)
	await _frames(30)
	sc = current_scene
	var env: Environment = sc.get("_world_env")
	_test(not env.fog_enabled and not env.volumetric_fog_enabled, "F5 démarre sans brouillard (brume et brume volumétrique coupées)")
	sc.call("_set_brume", true)
	_test(env.fog_enabled, "touche F : la brume reste disponible en comparaison")
	sc.call("_set_brume", false)
	var nr: int = sc.get("_nb_rochers")
	var nb: int = sc.get("_nb_buissons")
	var nt: int = (sc.get("_set_colliders") as Array).size()
	_test(nr == 33, "les 33 rochers du décor bloquent (%d)" % nr)
	_test(nb >= 30, "buissons hauts (≥ 0,85 m) bloquants : %d" % nb)
	_test(nt - nr - nb == 31, "arbres inchangés : %d" % (nt - nr - nb))
	# rocher autrefois traversable (Rock_Medium_1 non « blocking », (-6.6, 5.1), 2,06 m de large) : Aren s'arrête devant
	var p := await _pousse(-6.6, 2.6, 1.0, 120)
	_test(p.z < 5.1 - 0.6, "rocher (-6.6, 5.1) : Aren arrêté devant (z = %.2f)" % p.z)
	# Vorgane : présent, animé, solide, posé au sol
	var m: StaticBody3D = sc.get("_monstre")
	var ms: Sprite3D = sc.get("_monstre_sprite")
	_test(m != null and ms != null and (sc.get("_monstre_images") as Array).size() == 24 and bool(sc.get("_monstre_pose")),
		"Vorgane présent, 24 images d'attente, posé au sol (y = %.2f)" % (m.global_position.y if m != null else -99.0))
	var t0: Texture2D = ms.texture
	await _frames(20)
	_test(ms.texture != t0, "Vorgane animé (6 i/s)")
	var mz: float = m.global_position.z
	p = await _pousse(7.5, 0.3, 1.0, 120)
	_test(p.z < mz - 0.4, "Vorgane solide : Aren arrêté devant (z = %.2f, monstre %.2f)" % [p.z, mz])
	# par la tête (côté gauche de l'écran) : la boîte couvre toute la longueur du sprite (3 m), pas seulement 0,9 m
	var dr: Vector3 = (sc.get("_camera") as Camera3D).global_transform.basis.x
	dr.y = 0
	dr = dr.normalized()
	var s0: Vector3 = m.global_position - dr * 3.2
	_place(s0.x, s0.z)
	await _frames(10)
	_steer(dr)
	await _frames(120)
	_stop()
	await _frames(5)
	var le_long := (_hero().global_position - m.global_position).dot(dr)
	_test(le_long < -1.45, "Vorgane : arrêté au bout de sa tête (%.2f m de son centre ; sprite de 3 m)" % le_long)
	_test(not ms.flip_h or (p - m.global_position).dot((sc.get("_camera") as Camera3D).global_transform.basis.x) > 0.0,
		"Vorgane tourné vers Aren")
	p = await _pousse(10.0, 0.25, 1.0, 1)
	await _frames(20)
	_test(ms.flip_h, "Aren à sa droite : le Vorgane se retourne vers lui")
	print("V11 : %d échec(s)" % failures)
	quit(1 if failures > 0 else 0)
