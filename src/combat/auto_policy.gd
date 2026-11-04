extends RefCounted
## Politique de jeu automatique, simple et déterministe — pour les tests, la démo console et la démo vidéo.
## Ce n'est PAS une IA de compagnon du jeu final.


## Joue un combat complet. `style` : "normal" ou "serum_spam" (sérum dès que possible).
static func play(b, style := "normal", max_turns := 500) -> int:
	if b.journal.is_empty():
		b.start()
	var turns := 0
	while not b.is_over() and turns < max_turns:
		turns += 1
		var err: String = b.submit(choose(b, style))
		if err != "":
			b.submit({"action": "garde"})
	return turns


static func choose(b, style := "normal") -> Dictionary:
	var a = b.current_actor
	var mon = b.monsters(true)[0]
	if a.hp * 100 < a.max_hp * 40 and int(b.inventory.get("potion", 0)) > 0:
		return {"action": "potion", "target": a.id}
	if a.resonance >= 30:
		return {"action": "serum_pulsation", "target": mon.id, "part": best_part(mon, "aether")}
	if style == "serum_spam":
		return {"action": "attaque", "target": mon.id, "part": best_part(mon, a.damage_type)}
	var tele = mon.pending_cast if (mon.pending_cast != null and mon.pending_cast.telegraph) else null
	if tele != null:
		var glande = mon.get_part("glande")
		if glande != null and not glande.broken:
			var cmd := {"action": "technique", "mode": "VIF", "target": mon.id, "part": "glande"}
			var est: Dictionary = b.estimate(a, cmd)
			if est["resolve_at"] < tele.resolve_at and est["break"] >= glande.integrity:
				return cmd
		return {"action": "garde"}
	if a.decisions % 2 == 0:
		return {"action": "technique", "mode": "MESURE", "target": mon.id, "part": best_part(mon, a.damage_type)}
	return {"action": "attaque", "target": mon.id, "part": best_part(mon, a.damage_type)}


## Partie non brisée la plus sensible au type de dégâts (sinon la première).
static func best_part(mon, damage_type: String) -> String:
	var best = null
	for p in mon.parts:
		if p.broken:
			continue
		if best == null or p.affinity(damage_type) > best.affinity(damage_type):
			best = p
	return best.id if best != null else mon.parts[0].id
