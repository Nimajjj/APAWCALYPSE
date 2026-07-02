extends Node
## Systeme de progression roguelike : XP, niveaux et ameliorations.
##
## Les ennemis lachent de l'XP (EventBus.xp_gained). A chaque palier atteint, le
## jeu se met en pause et propose 3 ameliorations tirees au sort (stats, objets
## passifs, capacites, nouvelles armes). Le choix est applique a tous les joueurs.
##
## Decouple du reste : ecoute EventBus, agit sur Global.players. L'UI de choix est
## un CanvasLayer instancie a la volee ; la barre d'XP vit dans in_game_ui.

signal xp_changed(xp: int, xp_to_next: int, level: int)
signal leveled_up(level: int)

# Courbe d'XP : geometrique douce (niveau 1->2 = 8 XP, croissance ~x1.18/niv).
const XP_BASE := 8.0
const XP_GROWTH := 1.18

var level: int = 1
var xp: int = 0
var xp_to_next: int = 0

var _taken: Dictionary = {}   # id d'amelioration -> nombre de fois prise
var _catalog: Array[Upgrade] = []
var _pending_levelups: int = 0
var _panel: LevelUpPanel = null


func _ready() -> void:
	_build_catalog()
	xp_to_next = _xp_for_level(level)
	EventBus.xp_gained.connect(_on_xp_gained)


## Reinitialise la progression (nouvelle partie). Appele par Game.start_game.
func reset() -> void:
	level = 1
	xp = 0
	xp_to_next = _xp_for_level(level)
	_taken.clear()
	_pending_levelups = 0
	if _panel != null and is_instance_valid(_panel):
		_panel.queue_free()
	_panel = null
	# Reprend le cours du jeu au cas ou une partie s'arrete pendant un choix.
	if get_tree() != null:
		get_tree().paused = false
	xp_changed.emit(xp, xp_to_next, level)


func _xp_for_level(l: int) -> int:
	return int(round(XP_BASE * pow(XP_GROWTH, l - 1)))


func _on_xp_gained(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = _xp_for_level(level)
		_pending_levelups += 1
		leveled_up.emit(level)
		EventBus.player_leveled_up.emit(level)
	xp_changed.emit(xp, xp_to_next, level)
	if _pending_levelups > 0 and _panel == null:
		_present_next_levelup()


# ---------------------------------------------------------------------------
# Presentation / application des ameliorations
# ---------------------------------------------------------------------------
func _present_next_levelup() -> void:
	var choices: Array[Upgrade] = _roll_choices(3)
	if choices.is_empty():
		# Plus rien a proposer (toutes les ameliorations sont au max) : on consomme
		# silencieusement les paliers et on relance le jeu (evite un softlock si on
		# arrive ici en chaine, jeu deja en pause).
		_pending_levelups = 0
		get_tree().paused = false
		return
	get_tree().paused = true
	_panel = LevelUpPanel.new()
	add_child(_panel)
	_panel.setup(choices, level)
	_panel.chosen.connect(_on_upgrade_chosen)


func _on_upgrade_chosen(up: Upgrade) -> void:
	for p in Global.players:
		if p != null and is_instance_valid(p):
			up.apply(p)
	_taken[up.id] = int(_taken.get(up.id, 0)) + 1

	if _panel != null and is_instance_valid(_panel):
		_panel.queue_free()
	_panel = null
	_pending_levelups = max(0, _pending_levelups - 1)

	# Chaine les choix si plusieurs paliers ont ete franchis d'un coup.
	if _pending_levelups > 0:
		_present_next_levelup()
	else:
		get_tree().paused = false


## Tire `count` ameliorations distinctes parmi celles actuellement proposables.
func _roll_choices(count: int) -> Array[Upgrade]:
	var player: IPlayer = Global.players[0] if not Global.players.is_empty() else null
	var pool: Array[Upgrade] = []
	for up in _catalog:
		var taken: int = int(_taken.get(up.id, 0))
		if player == null or up.can_offer(player, taken):
			pool.append(up)
	pool.shuffle()
	return pool.slice(0, min(count, pool.size()))


# ---------------------------------------------------------------------------
# Catalogue d'ameliorations
# ---------------------------------------------------------------------------
func _build_catalog() -> void:
	var C := Upgrade.Category

	# --- Stats --- (effets multi-instructions -> methodes dediees, cf. plus bas)
	_catalog.append(Upgrade.new("hp", "Vitalite", "+30 vie max (et soin)",
		C.STAT, Color(1, 0.4, 0.45), "HP", _grant_hp, 6))
	_catalog.append(Upgrade.new("speed", "Cavale", "+8% vitesse de deplacement",
		C.STAT, Color(0.45, 0.9, 1.0), "SPD", _grant_speed, 6))
	_catalog.append(Upgrade.new("damage", "Puissance", "+15% degats infliges",
		C.STAT, Color(1, 0.6, 0.25), "DMG", _grant_damage, 8))
	_catalog.append(Upgrade.new("reload", "Mains agiles", "-12% temps de recharge",
		C.STAT, Color(1, 0.85, 0.3), "RLD", _grant_reload, 5))
	_catalog.append(Upgrade.new("fire_rate", "Gachette folle", "+12% cadence de tir",
		C.STAT, Color(1, 0.5, 0.35), "ROF", _grant_fire_rate, 6))
	_catalog.append(Upgrade.new("bullet", "Gros calibre", "+15% taille des projectiles",
		C.STAT, Color(0.75, 0.55, 1.0), "BLT", _grant_bullet, 5))

	# --- Objets passifs ---
	_catalog.append(Upgrade.new("lifesteal", "Sangsue", "+4 PV a chaque ennemi tue",
		C.ITEM, Color(0.9, 0.2, 0.35), "VAMP", _grant_lifesteal, 4))
	_catalog.append(Upgrade.new("armor", "Cuirasse", "-10% degats subis",
		C.ITEM, Color(0.6, 0.7, 0.85), "ARM", _grant_armor, 5))

	# --- Capacites ---
	_catalog.append(Upgrade.new("dash_cd", "Reflexes", "-15% cooldown du dash",
		C.ABILITY, Color(0.45, 0.78, 1.0), ">>", _grant_dash_cd, 5))
	_catalog.append(Upgrade.new("fire_cd", "Pyromane", "-15% cooldown du cercle de feu",
		C.ABILITY, Color(1.0, 0.55, 0.15), "()", _grant_fire_cd, 5))

	# --- Nouvelles armes (une entree par arme du catalogue, hors pistolet de base) ---
	var weapon_names := {
		"ak47": "AK-47", "mp5": "MP5", "shotgun": "Fusil a pompe",
		"sniper": "Sniper", "machinegun": "Mitrailleuse",
	}
	for wid in weapon_names.keys():
		var path := "res://scenes/weapon/%s.tscn" % wid
		if not ResourceLoader.exists(path):
			continue
		var wname: String = weapon_names[wid]
		# `bind` fige l'identifiant/chemin de l'arme : les Callables restent des
		# references de methode (func(player)) -> aucune lambda multi-ligne en arg.
		_catalog.append(Upgrade.new("weapon_" + wid, wname, "Equipe une nouvelle arme",
			C.WEAPON, Color(0.9, 0.85, 0.45), "GUN",
			_grant_weapon.bind(path), -1, _weapon_not_equipped.bind(wid)))


# --- Effets d'amelioration (references par le catalogue) ---
func _grant_damage(p: IPlayer) -> void:
	p.damage_factor *= 1.15


func _grant_reload(p: IPlayer) -> void:
	p.reload_factor = maxf(0.2, p.reload_factor * 0.88)


func _grant_lifesteal(p: IPlayer) -> void:
	p.lifesteal += 4.0


func _grant_armor(p: IPlayer) -> void:
	p.damage_reduction = minf(0.7, p.damage_reduction + 0.10)


func _grant_dash_cd(p: IPlayer) -> void:
	p.dash_cooldown = maxf(1.0, p.dash_cooldown * 0.85)


func _grant_fire_cd(p: IPlayer) -> void:
	p.fire_ring_cooldown = maxf(1.0, p.fire_ring_cooldown * 0.85)


func _grant_hp(p: IPlayer) -> void:
	p._base_max_health += 30.0
	p.apply_balance()
	p.heal(30.0)


func _grant_speed(p: IPlayer) -> void:
	p._base_speed *= 1.08
	p.apply_balance()


func _grant_fire_rate(p: IPlayer) -> void:
	p.fire_rate_factor *= 1.12
	p.apply_weapon_modifiers()


func _grant_bullet(p: IPlayer) -> void:
	p.bullet_scale_factor *= 1.15
	p.apply_weapon_modifiers()


func _grant_weapon(p: IPlayer, path: String) -> void:
	var scene := load(path) as PackedScene
	if scene != null:
		p.add_weapon(scene.instantiate())


func _weapon_not_equipped(p: IPlayer, wid: String) -> bool:
	return p.weapon == null or p.weapon.config_id != wid
