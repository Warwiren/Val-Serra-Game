extends SceneTree
## P6.2-C — continuité de la caméra du Colisée, image par image (sans rendu : positions seulement).
##   godot --headless --path . --script res://tools/p6/camera_continuite_p6.gd -- --route=p6_tunnel --etat=tutorial_completed
##        [--csv=user://cam.csv] [--transitions=B]
## Mesure à chaque image physique : position 3D réelle de la caméra, vitesse, accélération, distance caméra–héros
## (un changement = un changement de zoom apparent), position d'Aren à l'écran (1280 × 720) et son déplacement.
## Un BOND est une image où la caméra va nettement plus vite qu'Aren ou change brutalement de vitesse ; le suivi normal
## (lissage, zone morte) reste sous ces seuils. Seuils volontairement prudents, rappelés dans la sortie.
const V_MARGE := 1.0        # m/s au-delà de la vitesse d'Aren (lissage : la caméra peut rattraper un peu)
const ACC_MAX := 30.0       # m/s² au-delà de l'accélération d'Aren lui-même (ses départs / arrêts sont instantanés)
const ECRAN_PX := 6.0       # déplacement d'Aren à l'écran en une image, au-delà de son propre mouvement
var z
var n := 0
var cam_prev := Vector3.INF
var v_prev := Vector3.ZERO
var vh_prev := Vector3.ZERO
var hero_prev := Vector3.INF
var ecr_prev := Vector2.INF
var dist0 := -1.0
var lignes: PackedStringArray = ["t;secteur;x;y;cam_x;cam_y;cam_z;v_cam;v_hero;acc;dist;ecran_x;ecran_y;d_ecran;bond"]
var bonds: Array = []
var t := 0.0
var v_max := 0.0
var acc_max := 0.0
var dist_min := INF
var dist_max := 0.0
var ecran_max := 0.0
var arret_derive := 0.0     # déplacement cumulé de la caméra pendant qu'Aren est immobile (stabilité à l'arrêt)
var fini := false


func _initialize() -> void:
	change_scene_to_file("res://scenes/p6/colisee.tscn")


func _physics_process(delta: float) -> bool:
	if fini:
		return false
	n += 1
	if z == null:
		if n > 5 and current_scene != null and current_scene.get("world") != null and current_scene.get("cam") != null:
			z = current_scene
		return false
	var cam: Camera3D = z.cam
	var body: Node3D = z.body
	var s = z.s
	t += delta
	var cp := cam.global_position
	var hp := body.global_position
	var vp := Vector2(1280, 720)
	# position d'Aren à l'écran, calculée à partir de la caméra (indépendante de la taille de la fenêtre headless)
	var local := cam.global_transform.affine_inverse() * (hp + Vector3(0, 0.6, 0))
	var f := 0.5 * vp.y / tan(deg_to_rad(cam.fov) * 0.5)
	var ecr := Vector2(vp.x * 0.5 + f * local.x / -local.z, vp.y * 0.5 - f * local.y / -local.z)
	# recul de la caméra le long de son axe par rapport au plan d'Aren : constant tant que le zoom ne change pas
	var dist := (cp - hp).dot(cam.global_transform.basis.z)
	if cam_prev != Vector3.INF and delta > 0.0:
		var v := (cp - cam_prev) / delta
		var vhv := (hp - hero_prev) / delta
		var vh := vhv.length()
		var acc := (v - v_prev).length() / delta
		var acc_h := (vhv - vh_prev).length() / delta
		var d_ecr := ecr.distance_to(ecr_prev)
		var bond := ""
		if t > 0.6:                                 # mise en place
			if v.length() > vh + V_MARGE and v.length() > 1.5:
				bond = "vitesse"
			elif acc > acc_h + ACC_MAX:
				bond = "acceleration"
			elif d_ecr > ECRAN_PX and vh < 0.05:
				bond = "ecran"
			if absf(dist - dist0) > 0.05 and dist0 > 0.0:
				bond += ("+" if bond != "" else "") + "zoom"
				dist0 = dist
			v_max = maxf(v_max, v.length())
			acc_max = maxf(acc_max, acc)
			ecran_max = maxf(ecran_max, d_ecr)
			if vh < 0.02:
				arret_derive += (cp - cam_prev).length()
		dist_min = minf(dist_min, dist)
		dist_max = maxf(dist_max, dist)
		if bond != "":
			bonds.append("t=%.2f %s %s v=%.2f m/s (Aren %.2f) acc=%.1f écran=%.1f px dist=%.3f" % [t, z.secteur_actif(), bond,
				v.length(), vh, acc, d_ecr, dist])
		lignes.append("%.3f;%s;%.3f;%.3f;%.4f;%.4f;%.4f;%.3f;%.3f;%.2f;%.4f;%.1f;%.1f;%.2f;%s" % [t, z.secteur_actif(),
			s.hero.x, s.hero.y, cp.x, cp.y, cp.z, v.length(), vh, acc, dist, ecr.x, ecr.y, d_ecr, bond])
		v_prev = v
		vh_prev = vhv
	else:
		dist0 = dist
	if dist0 < 0.0 or t < 0.6:
		dist0 = dist
	cam_prev = cp
	hero_prev = hp
	ecr_prev = ecr
	if s.pilot_done or t > 90.0:
		fini = true
		var args := OS.get_cmdline_user_args()
		var csv := "user://camera_continuite_p6.csv"
		for a in args:
			if a.begins_with("--csv="):
				csv = a.substr(6)
		var fh := FileAccess.open(csv, FileAccess.WRITE)
		if fh != null:
			fh.store_string("\n".join(lignes) + "\n")
		print("CAMERA P6.2-C : %d images, %.1f s, %d bonds ; vitesse max %.2f m/s, accélération max %.1f m/s², recul caméra %.3f–%.3f m (zoom), déplacement écran max %.1f px/image, dérive à l'arrêt %.3f m" % [
			lignes.size() - 1, t, bonds.size(), v_max, acc_max, dist_min, dist_max, ecran_max, arret_derive])
		print("  seuils : vitesse > Aren + %.1f m/s, accélération > %.0f m/s², Aren déplacé de > %.0f px à l'écran sans bouger, distance ±0,05 m" % [V_MARGE, ACC_MAX, ECRAN_PX])
		for b in bonds.slice(0, 40):
			print("  BOND " + b)
		print("  bloqués : %s" % str(s.m.get("stuck", [])))
		print("  csv : " + ProjectSettings.globalize_path(csv))
		quit()
	return false
