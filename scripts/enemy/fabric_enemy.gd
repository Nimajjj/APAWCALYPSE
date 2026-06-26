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

@onready var boss_spawn_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D


func create_enemy(posistion: Vector2, destination: Vector2, boss: bool, direction: String) -> IEnemy:
	var enemy: IEnemy
	var enemy_type: int = handle_spawn(boss)

	if enemy_type == 0:
		enemy = zombie_scene.instantiate()
	elif enemy_type == 1:
		enemy = woman_zombie_scene.instantiate()
	elif enemy_type == 2:
		enemy = buffed_zombie_scene.instantiate()
	elif enemy_type == 3:
		enemy = miser_scene.instantiate()
	elif enemy_type == 4:
		enemy = reaper_scene.instantiate()
	elif enemy_type == 5:
		enemy = big_zombie_scene.instantiate()
		boss_spawn_sound.play()
	elif enemy_type == 6:
		enemy = runner_scene.instantiate()
	elif enemy_type == 7:
		enemy = brute_scene.instantiate()
	elif enemy_type == 8:
		enemy = charger_scene.instantiate()
	elif enemy_type == 9:
		enemy = exploder_scene.instantiate()


	posistion.x += randi_range(-100, 100)
	enemy.position = posistion

	# Stats de base persistantes (overrides dev) avant le scaling de vague.
	GameConfig.apply_enemy(enemy)

	enemy.max_health += Global.game.wave * 2
	enemy.damage += Global.game.wave * 1.75
	enemy.money += Global.game.wave * randi() % 5
	enemy.speed += randi() % 300

	# Applique les multiplicateurs d'equilibrage globaux (Balance) une fois le
	# scaling de vague effectue.
	enemy.apply_balance()

	enemy.speed_stock = enemy.speed
	enemy.health = enemy.max_health
	enemy.state = 0
	enemy.direction = direction
	enemy.destination = destination
	add_child(enemy)
	Global.units_alive += 1
	return enemy


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

