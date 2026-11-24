extends SceneTree
## P6.2-C — continuité de la caméra du Colisée, image par image (sans rendu : positions seulement).
##   godot --headless --path . --script res://tools/p6/camera_continuite_p6.gd -- --route=p6_tunnel --etat=tutorial_completed
##        [--csv=user://cam.csv] [--transitions=B] [--duree=s] [--scene=res://…tscn]
## Mesure à chaque image physique : position 3D réelle de la caméra, vitesse, accélération, distance caméra–héros
## (un changement = un changement de zoom apparent), position d'Aren à l'écran (1280 × 720) et son déplacement.
## Un BOND est une image où la caméra va nettement plus vite qu'Aren ou change brutalement de vitesse ; le suivi normal
## (lissage, zone morte) reste sous ces seuils. Seuils volontairement prudents, rappelés dans la sortie.
const V_MARGE := 1.0        # m/s au-delà de la vitesse d'Aren (lissage : la caméra peut rattraper un peu)
const V_MARCHE := 2.6       # P6.2-D : et au-delà de la marche (2,2 m/s) : le rattrapage lissé après un arrêt n'est pas un bond
const ACC_MAX := 30.0       # m/s² au-delà de l'accélération d'Aren lui-même (ses départs / arrêts sont instantanés)
const ECRAN_PX := 6.0       # déplacement d'Aren à l'écran en une image, au-delà de son propre mouvement
const World25 = preload("res://src/explore25/world25.gd")
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
## P7.4 : rotation de la caméra semi-fixe (ville V0.7-A) : vitesse d'azimut, épisodes, inversions de sens
var yaw_prev := INF
var yaw_v_prev := 0.0
var yaw_vmax := 0.0
var yaw_inversions := 0
var yaw_episodes := 0
var en_rotation := false
var images_rotation := 0
## P7.4.1 : position d'Aren à l'écran (1280 × 720) : extrêmes et images hors de la zone confortable
## (x de 15 à 85 %, y de 20 à 85 %) ; « hors écran » = au-delà des bords
var ecr_min := Vector2(INF, INF)
var ecr_max_pos := Vector2(-INF, -INF)
var hors_confort := 0
var hors_ecran := 0
var hors_exemples: Array = []


func _initialize() -> void:
	var scene := "res://scenes/p6/colisee.tscn"
	for a0 in OS.get_cmdline_user_args():
		if a0.begins_with("--scene="):
			scene = a0.substr(8)                  # P7.3 : autre scène (ville V0.6 : scenes/p7/ville_v06_montee.tscn)
	change_scene_to_file(scene)


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
		var yv := 0.0
		if yaw_prev != INF:
			yv = rad_to_deg(World25.yaw - yaw_prev) / delta
		var tourne := absf(yv) > 0.05
		if tourne:
			images_rotation += 1
			yaw_vmax = maxf(yaw_vmax, absf(yv))
			if not en_rotation:
				yaw_episodes += 1
			if absf(yaw_v_prev) > 0.5 and absf(yv) > 0.5 and signf(yv) != signf(yaw_v_prev):
				yaw_inversions += 1
		en_rotation = tourne
		yaw_v_prev = yv if tourne else yaw_v_prev * 0.0
		if t > 0.6:
			ecr_min = Vector2(minf(ecr_min.x, ecr.x), minf(ecr_min.y, ecr.y))
			ecr_max_pos = Vector2(maxf(ecr_max_pos.x, ecr.x), maxf(ecr_max_pos.y, ecr.y))
			if ecr.x < 0.0 or ecr.x > vp.x or ecr.y < 0.0 or ecr.y > vp.y:
				hors_ecran += 1
			if ecr.x < vp.x * 0.15 or ecr.x > vp.x * 0.85 or ecr.y < vp.y * 0.2 or ecr.y > vp.y * 0.85:
				hors_confort += 1
				if hors_exemples.size() < 8 and (hors_confort % 30) == 1:
					hors_exemples.append("t=%.1f (%.1f, %.1f) écran (%d, %d)" % [t, s.hero.x, s.hero.y, int(ecr.x), int(ecr.y)])
		if t > 0.6:                                 # mise en place
			if tourne:
				# rotation voulue (orbite autour d'Aren) : seul compte le déplacement d'Aren à l'écran
				if d_ecr > ECRAN_PX + 2.0 * (1.0 if vh > 0.05 else 0.0) and vh < 0.05:
					bond = "ecran(rotation)"
			elif v.length() > vh + V_MARGE and v.length() > V_MARCHE:
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
	yaw_prev = World25.yaw
	hero_prev = hp
	ecr_prev = ecr
	var duree := 90.0
	for a0 in OS.get_cmdline_user_args():
		if a0.begins_with("--duree="):
			duree = float(a0.substr(8))           # P7.1 : parcours plus longs (ville)
	if s.pilot_done or t > duree:
		fini = true
		var args := OS.get_cmdline_user_args()
		var csv := "user://camera_continuite_p6.csv"
		for a in args:
			if a.begins_with("--csv="):
				csv = a.substr(6)
		var fh := FileAccess.open(csv, FileAccess.WRITE)
		if fh != null:
			fh.store_string("\n".join(lignes) + "\n")
		print("CAMERA : %d images, %.1f s, %d bonds ; vitesse max %.2f m/s, accélération max %.1f m/s², recul caméra %.3f–%.3f m (zoom), déplacement écran max %.1f px/image, dérive à l'arrêt %.3f m" % [
			lignes.size() - 1, t, bonds.size(), v_max, acc_max, dist_min, dist_max, ecran_max, arret_derive])
		print("  ÉCRAN : Aren entre x %d–%d px et y %d–%d px ; %d images hors zone confortable, %d hors écran %s" % [int(ecr_min.x), int(ecr_max_pos.x), int(ecr_min.y), int(ecr_max_pos.y), hors_confort, hors_ecran, str(hors_exemples)])
		print("  ROTATION : %d épisodes, %d images en rotation, vitesse d'azimut max %.1f °/s, %d inversions de sens" % [yaw_episodes, images_rotation, yaw_vmax, yaw_inversions])
		print("  seuils : vitesse > Aren + %.1f m/s et > %.1f m/s, accélération > %.0f m/s² au-delà d'Aren, Aren déplacé de > %.0f px à l'écran sans bouger, recul ±0,05 m" % [V_MARGE, V_MARCHE, ACC_MAX, ECRAN_PX])
		for b in bonds.slice(0, 40):
			print("  BOND " + b)
		print("  bloqués : %s" % str(s.m.get("stuck", [])))
		print("  csv : " + ProjectSettings.globalize_path(csv))
		quit()
	return false
