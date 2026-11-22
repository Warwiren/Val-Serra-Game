extends "res://tests/test_case.gd"
## P6 — Colisée de Val'Serra (ouverture) : données de la zone, accès selon la progression (modèle logique World25 +
## portes de la scène), PNJ et dialogues, états de progression, adversaire du tutoriel (CombatCore inchangé).
## Le parcours complet joué (exploration -> tutoriel -> retour -> sortie) est vérifié par tests/e2e_p6_ouverture.gd.

const World25 = preload("res://src/explore25/world25.gd")
const Progression = preload("res://src/game/progression.gd")
const AutoPolicy = preload("res://src/combat/auto_policy.gd")
## P6.2-D : la géométrie de référence des tests est celle du tunnel de 6,5 m (variante A, coordonnées d'origine) ; le
## décalage des variantes (dont colisee.json) est vérifié par test_tunnel_variantes.
const ZONE := "res://data/p6/colisee_tunnel_A.json"
const ZONE_RETENUE := "res://data/p6/colisee.json"
const QUARTIER := "res://data/p6/quartier_initial.json"
const PNJ := "res://data/p6/pnj_colisee.json"
const DIALOGUES := "res://data/p6/dialogues_colisee.json"
const TUTO := "res://data/p6/tutoriel_colisee.json"
const MONSTRE := "res://data/combat/monster_commandant.json"
const GRID := 0.25
const CLES_HUD := ["initiative", "groupe", "actions", "description", "tempos", "confirmer", "pv_adversaire", "adversaire"]


func _json(p: String):
	return JSON.parse_string(FileAccess.open(p, FileAccess.READ).get_as_text())


## Monde logique + portes FERMÉES pour un état donné (mêmes règles que scenes/p6/colisee.gd : porte_ouverte).
func _monde(etat: String, file := ZONE):
	var w = World25.load_world(file, "instance")
	for p in w.adj["p6"].get("portes", []):
		var ouverte := true
		if p.has("fermee_a_partir_de"):
			ouverte = Progression.rang(etat) < Progression.rang(p["fermee_a_partir_de"])
		elif p.has("ouverte_a_partir_de"):
			ouverte = Progression.rang(etat) >= Progression.rang(p["ouverte_a_partir_de"])
		else:
			ouverte = p.get("marque", "") != "fermee"
		if not ouverte:
			var q: Array = p["rect"]
			w.solids.append({"id": p["id"], "kind": "rect", "rect": Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1]), "h0": 0.0, "h1": 2.6})
	return w


func _flood(w, start: Vector2) -> Dictionary:
	var seen := {}
	var q: Array = [start]
	seen[Vector2i(roundi(start.x / GRID), roundi(start.y / GRID))] = true
	while q.size() > 0:
		var cur: Vector2 = q.pop_back()
		for d in [Vector2(GRID, 0), Vector2(-GRID, 0), Vector2(0, GRID), Vector2(0, -GRID)]:
			var np: Vector2 = cur + d
			var k := Vector2i(roundi(np.x / GRID), roundi(np.y / GRID))
			if seen.has(k) or w.stand(np, 0.0).is_empty():
				continue
			seen[k] = true
			q.append(np)
	return seen


func _atteint(seen: Dictionary, p: Vector2) -> bool:
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			if seen.has(Vector2i(roundi(p.x / GRID) + dx, roundi(p.y / GRID) + dy)):
				return true
	return false


func test_zone_et_donnees() -> void:
	var w = World25.load_world(ZONE, "instance")
	check(not w.stand(Vector2(w.spawn.x, w.spawn.y), 0.0).is_empty(), "départ d'Aren tenable")
	check_eq(w.surface_at(Vector2(w.spawn.x, w.spawn.y), 0.0).get("id", ""), "vestiaires", "Aren démarre dans les vestiaires")
	check(w.triggers.size() == 1 and w.triggers[0]["id"] == "sortie_est", "une seule sortie : la sortie est")
	var p6: Dictionary = w.adj["p6"]
	for k in ["arene", "portes", "examens", "zones_nommees", "sols"]:
		check(p6.has(k), "section p6.%s présente" % k)
	# l'arène est ovale : le centre est praticable, les coins du rectangle sont fermés par le podium
	check(not w.stand(Vector2(26, 23), 0.0).is_empty(), "centre de l'arène praticable")
	var flood := _flood(_monde(Progression.TUTORIAL_COMPLETED), Vector2(26, 23))
	check(not _atteint(flood, Vector2(14.2, 14.6)), "coin nord-ouest du rectangle de l'arène inaccessible (podium ovale)")
	check(not _atteint(flood, Vector2(38.0, 31.6)), "coin sud-est du rectangle de l'arène inaccessible")
	var q = World25.load_world(QUARTIER, "instance")
	check(not q.stand(Vector2(q.spawn.x, q.spawn.y), 0.0).is_empty(), "arrivée dans le quartier tenable")
	check_eq(q.adj["p6"]["zone"], "quartier", "quartier : zone identifiée")


func test_acces_avant_tutoriel() -> void:
	var w = _monde(Progression.TUTORIAL_AVAILABLE)
	var f := _flood(w, Vector2(w.spawn.x, w.spawn.y))
	check(_atteint(f, Vector2(26, 41)), "avant : salle d'attente accessible")
	check(_atteint(f, Vector2(26, 23.5)), "avant : arène (devant le commandant) accessible")
	check(not _atteint(f, Vector2(50, 23)), "avant : coursive fermée (grille est baissée)")
	check(not _atteint(f, Vector2(62, 23)), "avant : sortie est inaccessible (impossible de quitter le Colisée)")
	check(not _atteint(f, Vector2(46.5, 38)), "avant : infirmerie inaccessible")
	check(not _atteint(f, Vector2(14.0, 51.6)), "avant : porte des vestiaires vers la rue fermée")


func test_acces_apres_tutoriel() -> void:
	var w = _monde(Progression.TUTORIAL_COMPLETED)
	var f := _flood(w, Vector2(26, 23.3))
	check(_atteint(f, Vector2(50, 23)), "après : coursive accessible")
	check(_atteint(f, Vector2(46.5, 38.5)), "après : infirmerie accessible")
	check(_atteint(f, Vector2(64.2, 23)), "après : sortie est accessible")
	check(_atteint(f, Vector2(26, 50)), "après : retour possible vers les vestiaires")
	check(not _atteint(f, Vector2(53, 37)), "après : réserve fermée")
	check(not _atteint(f, Vector2(50, 11)), "après : loge officielle fermée")
	check(not _atteint(f, Vector2(57.5, 16)), "après : accès aux gradins est fermé")


func test_quartier_retour_ferme() -> void:
	var w = _monde(Progression.COLISEUM_EXITED, QUARTIER)
	var f := _flood(w, Vector2(w.spawn.x, w.spawn.y))
	check(_atteint(f, Vector2(25.8, 8)), "quartier : la rue mène au panneau de la Guilde")
	check(not _atteint(f, Vector2(1.0, 8.0)), "quartier : retour au Colisée fermé après la sortie")


func test_pnj_et_dialogues() -> void:
	var pnj: Array = _json(PNJ)["pnj"]
	var dia: Dictionary = _json(DIALOGUES)["dialogues"]
	var w = World25.load_world(ZONE, "instance")
	var wq = World25.load_world(QUARTIER, "instance")
	var dsud: Dictionary = _json(ZONE_RETENUE)["ajustements"]["p6"]["decalage_sud"]
	var wr = World25.load_world(ZONE_RETENUE, "instance")
	var ids := {}
	for d in pnj:
		check(not ids.has(d["id"]), "PNJ %s : identifiant unique" % d["id"])
		ids[d["id"]] = true
		check(dia.has(d["dialogue"]), "PNJ %s : dialogue « %s » défini" % [d["id"], d["dialogue"]])
		var ww = wq if d["zone"] == "quartier" else w
		check(not ww.stand(Vector2(d["xy"][0], d["xy"][1]), 0.0).is_empty(), "PNJ %s : posé sur un sol libre" % d["id"])
		if d["zone"] != "quartier":
			var q := Vector2(d["xy"][0], d["xy"][1])
			if q.x >= dsud["x"][0] and q.x <= dsud["x"][1] and q.y >= dsud["y"]:
				q.y += float(dsud["dy"])
			check(not wr.stand(q, 0.0).is_empty(), "PNJ %s : posé sur un sol libre (tunnel retenu %s)" % [d["id"], dsud["tunnel"]])
		check(d.get("teinte", [1, 1, 1]) != [0.87, 0.79, 0.69], "PNJ %s : pas la silhouette d'Aren" % d["id"])
	for k in ["garde_vestiaires", "commandant", "chasseur_nerveux", "chasseuse_confiante", "chasseur_reussi", "chasseuse_echouee", "garde_gradins"]:
		check(ids.has(k), "PNJ attendu : " + k)
	for k in dia:
		var vs: Array = dia[k]
		check(vs.size() > 0 and vs[-1]["a_partir_de"] == Progression.INTRO_NOT_STARTED, "dialogue %s : une variante de repli" % k)
	# le commandant : choix de réponses (3) qui aboutissent tous au tutoriel
	var cmd: Dictionary = dia["commandant"][-1]
	check_eq(cmd.get("effet", ""), "lancer_tutoriel", "commandant : le dialogue lance le tutoriel")
	var choix_tous: Array = []
	for st in cmd["etapes"]:
		if st.has("choice"):
			choix_tous.append(st["choice"])
	check_eq(choix_tous.size(), 2, "commandant : deux moments de choix (réponse, puis commencer / passer)")
	var choix: Array = choix_tous[0]
	check_eq(choix.size(), 3, "commandant : trois réponses au choix")
	for c in choix:
		check(c["then"].size() >= 2, "réponse « %s » : réplique adaptée du commandant" % c["label"])
	var dec: Array = choix_tous[1]
	check(dec.size() == 2 and not dec[0].has("effet") and dec[1].get("effet", "") == "passer_tutoriel",
		"commandant : « Commencer l'entraînement » / « Passer le tutoriel » (effet passer_tutoriel)")
	check_eq(dia["garde_vestiaires"][-1].get("effet", ""), "consigne_arene", "garde des vestiaires : donne l'objectif")


func test_progression() -> void:
	var gs = Engine.get_main_loop().root.get_node_or_null("GameState")
	if gs == null:
		check(true, "GameState absent (exécution isolée)")
		return
	var sauve: Dictionary = gs.flags.duplicate()
	Progression.reinitialiser()
	check_eq(Progression.etat(), Progression.INTRO_NOT_STARTED, "état initial")
	Progression.definir(Progression.TUTORIAL_COMPLETED)
	Progression.definir(Progression.TUTORIAL_AVAILABLE)
	check_eq(Progression.etat(), Progression.TUTORIAL_COMPLETED, "l'état ne recule pas sans force")
	check(Progression.au_moins(Progression.TUTORIAL_IN_PROGRESS), "au_moins : ordre des états")
	check(not Progression.au_moins(Progression.COLISEUM_EXITED), "au_moins : état non atteint")
	Progression.definir(Progression.TUTORIAL_AVAILABLE, true)
	check_eq(Progression.etat(), Progression.TUTORIAL_AVAILABLE, "retour en arrière explicite (force)")
	Progression.definir_objectif("guilde_badge")
	check_eq(Progression.objectif_texte(), "Se rendre à la Guilde pour récupérer son badge", "objectif vers la Guilde")
	var snap: Dictionary = Progression.instantane()
	var relu = JSON.parse_string(JSON.stringify(snap))
	check_eq(relu, snap, "état sérialisable (sauvegarde)")
	gs.flags = sauve


func _combat_tuto():
	var data := BattleFactory.load_default_data()
	data["monster"] = BattleFactory.load_json(MONSTRE)
	return BattleFactory.create(data, ["heros"], {"potion": 2})


func test_commandant_ne_perd_pas_de_pv() -> void:
	var b = _combat_tuto()
	b.start()
	check_eq(b.hunters().size(), 1, "tutoriel : Aren seul dans le groupe")
	var mon = b.get_combatant("commandant")
	var h = b.get_combatant("heros")
	h.resonance = 100
	var cmds := [{"action": "attaque", "target": "commandant", "part": "heaume"},
		{"action": "technique", "mode": "CHARGE", "target": "commandant", "part": "plastron"},
		{"action": "serum_pulsation", "target": "commandant", "part": "bouclier"},
		{"action": "technique", "mode": "VIF", "target": "commandant", "part": "bouclier"}]
	for c in cmds:
		check_eq(b.submit(c), "", "commande acceptée : " + c["action"])
		check_eq(mon.hp, mon.max_hp, "le commandant ne perd pas de PV (%s)" % c["action"])
		for p in mon.parts:
			check(not p.broken, "aucune partie du commandant ne se brise")
	check(b.state != Battle.State.VICTORY, "pas de victoire ordinaire possible")


func test_tutoriel_imperdable() -> void:
	# déroulé du tutoriel : attaque, puis garde au moment de l'assaut annoncé ; fin au 3e tour
	var b = _combat_tuto()
	b.start()
	check_eq(b.submit({"action": "attaque", "target": "commandant", "part": "heaume"}), "", "tour 1 : attaque")
	var mon = b.get_combatant("commandant")
	check(mon.pending_cast != null and mon.pending_cast.telegraph, "tour 2 : l'assaut du commandant est annoncé")
	check(mon.pending_cast.resolve_at < b.now + b.get_combatant("heros").cycle(b.rules), "l'assaut frappe avant le tour suivant d'Aren")
	check_eq(b.submit({"action": "garde"}), "", "tour 2 : garde")
	var blocks: Array = b.journal.filter(func(e): return e["type"] == "guard_block")
	check_eq(blocks.size(), 1, "la garde absorbe l'assaut")
	var h = b.get_combatant("heros")
	check(h.hp >= h.max_hp * 0.6, "Aren garde plus de 60 %% de ses PV au 3e tour (%d / %d)" % [h.hp, h.max_hp])
	check(h.resonance >= 10, "la garde utile rapporte de la Résonance")
	# même sans jamais se garder, le joueur ne peut pas perdre pendant la durée du tutoriel (3 tours) ni bien au-delà
	var b2 = _combat_tuto()
	b2.start()
	for i in 6:
		b2.submit({"action": "attaque", "target": "commandant", "part": "heaume"})
	check(b2.get_combatant("heros").is_alive() and b2.state == Battle.State.AWAITING_COMMAND, "6 attaques sans garde : Aren tient toujours debout")


## P6.1 : imperdable PAR CONSTRUCTION (garde-fou appliqué avant chaque décision), sur une longue durée et quelles que
## soient les actions autorisées (attaque seule, technique chargée, garde, potions), et sans dépendre du schéma de l'IA.
func test_tutoriel_imperdable_garde_fou() -> void:
	var GardeFou = load("res://src/tutorial/garde_fou.gd")
	var jeux := [["attaque"], ["technique"], ["garde"], ["attaque", "technique", "garde", "potion"]]
	for jeu in jeux:
		var b = _combat_tuto()
		var base: int = b.get_combatant("commandant").attack
		b.start()
		for i in 60:
			GardeFou.borner(b, "heros", "commandant", base)
			var a: String = jeu[i % jeu.size()]
			var cmd := {"action": a}
			if a in ["attaque", "technique"]:
				cmd["target"] = "commandant"
				cmd["part"] = "heaume"
				if a == "technique":
					cmd["mode"] = "CHARGE"
			elif a == "potion":
				cmd["target"] = "heros"
			if b.submit(cmd) != "":
				b.submit({"action": "garde"})
			if b.state != Battle.State.AWAITING_COMMAND:
				break
		check(b.get_combatant("heros").is_alive() and b.state == Battle.State.AWAITING_COMMAND,
			"60 tours (%s) : Aren tient debout (%d PV)" % [",".join(PackedStringArray(jeu)), b.get_combatant("heros").hp])
		check_eq(b.get_combatant("commandant").hp, 500, "60 tours (%s) : commandant intact" % ",".join(PackedStringArray(jeu)))


## P6.2 — visibilité par secteurs (module réutilisable src/explore25/secteurs25.gd), sur les données du Colisée,
## caméra du Colisée (azimut 0°, plongée 24°).
func test_secteurs_visibilite() -> void:
	var Secteurs = load("res://src/explore25/secteurs25.gd")
	var yaw0: float = World25.yaw
	var p0: float = World25.pitch
	World25.yaw = 0.0
	World25.pitch = deg_to_rad(24.0)
	var z: Dictionary = _json(ZONE)
	var sc = Secteurs.new(z["ajustements"]["p6"]["secteurs"], "echelle")      # mode A (P6.2), conservé en comparaison
	check_eq(sc.secteur_en(Vector2(26, 51)), "S1", "vestiaires = S1")
	check_eq(sc.secteur_en(Vector2(26, 45.5)), "P12", "passage = P12")
	check_eq(sc.secteur_en(Vector2(26, 41)), "S2", "salle d'attente = S2")
	check_eq(sc.secteur_en(Vector2(26, 34)), "S3", "tunnel = S3")
	check_eq(sc.secteur_en(Vector2(26, 23)), "S4", "arène = zone ouverte S4 (P6.2-C : référence des coupes)")
	check_eq(sc.secteur_en(Vector2(50, 23)), "S6", "coursive = S6 (P6.2-D : Colisée complet)")
	check_eq(sc.secteur_en(Vector2(41, 23)), "S5", "tunnel est = S5")
	check_eq(sc.secteur_en(Vector2(60, 23)), "S9", "couloir de sortie = S9")
	check_eq(sc.secteur_en(Vector2(4, 4)), "EXT", "hors du bâtiment = reste du niveau")
	# murs : pivots déclarés depuis les données
	var murs := {}
	for o in z["ajustements"]["obstacles"]:
		if not str(o["id"]).begins_with("cmur_"):
			continue
		var pv := Node3D.new()
		pv.name = o["id"]
		var q: Array = o["rect"]
		var cp := Node3D.new()
		pv.add_child(cp)
		sc.declarer_mur(pv, cp, Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1]), 0.0, float(o["haut"]))
		murs[o["id"]] = pv
	sc.mettre_a_jour(Vector2(26, 51), true)
	var c1: Array = sc.murs_coupes()
	check(c1.has("cmur_vestiaires_s0"), "vestiaires : mur sud (premier plan) coupé")
	check(not c1.any(func(n): return str(n).begins_with("cmur_vestiaires_n") or str(n).begins_with("cmur_vestiaires_o") or str(n).begins_with("cmur_vestiaires_e")),
		"vestiaires : murs du fond et des côtés entiers")
	check(murs["cmur_vestiaires_n0"].scale.y == 1.0, "vestiaires : mur du fond pleine hauteur")
	sc.mettre_a_jour(Vector2(26, 41), true)
	var c2: Array = sc.murs_coupes()
	check(c2.has("cmur_salle_attente_s0") and c2.has("cmur_vestiaires_n0") and c2.has("cmur_vestiaires_n1"),
		"salle : murs qui la cachent coupés (son mur sud, mur nord des vestiaires)")
	check(not c2.any(func(n): return str(n).begins_with("cmur_salle_attente_n") or str(n).begins_with("cmur_salle_attente_o") or str(n).begins_with("cmur_salle_attente_e")),
		"salle : murs du fond et des côtés entiers")
	check(is_equal_approx(murs["cmur_salle_attente_s0"].scale.y, Secteurs.LIP / 1.0) and is_equal_approx(murs["cmur_vestiaires_n0"].scale.y, Secteurs.LIP / 3.0),
		"murs coupés réduits au muret de 0,5 m (collision non concernée)")
	sc.mettre_a_jour(Vector2(4, 4), true)
	check(sc.murs_coupes().is_empty(), "hors du bâtiment : aucun mur coupé (comportement P6.1)")
	# groupes de visibilité
	var racine := Node3D.new()
	var mk := func(p: Vector2, meta := {}) -> Node3D:
		var n := Node3D.new()
		n.set_meta("xz", p)
		for k in meta:
			n.set_meta(k, meta[k])
		racine.add_child(n)
		return n
	var deco_s1: Node3D = mk.call(Vector2(26, 51))
	var deco_s2: Node3D = mk.call(Vector2(26, 41))
	var mur_vest_n: Node3D = mk.call(Vector2(20.05, 46.3), {"mur": true})
	var mur_passage: Node3D = mk.call(Vector2(24.3, 45.5), {"mur": true})
	var arene: Node3D = mk.call(Vector2(26, 23))
	var exterieur: Node3D = mk.call(Vector2(70, 10))
	var poutre_s1: Node3D = mk.call(Vector2(26, 46.46), {"secteur": "S1"})
	sc.classer(null, racine)
	var vis := func(n: Node3D) -> bool: return n.get_parent().visible
	sc.mettre_a_jour(Vector2(26, 51), true)
	check(vis.call(deco_s1) and not vis.call(deco_s2), "depuis les vestiaires : la salle n'est pas affichée")
	check(not vis.call(arene) and not vis.call(exterieur), "depuis les vestiaires : ni l'arène ni l'extérieur")
	sc.mettre_a_jour(Vector2(26, 41), true)
	check(vis.call(deco_s2) and not vis.call(deco_s1), "depuis la salle : les vestiaires ne sont pas affichés")
	check(not vis.call(poutre_s1), "décor attribué aux vestiaires masqué depuis la salle (poutre, bannières)")
	check(not vis.call(mur_vest_n), "depuis la salle : mur nord des vestiaires masqué (il cachait la salle en P6.1)")
	check(vis.call(mur_passage), "depuis la salle : mur latéral du passage conservé (frontière passage / vestiaires)")
	check(not vis.call(arene) and not vis.call(exterieur), "depuis la salle : ni l'arène ni l'extérieur")
	sc.mettre_a_jour(Vector2(26, 34), true)
	check(vis.call(arene), "depuis le tunnel : l'arène se révèle")
	check(sc.camera_rect() == Rect2(), "tunnel : pas de limite de caméra propre")
	sc.mettre_a_jour(Vector2(26, 51), true)
	check(sc.camera_rect() == Rect2(16, 46.5, 20, 8.5), "vestiaires : limites de caméra = la pièce")
	check_eq(sc.fond(), "sombre", "vestiaires : fond intérieur sombre")
	racine.free()
	for k in murs:
		murs[k].free()
	World25.yaw = yaw0
	World25.pitch = p0


## P6.2-B — mode B « continu » : architecture persistante, aucune pièce derrière masquée, pièces devant estompées,
## arène révélée selon la position, seuil stable, éléments à cheval sur deux pièces.
func test_secteurs_continu() -> void:
	var Secteurs = load("res://src/explore25/secteurs25.gd")
	var yaw0: float = World25.yaw
	var p0: float = World25.pitch
	World25.yaw = 0.0
	World25.pitch = deg_to_rad(24.0)
	var z: Dictionary = _json(ZONE)
	var sc = Secteurs.new(z["ajustements"]["p6"]["secteurs"], "continu")
	check_eq(sc.mode, "continu", "mode B par défaut du Colisée")
	var racine := Node3D.new()
	var mk := func(p: Vector2, meta := {}) -> Node3D:
		var n := Node3D.new()
		n.set_meta("xz", p)
		for k in meta:
			n.set_meta(k, meta[k])
		racine.add_child(n)
		return n
	var deco_s1: Node3D = mk.call(Vector2(26, 51), {"secteur": "S1"})
	var deco_s2: Node3D = mk.call(Vector2(26, 41), {"secteur": "S2"})
	var mur_vest: Node3D = mk.call(Vector2(20, 46.3), {"mur": true})
	var arene: Node3D = mk.call(Vector2(26, 23))
	var ext: Node3D = mk.call(Vector2(70, 10), {"exterieur": true})
	# élément à cheval sur la salle et le passage (emprise) : appartient aux deux
	var banc := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1, 0.4, 3)
	banc.mesh = bm
	banc.position = Vector3(26, 0.2, 44.5)
	racine.add_child(banc)
	sc.classer(null, racine)
	var vis := func(n: Node3D) -> bool: return n.get_parent().visible
	sc.mettre_a_jour(Vector2(26, 51), true)
	check(vis.call(deco_s2), "B, vestiaires : la salle (derrière) reste rendue, cachée par les murs hauts")
	check(not vis.call(ext), "B, vestiaires : l'extérieur est masqué")
	check(vis.call(mur_vest), "B : les murs ne sont jamais masqués")
	sc.regler_voile_ext(sc.voile_ext_pour(Vector2(26, 51)))
	check(not vis.call(arene), "B, vestiaires : l'arène est voilée")
	sc.mettre_a_jour(Vector2(26, 41), true)
	check(not vis.call(deco_s1), "B, salle : les vestiaires (devant, côté caméra) sont estompés")
	check(vis.call(mur_vest), "B, salle : le mur des vestiaires reste (muret)")
	check(vis.call(banc), "B : élément à cheval sur deux pièces conservé")
	check(sc.traverses.size() >= 1, "B : éléments à cheval sur plusieurs secteurs relevés (%d)" % sc.traverses.size())
	# P6.2-C : plus aucune révélation depuis la salle ; dans le tunnel, l'arène n'est vue qu'à travers sa bouche (masque de
	# lignes de vue de la scène, testé dans test_vue_tunnel)
	for y in [44.0, 41.0, 38.0]:
		check(sc.voile_ext_pour(Vector2(26, y)) == 1.0, "B, salle (y %.0f) : arène masquée" % y)
	sc.mettre_a_jour(Vector2(26, 34), true)
	check(sc.voile_ext_pour(Vector2(26, 34)) == 0.0, "B, tunnel : arène rendue (vue limitée par la bouche)")
	sc.regler_voile_ext(0.5)
	sc.regler_voile_ext(0.0013)
	check(sc.voile_ext == 0.0, "voile : extrémité exacte (pas de résidu laissant l'arène en passe transparente)")
	# arène S4 : les murs du bâtiment devant (salle, linteaux) perdent leur partie haute ; jamais ceux du tunnel
	sc.mettre_a_jour(Vector2(26, 28), true)
	check_eq(sc.actif, "S4", "arène active (zone ouverte)")
	check_eq(sc.voile_ext_pour(Vector2(26, 28)), 0.0, "arène : visible")
	check(sc.a_ciel_ouvert(), "arène : ciel ouvert")
	var sc2 = Secteurs.new(_json(ZONE)["ajustements"]["p6"]["secteurs"], "continu")
	var murs_t := {}
	for d in [["salle_nord", Rect2(19.6, 37.1, 4.9, 0.4), 6.0, false], ["tunnel_o", Rect2(24.1, 32.0, 0.4, 5.5), 3.1, true],
			["arc_bouche", Rect2(24.1, 31.6, 3.8, 0.4), 3.1, true]]:
		var pv := Node3D.new()
		pv.name = d[0]
		var cp := MeshInstance3D.new()
		pv.add_child(cp)
		var haut := MeshInstance3D.new()
		pv.add_child(haut)
		sc2.declarer_mur(pv, cp, d[1], 2.3 if d[0] == "arc_bouche" else 0.0, d[2], [haut], null, d[3])
		murs_t[d[0]] = pv
	sc2.mettre_a_jour(Vector2(26, 28), true)
	var cc: Array = sc2.murs_coupes()
	check(cc.has("salle_nord"), "arène : mur nord de la salle coupé (%s)" % str(cc))
	check(not cc.has("tunnel_o") and not cc.has("arc_bouche"), "arène : murs et arc du tunnel entiers (P6.2-D : trouée locale si l'arc passe devant Aren)")
	sc2.mettre_a_jour(Vector2(26, 34.7), true)
	cc = sc2.murs_coupes()
	check(cc.has("salle_nord") and not cc.has("tunnel_o") and not cc.has("arc_bouche"), "tunnel : mur de la salle coupé, murs et arc du tunnel entiers (%s)" % str(cc))
	for k in murs_t:
		murs_t[k].free()
	# stabilité au seuil : depuis le passage, un petit pas dans la porte des vestiaires ne rebascule pas
	sc.mettre_a_jour(Vector2(26, 45.5), true)
	check_eq(sc.actif, "P12", "passage actif")
	sc.mettre_a_jour(Vector2(26, 46.7))
	check_eq(sc.actif, "P12", "stabilité : à 0,2 m dans les vestiaires, le passage reste actif")
	sc.mettre_a_jour(Vector2(26, 47.2))
	check_eq(sc.actif, "S1", "au-delà de la zone de stabilité : vestiaires")
	racine.free()
	World25.yaw = yaw0
	World25.pitch = p0


func test_etapes_du_tutoriel() -> void:
	var t: Dictionary = _json(TUTO)
	var hunters: Dictionary = BattleFactory.load_json("res://data/combat/hunters.json")
	var actions: Array = hunters["hunters"][0]["actions"]
	var vues := {}
	var tours := []
	for e in t["etapes"]:
		for c in e.get("cibles", []):
			check(CLES_HUD.has(c), "étape %s : cible d'interface connue (%s)" % [e["id"], c])
		for a in e.get("actions", []):
			check(actions.has(a), "étape %s : action réellement disponible (%s)" % [e["id"], a])
		vues[e["id"]] = true
		tours.append(int(e["tour"]))
	for k in ["initiative", "actions", "ciblage", "attaque", "garde", "fin"]:
		check(vues.has(k), "étape attendue : " + k)
	var trie: Array = tours.duplicate()
	trie.sort()
	check_eq(tours, trie, "étapes dans l'ordre des tours")
	check(t["etapes"][-1].get("fin", false), "la dernière étape clôt le tutoriel")


## P6.2-D : variantes de longueur du tunnel sud (A 6,5 m, B 8,5 m, C 9,5 m) : bloc sud décalé d'un seul tenant.
func test_tunnel_variantes() -> void:
	var a: Dictionary = _json("res://data/p6/colisee_tunnel_A.json")
	var pa: Dictionary = a["ajustements"]["p6"]
	for v in [["B", 2.0], ["C", 3.0]]:
		var z: Dictionary = _json("res://data/p6/colisee_tunnel_%s.json" % v[0])
		var pz: Dictionary = z["ajustements"]["p6"]
		check_eq(float(pz["decalage_sud"]["dy"]), v[1], "%s : décalage du bloc sud" % v[0])
		for i in 3:
			var ra: Array = pa["secteurs"][i]["rects"][0]
			var rz: Array = pz["secteurs"][i]["rects"][0]
			check(is_equal_approx(rz[1] - ra[1], v[1]) and is_equal_approx(rz[3] - ra[3], v[1]), "%s : pièce %s décalée d'un bloc" % [v[0], pz["secteurs"][i]["id"]])
		var t: Array = pz["secteurs"][3]["rects"][0]
		check(is_equal_approx(t[1], 32.0) and is_equal_approx(t[3] - t[1], 5.5 + v[1]), "%s : tunnel étiré, bouche inchangée" % v[0])
		check(is_equal_approx(float(pz["vue_tunnel"]["entree"]), 37.5 + v[1]), "%s : entrée du tunnel dans la vue" % v[0])
		var w = World25.load_world("res://data/p6/colisee_tunnel_%s.json" % v[0], "instance")
		check(not w.stand(Vector2(26.0, 51.0 + v[1]), 0.0).is_empty() and not w.stand(Vector2(26.0, 34.0 + v[1]), 0.0).is_empty(),
			"%s : vestiaires et tunnel praticables" % v[0])
		var e: Dictionary = z["ajustements"]["entree"]
		check(is_equal_approx(float(e["xy"][1]), 50.6 + v[1]), "%s : départ dans les vestiaires décalés" % v[0])
	check_eq(str(_json(ZONE_RETENUE)["ajustements"]["p6"]["decalage_sud"]["tunnel"]), "B", "colisee.json = tunnel retenu (B, 8,5 m)")


## P6.2-D : règles étendues au Colisée complet (mode B).
func test_colisee_complet() -> void:
	var Secteurs = load("res://src/explore25/secteurs25.gd")
	var yaw0: float = World25.yaw
	World25.yaw = 0.0                   # azimut du Colisée
	var sc = Secteurs.new(_json(ZONE)["ajustements"]["p6"]["secteurs"], "continu")
	var racine := Node3D.new()
	var mk := func(p: Vector2, meta := {}) -> Node3D:
		var n := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.6, 0.6, 0.6)
		n.mesh = bm
		n.position = Vector3(p.x, 0.3, p.y)
		for k in meta:
			n.set_meta(k, meta[k])
		racine.add_child(n)
		return n
	var reserve: Node3D = mk.call(Vector2(52, 38))
	var salle: Node3D = mk.call(Vector2(26, 41))
	var arene: Node3D = mk.call(Vector2(26, 20))
	sc.plafonds(racine, 6.1)
	sc.classer(null, racine)
	var vis := func(n: Node3D) -> bool: return n.get_parent().visible
	sc.mettre_a_jour(Vector2(46.6, 38), true)
	check_eq(sc.actif, "S7", "infirmerie active")
	check(not vis.call(reserve), "infirmerie : la réserve voisine (sur le côté, fermée) n'est pas rendue")
	sc.mettre_a_jour(Vector2(26, 51), true)
	check(vis.call(salle), "vestiaires : la salle, entièrement derrière, reste rendue (cachée par le mur du fond)")
	sc.mettre_a_jour(Vector2(26, 24), true)
	check(sc.toits_visibles().has("S6") and sc.toits_visibles().has("S9"), "arène : coursive et sortie couvertes d'un toit (%s)" % str(sc.toits_visibles()))
	check(not sc.toits_visibles().has("S5"), "arène : le tunnel est (voisin en vue) n'a pas de toit")
	check(not sc.toits_visibles().has("S2") and not sc.toits_visibles().has("S1"), "arène : pas de toit sur les pièces situées devant")
	sc.mettre_a_jour(Vector2(50, 23), true)
	check(sc.toits_visibles().is_empty(), "coursive : aucun toit affiché depuis un intérieur")
	var v0: float = sc.voile_ext_pour(Vector2(44.3, 23))
	var v1: float = sc.voile_ext_pour(Vector2(45.5, 23))
	var v2: float = sc.voile_ext_pour(Vector2(48, 23))
	check(v0 < 0.1 and v1 > 0.2 and v1 < 0.8 and v2 == 1.0, "coursive : l'arène s'efface selon la distance au tunnel est (%.2f / %.2f / %.2f)" % [v0, v1, v2])
	sc.mettre_a_jour(Vector2(41, 23), true)
	check_eq(sc.voile_ext_pour(Vector2(41, 23)), 0.0, "tunnel est : l'arène reste en vue")
	check(is_instance_valid(arene), "arène classée")
	racine.free()
	World25.yaw = yaw0
