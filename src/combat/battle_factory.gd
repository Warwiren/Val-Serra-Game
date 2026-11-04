extends RefCounted
## Charge les fichiers JSON de data/combat/ et construit un combat prêt à démarrer.
## Les nombres JSON sont lus comme des décimaux : on les convertit explicitement en entiers.

const Battle = preload("res://src/combat/core/battle.gd")
const Combatant = preload("res://src/combat/core/combatant.gd")
const MonsterPart = preload("res://src/combat/core/monster_part.gd")

const DATA_DIR := "res://data/combat/"


static func load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Fichier introuvable : %s" % path)
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("JSON invalide : %s" % path)
		return {}
	return parsed


## Toutes les données par défaut du prototype.
static func load_default_data() -> Dictionary:
	return {
		"rules": load_json(DATA_DIR + "rules.json"),
		"actions": load_json(DATA_DIR + "actions.json"),
		"hunters": load_json(DATA_DIR + "hunters.json"),
		"monster": load_json(DATA_DIR + "monster_vorgane.json"),
	}


## Combat par défaut : 3 Chasseurs contre le monstre de test, 2 potions.
static func create_default(inventory := {"potion": 2}) -> Battle:
	var data := load_default_data()
	return create(data, ["heros", "compagnon_vif", "compagnon_lourd"], inventory)


## Construit un combat (non démarré : appeler battle.start()).
static func create(data: Dictionary, party_ids: Array, inventory: Dictionary) -> Battle:
	var b := Battle.new()
	b.rules = data["rules"]
	b.actions = _strip_notes(data["actions"])
	b.inventory = inventory.duplicate()
	var hdb: Dictionary = data["hunters"]
	var index := 0
	for hid in party_ids:
		var hdef := _find_hunter(hdb, hid)
		if hdef.is_empty():
			push_error("Chasseur inconnu : %s" % hid)
			continue
		b.combatants.append(make_hunter(b.rules, hdef, hdb["weapons"], hdb["armors"], index))
		index += 1
	var mdef: Dictionary = data["monster"]
	b.combatants.append(make_monster(mdef, index))
	b.monster_rewards = mdef.get("rewards", {})
	return b


static func make_hunter(rules: Dictionary, hdef: Dictionary, weapons: Dictionary, armors: Dictionary, index: int) -> Combatant:
	var c := Combatant.new()
	var d: Dictionary = rules["derived"]
	var w: Dictionary = weapons[hdef["weapon"]]
	var a: Dictionary = armors[hdef["armor"]]
	c.id = hdef["id"]
	c.name = hdef["name"]
	c.team = Combatant.TEAM_HUNTERS
	c.index = index
	c.stats = _int_dict(hdef["stats"])
	c.max_hp = int(d["hp_base"]) + int(d["hp_per_con"]) * int(c.stats["CON"])
	c.hp = c.max_hp
	c.defense = int(a["defense"])
	c.base_speed = int(d["speed_base"]) + int(d["speed_per_dex"]) * int(c.stats["DEX"]) \
		+ int(w["speed_bonus"]) + int(a["speed_bonus"])
	c.weapon_name = w["name"]
	c.attack = int(w["attack"])
	c.break_power = int(w["break_power"])
	c.damage_type = w["damage_type"]
	c.stat_weights = w["stat_weights"]
	c.action_ids = hdef["actions"]
	return c


static func make_monster(mdef: Dictionary, index: int) -> Combatant:
	var m := Combatant.new()
	m.id = mdef["id"]
	m.name = mdef["name"]
	m.team = Combatant.TEAM_MONSTERS
	m.index = index
	m.is_boss = bool(mdef.get("is_boss", false))
	m.stats = _int_dict(mdef["stats"])
	m.max_hp = int(mdef["hp"])
	m.hp = m.max_hp
	m.defense = int(mdef["defense"])
	m.base_speed = int(mdef["speed"])
	m.attack = int(mdef["attack"])
	m.stat_weights = mdef.get("stat_weights", {"FOR": 1.0})
	m.resistances = mdef.get("resistances", {})
	m.monster_actions = _strip_notes(mdef["actions"])
	m.ai = mdef["ai"]
	for pdef in mdef["parts"]:
		var p := MonsterPart.new()
		p.id = pdef["id"]
		p.name = pdef["name"]
		p.max_integrity = int(pdef["integrity"])
		p.integrity = p.max_integrity
		p.affinities = pdef.get("affinities", {})
		p.break_effect = pdef.get("break_effect", {})
		p.loot = pdef.get("loot", "")
		m.parts.append(p)
	return m


static func _find_hunter(hdb: Dictionary, hid: String) -> Dictionary:
	for h in hdb["hunters"]:
		if h["id"] == hid:
			return h
	return {}


static func _int_dict(src: Dictionary) -> Dictionary:
	var out := {}
	for k in src:
		out[k] = int(src[k])
	return out


## Retire les clés de commentaire ("_note") d'un dictionnaire de définitions.
static func _strip_notes(src: Dictionary) -> Dictionary:
	var out := {}
	for k in src:
		if not String(k).begins_with("_"):
			out[k] = src[k]
	return out
