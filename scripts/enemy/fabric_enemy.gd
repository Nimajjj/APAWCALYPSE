extends Node2D

var zombie_scene: PackedScene = preload("res://scenes/enemy/zombie.tscn")
var floda_scene: PackedScene = preload("res://scenes/enemy/floda.tscn")
var woman_zombie_scene: PackedScene = preload("res://scenes/enemy/woman_zombie.tscn")
var big_zombie_scene: PackedScene = preload("res://scenes/enemy/big_zombie.tscn")


func create_enemy(posistion: Vector2, destination: Vector2, boss: bool, direction: String) -> IEnemy:
	var enemy: IEnemy

	if boss:
		enemy = big_zombie_scene.instantiate()
		enemy.is_boss = true
	else:
		var rand = randi() % 100
		print(rand)
		if rand < 65:
			enemy = zombie_scene.instantiate()
		elif 65 <= rand && rand < 75:
			enemy = floda_scene.instantiate()
		else:
			enemy = woman_zombie_scene.instantiate()
	
	posistion.x += randi_range(-50, 50)
	enemy.position = posistion
	enemy.max_health += Global.game.wave * 2
	enemy.damage += Global.game.wave * 1.75
	enemy.money += Global.game.wave * randi() % 5
	enemy.speed += randi() % 300
	enemy.health = enemy.max_health
	enemy.state = 0
	enemy.direction = direction
	enemy.destination = destination
	enemy.target = enemy.destination
	add_child(enemy)
	Global.units_alive += 1
	print(enemy.speed)
	return enemy
