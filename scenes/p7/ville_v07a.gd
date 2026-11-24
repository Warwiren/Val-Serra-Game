extends "res://scenes/p7/ville_v06.gd"
## P7.4 — VILLE V0.7-A : micro-blockout semi-circulaire et ascendant (comparaison caméra fixe A / semi-fixe B).
## EXPÉRIENCE DE CONCEPTION, NON VALIDÉE. Données : data/p7/ville_v07a.json (tools/p7/build_ville_v07a.py).
## Reprend le vocabulaire de la V0.6 (volumes provisoires, toits, estompage près de la caméra, escaliers clairs, ciel et
## brume) avec ce qui est propre à la V0.7-A :
##   * des masses de terrain par morceaux (paliers, belvédère, terrasses), pas des murs de soutènement rectilignes ;
##   * un Colisée reconnaissable de l'extérieur : tambour, arcades sur deux registres, attique, bannières, entrée
##     publique monumentale ; volume FERMÉ (l'arène n'est jamais visible depuis la ville) ;
##   * deux départs de rues vers des instances futures, fermés par un chantier et par une grille, prolongés au-delà
##     par des volumes de décor.

const PIERRE_COLISEE := Color(0.76, 0.66, 0.52)


## Décor : masses, paysage, Colisée, fontaine, château (déplacé), chantier, porte sud, ambiance.
func decorer() -> void:
	_masses()
	for p in v.get("paysage", []):
		var q: Array = p["rect"]
		var r := Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1])
		var h0: float = p["h"]
		var h1: float = h0 + float(p["haut"])
		var cat := "residentiel" if int(q[0] + q[1]) % 2 == 0 else "residentiel_b"
		var mi: MeshInstance3D = sc._box_mesh(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), mat(COULEURS[cat], 0.0, 1.0, h0, true))
		mi.name = "paysage"
		_toit(r, h1, str(p.get("toit", "2p")), int(q[0] * 31.0 + q[1] * 7.0))
	_colisee_v07()
	_fontaine_v06()
	# château de la V0.6, déplacé en bloc à la position des données (au nord-nord-est)
	var n0: int = sc.root.get_child_count()
	_chateau()
	var ch: Array = v.get("chateau", [60.0, -250.0])
	var d := Vector3(float(ch[0]) - 60.0, 0.0, float(ch[1]) + 250.0)
	for i in range(n0, sc.root.get_child_count()):
		var n: Node = sc.root.get_child(i)
		if n is Node3D:
			(n as Node3D).position += d
	_chantier()
	_ambiance()
	var ps: Array = v.get("porte_sud", [])
	if ps.size() == 3:
		var bois := mat(Color(0.45, 0.33, 0.24))
		for x in [float(ps[0]) + 0.25, float(ps[1]) - 0.25]:
			sc._box_mesh(Vector3(x, 0.8, float(ps[2])), Vector3(0.3, 1.6, 3.0), bois)
	_libelle("Colisée", Vector3(-6.0, 3.5 + 20.0, 100.0))
	_libelle("Château — accès fermé", Vector3(70.0, 12.0, 39.0))


## Masses de terrain : une boîte par morceau, du sol (−1 m) à l'altitude du morceau ; cordon clair au sommet de la
## face sud (lecture de la hauteur depuis la caméra).
func _masses() -> void:
	var pierre := mat(MUR_SOUT, 0.0, 0.0, 0.0)
	var cordon := mat(Color(0.70, 0.67, 0.61))
	for m in v.get("masses", []):
		var q: Array = m[0]
		var h: float = float(m[1]) - 0.006
		var r := Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1])
		sc._box_mesh(sc._rect_center(r, -1.0, h), Vector3(r.size.x, h + 1.0, r.size.y), pierre)
		sc._box_mesh(Vector3(r.get_center().x, h - 0.005, r.get_center().y), Vector3(r.size.x, 0.01, r.size.y), mat(_sol(h + 0.01).darkened(0.12), 1.0))
		if r.size.x < 200.0:
			sc._box_mesh(Vector3(r.get_center().x, h - 0.12, r.end.y + 0.12), Vector3(r.size.x, 0.24, 0.24), cordon)
	# joues des volées (murets latéraux)
	for vo in v.get("volees", []):
		var x0: float = vo[1]
		var x1: float = vo[2]
		var yh: float = vo[3]
		var L: float = vo[4]
		var hb: float = vo[5]
		var ht: float = vo[6]
		for xj in [x0 - 0.2, x1 + 0.2]:
			sc._box_mesh(Vector3(xj, (hb + ht) * 0.5 + 0.25, yh + L * 0.5), Vector3(0.4, ht - hb + 0.5, L), mat(MUR_SOUT.lightened(0.05), 0.0, 0.0, hb))


## Colisée vu de la ville : tambour elliptique fermé (sol de l'arène jamais visible), deux registres d'arcades sombres,
## attique plein, couronnement, bannières entre les arcs, entrée publique à l'est (porche, fronton, bannière de la Guilde).
func _colisee_v07() -> void:
	var cd: Dictionary = v.get("colisee", {})
	if cd.is_empty():
		return
	var c := Vector2(cd["centre"][0], cd["centre"][1])
	var rr := Vector2(cd["rayons"][0], cd["rayons"][1])
	var h0: float = cd["h"]
	var haut: float = cd["haut"]
	var pierre := mat(PIERRE_COLISEE, 0.0, 0.0, h0)
	var sombre := mat(Color(0.16, 0.14, 0.12))
	# tambour (cylindre fermé, mis à l'échelle de l'ellipse)
	for spec in [[0.0, haut, 1.0, pierre], [haut, haut + 0.7, 1.015, mat(PIERRE_COLISEE.lightened(0.12))],
			[3.4, 3.8, 1.012, mat(PIERRE_COLISEE.darkened(0.08))], [9.4, 9.8, 1.012, mat(PIERRE_COLISEE.darkened(0.08))]]:
		var cy := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 1.0
		cm.bottom_radius = 1.0
		cm.height = float(spec[1]) - float(spec[0])
		cm.radial_segments = 96
		cm.rings = 1
		cy.mesh = cm
		cy.scale = Vector3(rr.x * spec[2], 1.0, rr.y * spec[2])
		cy.position = Vector3(c.x, h0 + (float(spec[0]) + float(spec[1])) * 0.5, c.y)
		cy.material_override = spec[3]
		cy.name = "Colisee_tambour"
		sc.root.add_child(cy)
	# arcades : deux registres + attique à fenêtres carrées, sur la moitié sud (face à la ville et à la caméra)
	var n := 44
	for k in n:
		var a := PI * (k + 0.5) / n
		var dirv := Vector2(cos(a), sin(a))
		var p := c + Vector2(dirv.x * rr.x, dirv.y * rr.y) * 1.004
		var nrm := Vector2(dirv.x / rr.x, dirv.y / rr.y).normalized()
		var ang := atan2(nrm.x, nrm.y)
		for reg in [[0.0, 3.2, 1.7], [4.2, 9.0, 1.6], [10.6, 13.4, 1.0]]:
			if float(reg[0]) < 4.5 and absf(p.x - c.x) < 5.0:
				continue                         # entrée publique
			var hh: float = float(reg[1]) - float(reg[0])
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(reg[2], hh, 0.12)
			mi.mesh = bm
			mi.material_override = sombre
			mi.position = Vector3(p.x, h0 + float(reg[0]) + hh * 0.5 + 0.2, p.y)
			mi.rotation.y = ang
			sc.root.add_child(mi)
		if k % 4 == 2:
			_banniere_colisee(Vector3(p.x, h0 + 13.6, p.y) + Vector3(nrm.x, 0, nrm.y) * 0.15, ang, Color(0.62, 0.16, 0.18))
	# entrée publique (sud, face caméra) : porche saillant, baie sombre, fronton, bannière de la Guilde au-dessus
	var vb: Array = cd.get("vestibule", [])
	if vb.size() == 4:
		var r := Rect2(vb[0], vb[1], vb[2] - vb[0], vb[3] - vb[1])
		var ye: float = r.end.y
		for x in [r.position.x - 1.0, r.end.x + 1.0]:
			sc._box_mesh(Vector3(x, h0 + 4.5, ye - 0.8), Vector3(1.6, 9.0, 1.6), pierre)
		sc._box_mesh(Vector3(r.get_center().x, h0 + 8.0, ye - 0.8), Vector3(r.size.x + 3.6, 2.0, 1.6), pierre)
		sc._box_mesh(Vector3(r.get_center().x, h0 + 9.6, ye - 0.8), Vector3(r.size.x + 4.4, 1.2, 1.8), mat(PIERRE_COLISEE.lightened(0.12)))
		sc._box_mesh(Vector3(r.get_center().x, h0 + 3.5, r.position.y + 0.5), Vector3(r.size.x, 7.0, 1.0), sombre)
		_banniere_colisee(Vector3(r.get_center().x, h0 + 13.5, ye - 1.0), 0.0, Color(0.22, 0.30, 0.62), 2.6, 3.4)


func _banniere_colisee(p: Vector3, ang: float, col: Color, larg := 1.4, haut := 3.0) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(larg, haut, 0.05)
	mi.mesh = bm
	mi.material_override = m
	mi.position = p - Vector3(0, haut * 0.5, 0)
	mi.rotation.y = ang
	sc.root.add_child(mi)
	var or_ := StandardMaterial3D.new()
	or_.albedo_color = Color(0.92, 0.78, 0.36)
	var mo := MeshInstance3D.new()
	var bo := BoxMesh.new()
	bo.size = Vector3(larg * 0.4, larg * 0.4, 0.07)
	mo.mesh = bo
	mo.material_override = or_
	mo.position = p - Vector3(0, haut * 0.45, 0)
	mo.rotation.y = ang
	sc.root.add_child(mo)


## Chantier qui ferme la rue vers l'est : barrière, échafaudage, tas de matériaux (décor, sans collision au-delà).
func _chantier() -> void:
	var q: Array = v.get("chantier", [])
	if q.size() != 4:
		return
	var bois := mat(Color(0.55, 0.40, 0.26))
	var jaune := mat(Color(0.85, 0.62, 0.20))
	var x: float = q[2]
	for y in range(int(q[1]), int(q[3]) + 1, 2):
		sc._box_mesh(Vector3(x + 0.3, 0.6, float(y)), Vector3(0.15, 1.2, 0.15), bois)
	for hh in [0.45, 1.0]:
		sc._box_mesh(Vector3(x + 0.3, hh, (float(q[1]) + float(q[3])) * 0.5), Vector3(0.1, 0.22, float(q[3]) - float(q[1])), jaune)
	# échafaudage contre la façade nord de la rue, au-delà de la barrière
	for i in 4:
		var xx := x + 3.0 + i * 2.5
		sc._box_mesh(Vector3(xx, 3.0, 135.6), Vector3(0.14, 6.0, 0.14), bois)
	for hh in [2.0, 4.0]:
		sc._box_mesh(Vector3(x + 6.75, hh, 135.4), Vector3(8.0, 0.12, 1.0), bois)
	sc._box_mesh(Vector3(x + 5.0, 0.5, 141.0), Vector3(2.4, 1.0, 1.6), mat(Color(0.62, 0.60, 0.56)))
	sc._box_mesh(Vector3(x + 8.0, 0.35, 142.0), Vector3(1.6, 0.7, 1.2), bois)
