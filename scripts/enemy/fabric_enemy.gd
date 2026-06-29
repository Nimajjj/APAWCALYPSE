extends Node2D

var zombie_scene: PackedScene        = preload("res://scenes/enemy/zombie.tscn")
var woman_zombie_scene: PackedScene  = preload("res://scenes/enemy/woman_zombie.tscn")
var buffed_zombie_scene: PackedScene = preload("res://scenes/enemy/buffed_zombie.tscn")
var miser_scene: PackedScene         = preload("res://scenes/enemy/miser.tscn")
var big_zombie_scene: PackedScene    = preload("res://scenes/enemy/big_zombie.tscn")
var reaper_scene: PackedScene        = preload("res://scenes/enemy/reaper.tscn")
var runner_scene: PackedScene        = preload("res://scenes/enemy/runner.tscn")
var brute_scene: PackedScene         = preload("res://scenes/enemy/brute.tscn")
var charger_scene: PackedScene       = preload("res://scenes/enemy/charger.tscn")
var exploder_scene: PackedScene      = preload("res://scenes/enemy/exploder.tscn")

# Table de spawn editable (.tres). Fallback sur l'ancienne logique si absente.
var _spawn_table: EnemySpawnTable = load("res://resources/enemy_spawn_table.tres") as EnemySpawnTable

const SpawnTelegraphScene := preload("res://scripts/effects/spawn_telegraph.gd")

@onready var boss_spawn_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D


func create_enemy(posistion: Vector2, destination: Vector2, boss: bool, direction: String) -> IEnemy:
	var enemy: IEnemy = _instantiate(handle_spawn(boss))

	posistion.x += randi_range(-100, 100)
	enemy.position = posistion
	_apply_stats(enemy)

	enemy.state = 0
	enemy.direction = direction
	enemy.destination = destination
	add_child(enemy)
	Global.units_alive += 1
	return enemy


## Spawn "style Brotato" : pose une croix rouge clignotante dans un rayon autour
## du joueur, puis fait apparaitre l'ennemi (deja en poursuite) a cet endroit.
## Le slot est reserve immediatement (units_alive) pour que la vague ne se termine
## pas tant qu'un marqueur est en attente.
## Renvoie false si aucun point valide n'a ete trouve (zone verrouillee / coince) ;
## l'appelant retombe alors sur un spawn classique par la fenetre.
func spawn_near_player(boss: bool, direction: String) -> bool:
	if Global.players.is_empty() or Global.players[0] == null:
		return false
	var player: IPlayer = Global.players[0]
	var pos: Vector2 = _pick_point_near(player)
	if is_nan(pos.x):
		return false

	Global.units_alive += 1
	var telegraph := SpawnTelegraphScene.new() as SpawnTelegraph
	_telegraph_parent().add_child(telegraph)
	telegraph.global_position = pos
	telegraph.finished.connect(func():
		var enemy: IEnemy = _instantiate(handle_spawn(boss))
		_apply_stats(enemy)
		enemy.direction = direction
		enemy.destination = pos
		add_child(enemy)
		enemy.global_position = pos
		# Apparait directement en poursuite (etat 2), sans transiter par la fenetre.
		if is_instance_valid(player):
			enemy.state = 2
			enemy.chase_target = player
			enemy.retarget()
			enemy.path_timer.start()
		else:
			enemy.state = 0
		Global.units.append(enemy)
	)
	return true


## Tire un point aleatoire dans le disque [min, rayon] autour du joueur, le projette
## sur la navmesh (pas de spawn dans un mur), puis valide qu'il est dans la zone
## ACTUELLEMENT accessible (style COD Zombies) : on calcule l'itineraire navmesh
## joueur -> point et on le rejette s'il n'atteint pas le point (zone isolee) ou si
## un segment traverse une PORTE FERMEE non achetee. Renvoie Vector2(NAN, NAN) si
## aucun point valable n'est trouve.
const _SPAWN_ATTEMPTS := 16
# Tolerance entre la fin de l'itineraire et le point vise (point reellement atteint).
const _REACH_TOLERANCE := 24.0
# Une porte fermee a moins de cette distance d'un segment de l'itineraire = zone
# verrouillee. ~ demi-largeur d'une porte (64px) + marge.
const _DOOR_BLOCK_RADIUS := 48.0

func _pick_point_near(player: IPlayer) -> Vector2:
	var radius: float = Balance.get_v("spawn_near_radius")
	var min_dist: float = min(120.0, radius * 0.4)
	var nav_map: RID = player.get_world_2d().get_navigation_map()
	if not nav_map.is_valid():
		return Vector2(NAN, NAN)
	var from: Vector2 = player.global_position
	var doors := get_tree().get_nodes_in_group("doors")

	for _i in _SPAWN_ATTEMPTS:
		var angle: float = randf() * TAU
		var dist: float = lerpf(min_dist, radius, sqrt(randf()))
		var target: Vector2 = from + Vector2(cos(angle), sin(angle)) * dist
		var pos: Vector2 = NavigationServer2D.map_get_closest_point(nav_map, target)
		# Trop proche apres projection (point colle a un mur) -> on retente.
		if pos.distance_to(from) < min_dist * 0.5:
			continue
		if _is_reachable_open(nav_map, from, pos, doors):
			return pos
	return Vector2(NAN, NAN)


## Vrai si un itineraire navmesh joueur -> pos existe ET ne longe aucune porte encore
## fermee. Definition de "zone accessible" (style COD Zombies) : la navmesh relie
## toutes les pieces (les portes ne la decoupent pas), donc on rejette l'itineraire
## des qu'il passe au niveau d'une porte non achetee (encore dans le groupe "doors").
func _is_reachable_open(nav_map: RID, from: Vector2, pos: Vector2, doors: Array) -> bool:
	var path: PackedVector2Array = NavigationServer2D.map_get_path(nav_map, from, pos, true)
	if path.size() < 2:
		return false
	# L'itineraire doit reellement aboutir au point (sinon zone isolee/inaccessible).
	if path[path.size() - 1].distance_to(pos) > _REACH_TOLERANCE:
		return false
	for i in path.size() - 1:
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		for d in doors:
			if not is_instance_valid(d):
				continue
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(d.global_position, a, b)
			if closest.distance_to(d.global_position) < _DOOR_BLOCK_RADIUS:
				return false
	return true


func _telegraph_parent() -> Node:
	return Global.map if Global.map != null else self


func _instantiate(enemy_type: int) -> IEnemy:
	if enemy_type == 1:
		return woman_zombie_scene.instantiate()
	elif enemy_type == 2:
		return buffed_zombie_scene.instantiate()
	elif enemy_type == 3:
		return miser_scene.instantiate()
	elif enemy_type == 4:
		return reaper_scene.instantiate()
	elif enemy_type == 5:
		boss_spawn_sound.play()
		return big_zombie_scene.instantiate()
	elif enemy_type == 6:
		return runner_scene.instantiate()
	elif enemy_type == 7:
		return brute_scene.instantiate()
	elif enemy_type == 8:
		return charger_scene.instantiate()
	elif enemy_type == 9:
		return exploder_scene.instantiate()
	return zombie_scene.instantiate()


## Applique les overrides dev, le scaling de vague puis les multiplicateurs Balance.
func _apply_stats(enemy: IEnemy) -> void:
	GameConfig.apply_enemy(enemy)

	enemy.max_health += Global.game.wave * 2
	enemy.damage += Global.game.wave * 1.75
	enemy.money += Global.game.wave * randi() % 5
	enemy.speed += randi() % 300

	enemy.apply_balance()

	enemy.speed_stock = enemy.speed
	enemy.health = enemy.max_health


func handle_spawn(boss: bool) -> int:
	if boss:
		return 5
	var spawn_rate = randi() % 100
	if _spawn_table != null:
		var wave: int = Global.game.wave if Global.game != null else 1
		return _spawn_table.pick_type(wave, spawn_rate)
	# Fallback (table absente) : ancienne logique en dur.
	if Global.game.wave < 6:
		if spawn_rate < 80:
			return 0
		else:
			return 1
	elif Global.game.wave < 11:
		if spawn_rate < 60:
			return 0
		elif spawn_rate < 80:
			return 1
		elif spawn_rate < 95:
			return 2
		else:
			return 3
	elif Global.game.wave < 16:
		if spawn_rate < 40:
			return 0
		elif spawn_rate < 65:
			return 1
		elif spawn_rate < 90:
			return 2
		elif spawn_rate < 99:
			return 3
		else:
			return 4
	else:
		if spawn_rate < 20:
			return 0
		elif spawn_rate < 40:
			return 1
		elif spawn_rate < 80:
			return 2
		elif spawn_rate < 90:
			return 3
		else:
			return 4
