extends Node2D

var zombie_scene: PackedScene = preload("res://scenes/enemy/zombie.tscn")
var floda_scene: PackedScene = preload("res://scenes/enemy/floda.tscn")
var woman_zombie_scene: PackedScene = preload("res://scenes/enemy/woman_zombie.tscn")
var big_zombie_scene: PackedScene = preload("res://scenes/enemy/big_zombie.tscn")


func create_enemy(posistion: Vector2, destination: Vector2, boss: bool, direction: String) -> IEnemy:
	if multiplayer.get_unique_id() != 1: return
		
	var enemy: IEnemy

	if boss:
		enemy = big_zombie_scene.instantiate()
	else:
		var rand = randi() % 100
		if rand < 65:
			enemy = zombie_scene.instantiate()
		elif 65 <= rand && rand < 75:
			enemy = floda_scene.instantiate()
		else:
			enemy = woman_zombie_scene.instantiate()
	
	posistion.x += randi_range(-50, 50)
	enemy.position = position
	enemy.global_position = global_position
	enemy.max_health += Global.game.wave * 2
	enemy.damage += Global.game.wave * 1.75
	enemy .money += Global.game.wave * randi() % 5
	enemy.speed += randi() % 300
	enemy.health = enemy.max_health
	enemy.state = 0
	enemy.direction = direction
	enemy.destination = destination
	enemy.target = enemy.destination
		
	get_tree().get_root().get_node("/root/Main/Enemies").add_child(enemy, true)
	
	enemy.spawner = get_parent()
	Global.units_alive += 1
	return enemy
