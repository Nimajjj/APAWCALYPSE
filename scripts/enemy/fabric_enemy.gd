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
# Nouveaux insectes (non animes pour l'instant, profil de stats uniquement).
var ant_scene: PackedScene           = preload("res://scenes/enemy/ant.tscn")
var beetle_scene: PackedScene        = preload("res://scenes/enemy/beetle.tscn")
var explosive_fly_scene: PackedScene = preload("res://scenes/enemy/explosive_fly.tscn")
var toxic_fly_scene: PackedScene     = preload("res://scenes/enemy/toxic_fly.tscn")
var wasp_scene: PackedScene          = preload("res://scenes/enemy/wasp.tscn")

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
# Marge ajoutee autour du rectangle de collision d'une porte (~ rayon d'un corps
# en scale 2x + tolerance) : un segment de l'itineraire qui entre dans cette zone
# est considere comme bloque par la porte fermee.
const _DOOR_MARGIN := 20.0
# Fallback (porte sans StaticBody/CollisionShape rectangulaire) : disque autour de
# l'origine du noeud. ~ demi-largeur d'une porte (64px) + marge.
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


## Vrai si un itineraire navmesh joueur -> pos existe ET ne traverse aucune porte
## encore fermee. Definition de "zone accessible" (style COD Zombies) : la navmesh
## relie toutes les pieces (les portes ne la decoupent pas), donc on rejette
## l'itineraire des qu'un de ses segments coupe la zone d'une porte non achetee
## (encore dans le groupe "doors").
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
			if _segment_hits_door(a, b, d):
				return false
	return true


## Vrai si le segment [a, b] traverse la porte fermee `door`. On teste le rectangle
## de collision REEL de la porte (StaticBody2D/CollisionShape2D), via sa transform
## globale, et non l'origine du noeud : les portes (surtout les SideDoor) ont un
## collider decale de plusieurs dizaines de px par rapport a leur origine, ce qui
## faisait passer l'ancien test par disque a cote de l'ouverture reelle.
func _segment_hits_door(a: Vector2, b: Vector2, door: Node) -> bool:
	var cs := door.get_node_or_null("StaticBody2D/CollisionShape2D") as CollisionShape2D
	if cs == null or not (cs.shape is RectangleShape2D):
		# Fallback : disque autour de l'origine du noeud.
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(door.global_position, a, b)
		return closest.distance_to(door.global_position) < _DOOR_BLOCK_RADIUS
	# On ramene le segment dans l'espace LOCAL du collider : la boite devient alors
	# une AABB centree sur l'origine, ce qui rend le test trivial et insensible a la
	# rotation de la porte.
	var inv := cs.global_transform.affine_inverse()
	var la: Vector2 = inv * a
	var lb: Vector2 = inv * b
	var ext: Vector2 = (cs.shape as RectangleShape2D).size * 0.5 + Vector2(_DOOR_MARGIN, _DOOR_MARGIN)
	return _segment_intersects_box(la, lb, ext)


## Intersection segment / AABB centree en (0,0) de demi-tailles `ext` (espace local).
func _segment_intersects_box(a: Vector2, b: Vector2, ext: Vector2) -> bool:
	# Une extremite dans la boite -> intersection.
	if absf(a.x) <= ext.x and absf(a.y) <= ext.y:
		return true
	if absf(b.x) <= ext.x and absf(b.y) <= ext.y:
		return true
	# Sinon, test contre les 4 aretes de la boite.
	var c0 := Vector2(-ext.x, -ext.y)
	var c1 := Vector2(ext.x, -ext.y)
	var c2 := Vector2(ext.x, ext.y)
	var c3 := Vector2(-ext.x, ext.y)
	if Geometry2D.segment_intersects_segment(a, b, c0, c1) != null:
		return true
	if Geometry2D.segment_intersects_segment(a, b, c1, c2) != null:
		return true
	if Geometry2D.segment_intersects_segment(a, b, c2, c3) != null:
		return true
	if Geometry2D.segment_intersects_segment(a, b, c3, c0) != null:
		return true
	return false


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
	elif enemy_type == 10:
		return ant_scene.instantiate()
	elif enemy_type == 11:
		return beetle_scene.instantiate()
	elif enemy_type == 12:
		return explosive_fly_scene.instantiate()
	elif enemy_type == 13:
		return toxic_fly_scene.instantiate()
	elif enemy_type == 14:
		return wasp_scene.instantiate()
	return zombie_scene.instantiate()


## Applique les overrides dev, le scaling de vague puis les multiplicateurs Balance.
func _apply_stats(enemy: IEnemy) -> void:
	GameConfig.apply_enemy(enemy)

	# Scaling de vague facon Brotato : croissance LINEAIRE proportionnelle a la stat
	# de base (PV = base * (1 + pv_par_vague * (vague-1))). Fort et previsible, il
	# suit la montee en puissance du joueur (upgrades multiplicatives) pour eviter
	# qu'on devienne trop fort trop vite. Les boss recoivent la moitie de la
	# croissance PV/degats (deja tres tanky en valeur de base).
	var waves_elapsed: int = max(0, Global.game.wave - 1)
	var hp_step: float = Balance.get_v("enemy_hp_per_wave")
	var dmg_step: float = Balance.get_v("enemy_dmg_per_wave")
	if enemy.is_boss:
		hp_step *= 0.5
		dmg_step *= 0.5
	enemy.max_health = int(enemy.max_health * (1.0 + hp_step * waves_elapsed))
	enemy.damage = int(enemy.damage * (1.0 + dmg_step * waves_elapsed))
	# L'argent ET la vitesse restent FIXES par type d'ennemi (valeurs de base de la
	# scene) : pas de scaling de vague ni de hasard, pour une economie lisible et des
	# deplacements coherents. Seuls les multiplicateurs Balance "enemy_money" /
	# "enemy_speed" les ajustent.

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
