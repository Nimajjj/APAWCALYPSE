extends Node2D

var zombie_scene: PackedScene        = preload("res://scenes/enemy/zombie.tscn")
var woman_zombie_scene: PackedScene  = preload("res://scenes/enemy/woman_zombie.tscn")
var buffed_zombie_scene: PackedScene = preload("res://scenes/enemy/buffed_zombie.tscn")
var miser_scene: PackedScene         = preload("res://scenes/enemy/miser.tscn")
var big_zombie_scene: PackedScene    = preload("res://scenes/enemy/big_zombie.tscn")
var reaper_scene: PackedScene        = preload("res://scenes/enemy/reaper.tscn")

@onready var boss_spawn_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D


func create_enemy(posistion: Vector2, destination: Vector2, boss: bool, direction: String) -> IEnemy:
	if multiplayer.get_unique_id() != 1: return

	var enemy: IEnemy
	var enemy_type: int = handle_spawn(boss)

	if boss:
		enemy = big_zombie_scene.instantiate()
	else:
		var rand = randi() % 100
		if rand < 65:
			enemy = zombie_scene.instantiate()
		else:
			enemy = woman_zombie_scene.instantiate()
	
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


	posistion.x += randi_range(-50, 50)
	enemy.position = position
	enemy.global_position = global_position
	enemy.max_health += Global.game.wave * 2
	enemy.damage += Global.game.wave * 1.75
	enemy .money += Global.game.wave * randi() % 5
	enemy.speed += randi() % 300
	enemy.speed_stock = enemy.speed
	enemy.health = enemy.max_health
	enemy.state = 0
	enemy.direction = direction
	enemy.destination = destination
	enemy.target = enemy.destination

	get_tree().get_root().get_node("/root/Main/Enemies").add_child(enemy, true)

	enemy.spawner = get_parent()
	Global.units_alive += 1
	
	return enemy


func handle_spawn(boss: bool) -> int:
	if boss:
		return 5
	var spawn_rate = randi() % 100
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

