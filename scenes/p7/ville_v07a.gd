extends "res://scenes/p7/ville_v06.gd"
## P7.4 — VILLE V0.7-A : micro-blockout semi-circulaire et ascendant (comparaison caméra fixe A / semi-fixe B).
## EXPÉRIENCE DE CONCEPTION, NON VALIDÉE. Données : data/p7/ville_v07a.json (tools/p7/build_ville_v07a.py).
## P8.0-C : maillon de la chaîne d'héritage de la ville V0.7-B (son decorer() est appelé par ville_v07b) ; données,
## générateur et plan de la V0.7-A retirés (historique Git, commit 588e90c).
## Reprend le vocabulaire de la V0.6 (volumes provisoires, toits, estompage près de la caméra, escaliers clairs, ciel et
## brume) avec ce qui est propre à la V0.7-A :
##   * des masses de terrain par morceaux (paliers, belvédère, terrasses), pas des murs de soutènement rectilignes ;
##   * un Colisée reconnaissable de l'extérieur : tambour, arcades sur deux registres, attique, bannières, entrée
##     publique monumentale ; volume FERMÉ (l'arène n'est jamais visible depuis la ville) ;
##   * deux départs de rues vers des instances futures, fermés par un chantier et par une grille, prolongés au-delà
##     par des volumes de décor.

const PIERRE_COLISEE := Color(0.76, 0.66, 0.52)


## P7.4.2 : piles et mur du propylée = collisions des données seulement (dessinés par _propylee).
func construit(e: Dictionary) -> bool:
	if e["type"] == "block" and str(e.get("id", "")).begins_with("porche_"):
		var r: Rect2 = e["rect"]
		sc._static_box(sc._rect_center(r, e["h0"], e["h1"]), Vector3(r.size.x, e["h1"] - e["h0"], r.size.y), sc.L_OBST)
		return true
	return super(e)


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
	# joues des volées (murets latéraux) ; P7.12.2 : la V0.7-B les remplace par les murs d'échiffre de ses escaliers de pierre
	if has_method("sans_joues") and call("sans_joues"):
		return
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
		# P7.6 : les cordons (anneaux à peine plus larges que le tambour) n'ont plus de couvercles : leur bord supérieur, à
		# peine visible entre les facettes, faisait une ligne claire en pointillés sur toute la façade (cause confirmée en
		# masquant les cordons ; les ombres n'y étaient pour rien). Tambour et couronnement gardent les leurs (fermeture).
		if float(spec[2]) > 1.0 and float(spec[1]) < haut:
			cm.cap_top = false
			cm.cap_bottom = false
		cy.mesh = cm
		cy.scale = Vector3(rr.x * spec[2], 1.0, rr.y * spec[2])
		cy.position = Vector3(c.x, h0 + (float(spec[0]) + float(spec[1])) * 0.5, c.y)
		cy.material_override = spec[3]
		cy.name = "Colisee_tambour"
		if sc._cli.has("sans_cordons") and float(spec[2]) > 1.0 and float(spec[0]) > 0.0 and float(spec[1]) < haut:
			cy.visible = false                                 # P7.6 : diagnostic de la bande du tambour
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
			if float(reg[0]) < 4.5 and _pres_porte(p, cd):
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
	# P7.4.1 / P7.4.2 : porte publique sur la façade EST (vers la grande place, même axe réel que la sortie est de
	# l'instance du Colisée). P7.4.2 : PROPYLÉE monumental devant elle (voir _propylee).
	var vb: Array = cd.get("vestibule", [])
	if vb.size() == 4:
		var r := Rect2(vb[0], vb[1], vb[2] - vb[0], vb[3] - vb[1])
		var yc := r.get_center().y
		# vestibule creusé dans le tambour : joues, voûte, fond sombre (on y entre en marchant)
		for y in [r.position.y - 0.1, r.end.y + 0.1]:
			sc._box_mesh(Vector3(r.get_center().x, h0 + 3.6, y), Vector3(r.size.x, 7.2, 0.2), pierre)
		sc._box_mesh(Vector3(r.position.x - 0.3, h0 + 3.6, yc), Vector3(0.6, 7.2, r.size.y), sombre)
		sc._box_mesh(Vector3(r.get_center().x, h0 + 7.4, yc), Vector3(r.size.x, 0.4, r.size.y + 0.4), pierre)
		_propylee(cd.get("propylee", {}), h0, yc)
		_porte_battants(cd.get("porte_battants", []), h0)


## P7.5 : porte publique à deux battants dans l'ARCHE SUD du propylée (face à l'allée d'approche et à la caméra), en
## retrait des piles : bois sombre, planches, ferrures et clous, anneaux, tympan de bois sous le cintre, seuil de pierre
## claire. Fermée et solide : on entre par interaction (E), suivie du fondu de la transition existante.
func _porte_battants(q: Array, h0: float) -> void:
	if q.size() != 4:
		return
	var x0: float = q[0]
	var x1: float = q[2]
	var y := (float(q[1]) + float(q[3])) * 0.5
	var R := (x1 - x0) * 0.5
	var xc := (x0 + x1) * 0.5
	var naissance := 4.4
	var bois := StandardMaterial3D.new()
	bois.albedo_color = Color(0.20, 0.12, 0.075)
	bois.roughness = 0.85
	var planche := mat(Color(0.14, 0.085, 0.05))
	var fer := StandardMaterial3D.new()
	fer.albedo_color = Color(0.16, 0.16, 0.18)
	fer.metallic = 0.7
	fer.roughness = 0.45
	var larg := R
	for i in 2:
		var xb := x0 + larg * (i + 0.5)
		sc._box_mesh(Vector3(xb, h0 + naissance * 0.5, y), Vector3(larg - 0.04, naissance, 0.2), bois)
		for k in 5:
			sc._box_mesh(Vector3(x0 + larg * i + (k + 0.5) * larg / 5.0, h0 + naissance * 0.5, y + 0.11), Vector3(0.05, naissance - 0.2, 0.03), planche)
		for hb in [0.6, 2.2, 3.8]:
			sc._box_mesh(Vector3(xb, h0 + hb, y + 0.13), Vector3(larg - 0.2, 0.16, 0.05), fer)
			for k in 6:
				sc._box_mesh(Vector3(x0 + larg * i + 0.2 + k * (larg - 0.4) / 5.0, h0 + hb, y + 0.16), Vector3(0.07, 0.07, 0.05), fer)
		sc._box_mesh(Vector3(xc + (-0.6 if i == 0 else 0.6), h0 + 1.9, y + 0.18), Vector3(0.36, 0.36, 0.06), fer)
	# tympan de bois en gradins sous le cintre (masqués par l'archivolte), traverse et montant central ferrés
	var n := 6
	for i in n:
		var ha := naissance + R * float(i) / n
		var hb2 := naissance + R * float(i + 1) / n
		var w := 2.0 * sqrt(maxf(0.0, R * R - (hb2 - naissance) * (hb2 - naissance)))
		if w > 0.05:
			sc._box_mesh(Vector3(xc, h0 + (ha + hb2) * 0.5, y), Vector3(w, hb2 - ha, 0.2), bois)
	sc._box_mesh(Vector3(xc, h0 + naissance, y + 0.14), Vector3(2.0 * R, 0.2, 0.06), fer)
	sc._box_mesh(Vector3(xc, h0 + naissance * 0.5, y + 0.14), Vector3(0.12, naissance, 0.06), fer)
	sc._box_mesh(Vector3(xc, h0 + 0.06, y + 0.4), Vector3(2.0 * R + 0.4, 0.12, 0.8), mat(CALCAIRE_CLAIR))


## Propylée de l'entrée publique : avant-corps en calcaire CLAIR (distinct de l'ocre du tambour et de ses arcades
## sombres) devant la porte est. Deux grandes arches à encadrement massif (bandeau d'archivolte et clé claire) :
##   * arche EST, dans l'axe réel de la porte ;
##   * arche SUD, ouverte sur l'allée d'approche, donc face à la caméra qui regarde le nord : c'est elle qui signale
##     l'entrée depuis la place et le parvis.
## Attique avec emblème doré, deux bannières de la Guilde sur la face sud, lumière chaude sous la voûte et deux
## lanternes (énergie modérée, aucun changement de l'éclairage global). Collisions : piles et mur nord (données).
const CALCAIRE := Color(0.86, 0.82, 0.72)
const CALCAIRE_CLAIR := Color(0.93, 0.90, 0.82)


func _propylee(p: Dictionary, h0: float, yc: float) -> void:
	if p.is_empty():
		return
	var e: Array = p["emprise"]
	var x0: float = e[0]
	var y0: float = e[1]
	var x1: float = e[2]
	var y1: float = e[3]
	var pierre := mat(CALCAIRE, 0.0, 0.0, h0)
	var clair := mat(CALCAIRE_CLAIR)
	var haut := 9.5
	# piles massives (socle saillant et chapiteau)
	for k in p["piles"]:
		var q: Array = p["piles"][k]
		var rr := Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1])
		sc._box_mesh(sc._rect_center(rr, h0, h0 + haut), Vector3(rr.size.x, haut, rr.size.y), pierre)
		sc._box_mesh(sc._rect_center(rr.grow(0.18), h0, h0 + 0.9), Vector3(rr.size.x + 0.36, 0.9, rr.size.y + 0.36), clair)
		sc._box_mesh(sc._rect_center(rr.grow(0.14), h0 + 4.2, h0 + 4.6), Vector3(rr.size.x + 0.28, 0.4, rr.size.y + 0.28), clair)
	var mn: Array = p["mur_n"]
	var rn := Rect2(mn[0], mn[1], mn[2] - mn[0], mn[3] - mn[1])
	sc._box_mesh(sc._rect_center(rn, h0, h0 + haut), Vector3(rn.size.x, haut, rn.size.y), pierre)
	# arche est (plan x = x1 - 0,6) et arche sud (plan y = y1 - 0,6)
	var ne: Array = p["piles"]["ne"]
	var se: Array = p["piles"]["se"]
	var so: Array = p["piles"]["so"]
	_arche(Vector3(x1 - 0.8, h0, (float(ne[3]) + float(se[1])) * 0.5), "y", (float(se[1]) - float(ne[3])) * 0.5, 4.4, haut, 1.6, pierre, clair)
	# P7.5 : arche est aveugle (panneau de pierre en retrait) : le porche est fermé, on entre par la porte de l'arche sud
	sc._box_mesh(Vector3(x1 - 0.55, h0 + 4.0, (float(ne[3]) + float(se[1])) * 0.5), Vector3(0.3, 8.0, float(se[1]) - float(ne[3])), mat(CALCAIRE.darkened(0.12)))
	_arche(Vector3((float(so[2]) + float(se[0])) * 0.5, h0, y1 - 0.8), "x", (float(se[0]) - float(so[2])) * 0.5, 4.4, haut, 1.6, pierre, clair)
	# voûte (plafond), entablement et attique avec emblème
	sc._box_mesh(Vector3((x0 + x1) * 0.5, h0 + haut - 0.3, (y0 + y1) * 0.5), Vector3(x1 - x0, 0.6, y1 - y0), pierre)
	sc._box_mesh(Vector3((x0 + x1) * 0.5, h0 + haut + 0.35, (y0 + y1) * 0.5), Vector3(x1 - x0 + 0.6, 0.7, y1 - y0 + 0.6), clair)
	sc._box_mesh(Vector3((x0 + x1) * 0.5, h0 + haut + 1.6, (y0 + y1) * 0.5), Vector3(x1 - x0 - 0.4, 1.8, y1 - y0 - 0.4), pierre)
	sc._box_mesh(Vector3((x0 + x1) * 0.5, h0 + haut + 2.65, (y0 + y1) * 0.5), Vector3(x1 - x0 + 0.2, 0.3, y1 - y0 + 0.2), clair)
	var or_ := StandardMaterial3D.new()
	or_.albedo_color = Color(0.93, 0.76, 0.30)
	or_.metallic = 0.4
	or_.roughness = 0.45
	for spec in [[Vector3((x0 + x1) * 0.5, h0 + haut + 1.6, y1 - 0.15), 0.0], [Vector3(x1 - 0.15, h0 + haut + 1.6, (y0 + y1) * 0.5), PI * 0.5]]:
		var disque := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.75
		cm.bottom_radius = 0.75
		cm.height = 0.12
		cm.radial_segments = 24
		disque.mesh = cm
		disque.material_override = or_
		disque.position = spec[0]
		disque.rotation = Vector3(PI * 0.5, spec[1], 0.0)
		sc.root.add_child(disque)
	# deux bannières de la Guilde sur la face sud (face caméra), de part et d'autre de l'arche
	for x in [float(so[0]) + 0.5, float(se[0]) + 0.8]:
		_banniere_colisee(Vector3(x, h0 + 8.6, y1 + 0.08), 0.0, Color(0.20, 0.30, 0.66), 1.2, 4.2)
	# lumière chaude sous la voûte (signale le passage) et lanternes de part et d'autre de l'arche sud
	sc._light(Vector3((x0 + x1) * 0.5 - 1.0, h0 + 5.5, yc), 1.3, 9.0, Color(1.0, 0.78, 0.5))
	for x in [float(so[2]) + 0.35, float(se[0]) - 0.35]:
		sc._light(Vector3(x, h0 + 3.2, y1 + 0.6), 1.0, 6.0)
		sc._halo(Vector3(x, h0 + 3.2, y1 + 0.6), 0.9, 0.45)
		sc._box_mesh(Vector3(x, h0 + 3.0, y1 + 0.35), Vector3(0.28, 0.45, 0.28), mat(Color(0.25, 0.2, 0.16)))
	_libelle("Colisée — entrée publique", Vector3((x0 + x1) * 0.5, h0 + haut + 4.0, (y0 + y1) * 0.5))


## Arche : ouverture en plein cintre (rayon R, naissance à h0 + naissance) dans un mur de hauteur « haut », plan normal
## à « axe » ("x" : arche ouverte vers le sud / le nord, s'étend le long de x ; "y" : ouverte vers l'est, le long de y).
## Écoinçons en gradins (masqués par l'archivolte), archivolte en claveaux clairs, clé saillante.
func _arche(c: Vector3, axe: String, R: float, naissance: float, haut: float, ep: float, pierre: Material, clair: Material) -> void:
	var le_long := func(u: float, h: float, du: float, dh: float, epaisseur: float, m: Material) -> void:
		var pos := Vector3(c.x + u, c.y + h, c.z) if axe == "x" else Vector3(c.x, c.y + h, c.z + u)
		var size := Vector3(du, dh, epaisseur) if axe == "x" else Vector3(epaisseur, dh, du)
		sc._box_mesh(pos, size, m)
	# mur au-dessus de la clé
	var top_arc := naissance + R
	le_long.call(0.0, (top_arc + 0.5 + haut) * 0.5, 2.0 * R, haut - top_arc - 0.5, ep, pierre)
	# écoinçons en gradins de part et d'autre
	var n := 6
	for i in n:
		var ha := naissance + R * float(i) / n
		var hb := naissance + R * float(i + 1) / n
		var w := R - sqrt(maxf(0.0, R * R - (hb - naissance) * (hb - naissance)))
		if w <= 0.01:
			continue
		for sgn in [-1.0, 1.0]:
			le_long.call(sgn * (R - w * 0.5), (ha + hb) * 0.5, w, hb - ha, ep, pierre)
	le_long.call(0.0, (top_arc + top_arc + 0.5) * 0.5, 2.0 * R, 0.5, ep, pierre)
	# archivolte : claveaux clairs le long du cintre, légèrement en saillie
	var k := 15
	for i in k:
		var a := PI * (float(i) + 0.5) / k
		var u := cos(a) * (R + 0.35)
		var h := naissance + sin(a) * (R + 0.35)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(PI * (R + 0.35) / k + 0.05, 0.7, ep + 0.3) if axe == "x" else Vector3(ep + 0.3, 0.7, PI * (R + 0.35) / k + 0.05)
		mi.mesh = bm
		mi.material_override = clair
		mi.position = Vector3(c.x + u, c.y + h, c.z) if axe == "x" else Vector3(c.x, c.y + h, c.z + u)
		if axe == "x":
			mi.rotation.z = a - PI * 0.5
		else:
			mi.rotation.x = -(a - PI * 0.5)
		sc.root.add_child(mi)
	# clé
	le_long.call(0.0, top_arc + 0.35, 0.8, 1.0, ep + 0.5, clair)


func _pres_porte(p: Vector2, cd: Dictionary) -> bool:
	var vb: Array = cd.get("vestibule", [])
	if vb.size() != 4:
		return false
	return absf(p.y - (float(vb[1]) + float(vb[3])) * 0.5) < 4.0 and p.x > float(vb[0]) - 3.0


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
