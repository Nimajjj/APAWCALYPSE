extends Node
## Store central et PERSISTANT de toutes les stats du jeu (global, persos, armes,
## ennemis). Les valeurs par defaut sont lues une fois dans les scenes ; les
## overrides edites via le panel web sont appliques EN DIRECT et sauvegardes dans
## user://balance_overrides.json (rechargees au demarrage).
##
## Structure : categories "global", "player:<id>", "weapon:<id>", "enemy:<id>".
## Effectif = override si present, sinon defaut.

const SAVE_PATH := "user://balance_overrides.json"

const PLAYERS := ["candy", "blade", "grey", "bada-boom"]
const WEAPONS := ["pistol", "ak47", "mp5", "shotgun", "sniper", "machinegun"]
const ENEMIES := ["zombie", "woman_zombie", "buffed_zombie", "big_zombie", "miser", "reaper", "runner", "brute", "charger", "exploder"]

# [propriete, libelle, min, max, pas, est_entier]
const PLAYER_FIELDS := [
	["speed", "Vitesse", 1000.0, 30000.0, 250.0, false],
	["max_health", "Vie max", 50.0, 1000.0, 10.0, false],
	["acceleration", "Acceleration", 0.05, 1.0, 0.01, false],
	["friction", "Friction", 0.0, 1.0, 0.01, false],
	["regeneration", "Regeneration", 0.0, 50.0, 1.0, false],
	["money", "Argent depart", 0.0, 5000.0, 50.0, true],
]
const WEAPON_FIELDS := [
	["damage", "Degats", 1.0, 1000.0, 1.0, true],
	["mag_capacity", "Chargeur", 1.0, 500.0, 1.0, true],
	["fire_rate", "Cadence (s)", 0.02, 2.0, 0.01, false],
	["reload_time", "Recharge (s)", 0.1, 6.0, 0.1, false],
	["fire_range", "Portee tir (px)", 40.0, 600.0, 5.0, false],
	["weapon_range", "Portee balle", 0.1, 60.0, 0.1, false],
	["bullet_scale", "Taille balle", 0.3, 5.0, 0.1, false],
	["spread", "Dispersion", 0.0, 1.0, 0.01, false],
	["shake_power", "Shake", 0.0, 3.0, 0.05, false],
	["weapon_size", "Taille arme", 0.3, 4.0, 0.05, false],
]
const ENEMY_FIELDS := [
	["max_health", "Vie", 10.0, 10000.0, 10.0, true],
	["speed", "Vitesse", 100.0, 8000.0, 50.0, true],
	["money", "Argent", 0.0, 500.0, 1.0, true],
	["damage", "Degats", 0.0, 500.0, 1.0, true],
]
# Stats des capacites (categorie "abilities"). Valeurs absolues, pas de scene.
const ABILITY_FIELDS := [
	["dash_distance", "Dash — distance", 80.0, 500.0, 10.0, false],
	["dash_cooldown", "Dash — cooldown (s)", 1.0, 30.0, 0.5, false],
	["fire_cooldown", "Feu — cooldown (s)", 1.0, 30.0, 0.5, false],
	["fire_duration", "Feu — duree (s)", 1.0, 12.0, 0.5, false],
	["fire_damage", "Feu — degats/tick", 5.0, 300.0, 5.0, true],
	["fire_tick", "Feu — interv. tick (s)", 0.1, 1.0, 0.05, false],
	["fire_radius", "Feu — rayon", 30.0, 160.0, 5.0, false],
]
const ABILITY_DEFAULTS := {
	"dash_distance": 230.0, "dash_cooldown": 15.0,
	"fire_cooldown": 15.0, "fire_duration": 4.0, "fire_damage": 45.0,
	"fire_tick": 0.3, "fire_radius": 56.0,
}

var defaults: Dictionary = {}
var overrides: Dictionary = {}


func _ready() -> void:
	_build_defaults()
	_load_overrides()
	# Applique les overrides "global" a Balance (les entites ne sont pas encore
	# spawnees, donc rien d'autre a propager au demarrage).
	if overrides.has("global"):
		for k in overrides["global"].keys():
			Balance.set_v(k, float(overrides["global"][k]))


# ---------------------------------------------------------------------------
# Lecture des valeurs par defaut depuis les scenes
# ---------------------------------------------------------------------------
func _build_defaults() -> void:
	defaults["global"] = {}
	for k in Balance.DEFS.keys():
		defaults["global"][k] = Balance.DEFS[k][0]

	for id in PLAYERS:
		defaults["player:" + id] = _read_fields("res://scenes/player/%s.tscn" % id, PLAYER_FIELDS)
	for id in WEAPONS:
		defaults["weapon:" + id] = _read_fields("res://scenes/weapon/%s.tscn" % id, WEAPON_FIELDS)
	for id in ENEMIES:
		defaults["enemy:" + id] = _read_fields("res://scenes/enemy/%s.tscn" % id, ENEMY_FIELDS)

	defaults["abilities"] = ABILITY_DEFAULTS.duplicate()


func _read_fields(path: String, fields: Array) -> Dictionary:
	var out: Dictionary = {}
	var res := load(path) as PackedScene
	if res == null:
		return out
	var n: Node = res.instantiate()
	for f in fields:
		var prop: String = f[0]
		if prop == "weapon_size":
			out[prop] = float((n as Node2D).scale.x)
		else:
			out[prop] = float(n.get(prop))
	n.free()
	return out


# ---------------------------------------------------------------------------
# Acces / mutation
# ---------------------------------------------------------------------------
func effective(cat: String, field: String) -> float:
	if overrides.has(cat) and overrides[cat].has(field):
		return float(overrides[cat][field])
	if defaults.has(cat) and defaults[cat].has(field):
		return float(defaults[cat][field])
	return 0.0


## Modifie une valeur et l'applique immediatement aux entites concernees. Ne
## sauvegarde PAS sur disque (appeler save() pour rendre permanent).
func set_value(cat: String, field: String, value: float) -> void:
	if not overrides.has(cat):
		overrides[cat] = {}
	overrides[cat][field] = value
	_apply_live(cat, field, value)


func _apply_live(cat: String, field: String, value: float) -> void:
	if cat == "global":
		Balance.set_v(field, value)
	elif cat.begins_with("weapon:"):
		var id := cat.substr(7)
		var w := _current_weapon()
		if w != null and w.config_id == id:
			_set_weapon_field(w, field, value)
	elif cat.begins_with("enemy:"):
		var id := cat.substr(6)
		for e in Global.units:
			if e != null and is_instance_valid(e) and not e.dead and _scene_id(e) == id:
				_set_enemy_field(e, field, value)
	elif cat.begins_with("player:"):
		var id := cat.substr(7)
		for p in Global.players:
			if p != null and is_instance_valid(p) and _scene_id(p) == id:
				_set_player_field(p, field, value)
	elif cat == "abilities":
		for p in Global.players:
			if p != null and is_instance_valid(p):
				apply_abilities(p)


# ---------------------------------------------------------------------------
# Application aux entites (au spawn)
# ---------------------------------------------------------------------------
func apply_player(p: IPlayer) -> void:
	var cat := "player:" + _scene_id(p)
	if not defaults.has(cat):
		return
	for f in PLAYER_FIELDS:
		var v := effective(cat, f[0])
		p.set(f[0], int(v) if f[5] else v)


func apply_weapon(w: IWeapon) -> void:
	if w.config_id == "":
		return
	var cat := "weapon:" + w.config_id
	if not defaults.has(cat):
		return
	for f in WEAPON_FIELDS:
		var v := effective(cat, f[0])
		if f[0] == "weapon_size":
			w.set_display_scale(v)
		elif f[5]:
			w.set(f[0], int(v))
		else:
			w.set(f[0], v)


## Stats des capacites du joueur (dash + reglages de cooldown du cercle de feu).
func apply_abilities(p: IPlayer) -> void:
	p.dash_distance = effective("abilities", "dash_distance")
	p.dash_cooldown = effective("abilities", "dash_cooldown")
	p.fire_ring_cooldown = effective("abilities", "fire_cooldown")


func apply_enemy(e: IEnemy) -> void:
	var cat := "enemy:" + _scene_id(e)
	if not defaults.has(cat):
		return
	for f in ENEMY_FIELDS:
		e.set(f[0], int(effective(cat, f[0])))


# ---------------------------------------------------------------------------
# Application live a une entite deja en jeu
# ---------------------------------------------------------------------------
func _set_weapon_field(w: IWeapon, field: String, value: float) -> void:
	if field == "weapon_size":
		w.set_display_scale(value)
		return
	if field in ["damage", "mag_capacity", "accuracy"]:
		w.set(field, int(value))
	else:
		w.set(field, value)
	if field == "fire_rate":
		w.fire_rate_timer.wait_time = w.fire_rate * Balance.get_v("weapon_fire_rate")


func _set_enemy_field(e: IEnemy, field: String, value: float) -> void:
	var iv := int(value)
	e.set(field, iv)
	# Synchronise la base (pour rester coherent avec les multiplicateurs Balance).
	if field == "max_health":
		e._base_max_health = iv
		e.HealthBar.max_value = iv
		e.health = min(e.health, iv)
		e.HealthBar.value = e.health
	elif field == "speed":
		e._base_speed = iv
		e.speed_stock = iv
	elif field == "damage":
		e._base_damage = iv
	elif field == "money":
		e._base_money = iv


func _set_player_field(p: IPlayer, field: String, value: float) -> void:
	if field == "speed":
		p._base_speed = value
		p.apply_balance()
	elif field == "max_health":
		p._base_max_health = value
		p.apply_balance()
	else:
		p.set(field, int(value) if field == "money" else value)


# ---------------------------------------------------------------------------
# Persistance
# ---------------------------------------------------------------------------
func save() -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("GameConfig: sauvegarde impossible (%s)" % SAVE_PATH)
		return false
	f.store_string(JSON.stringify(overrides, "\t"))
	f.close()
	return true


func _load_overrides() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if parsed is Dictionary:
		overrides = parsed


# ---------------------------------------------------------------------------
# Etat pour le panel web
# ---------------------------------------------------------------------------
func get_state() -> Dictionary:
	var cats: Array = []
	cats.append(_cat_state("global", "Global / multiplicateurs", _global_specs()))
	cats.append(_cat_state("abilities", "Capacites", ABILITY_FIELDS))
	for id in PLAYERS:
		cats.append(_cat_state("player:" + id, "Perso — " + id, PLAYER_FIELDS))
	for id in WEAPONS:
		cats.append(_cat_state("weapon:" + id, "Arme — " + id, WEAPON_FIELDS))
	for id in ENEMIES:
		cats.append(_cat_state("enemy:" + id, "Ennemi — " + id, ENEMY_FIELDS))
	return {"categories": cats}


func _global_specs() -> Array:
	var out: Array = []
	for k in Balance.DEFS.keys():
		var d: Array = Balance.DEFS[k]
		out.append([k, d[4], d[1], d[2], d[3], false])
	return out


func _cat_state(cat: String, label: String, fields: Array) -> Dictionary:
	var arr: Array = []
	for f in fields:
		arr.append({
			"key": f[0], "label": f[1], "min": f[2], "max": f[3], "step": f[4],
			"value": effective(cat, f[0]),
		})
	return {"id": cat, "label": label, "fields": arr}


# ---------------------------------------------------------------------------
func _scene_id(node: Node) -> String:
	var path: String = node.scene_file_path
	if path == "":
		return ""
	return path.get_file().get_basename()


func _current_weapon() -> IWeapon:
	if Global.players.is_empty():
		return null
	return Global.players[0].weapon
