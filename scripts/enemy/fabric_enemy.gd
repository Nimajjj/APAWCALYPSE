extends Node2D

var zombie_scene: PackedScene = preload("res://scenes/enemy/zombie.tscn")
var big_zombie_scene: PackedScene = preload("res://scenes/enemy/big_zombie.tscn")


func create_enemy(posistion: Vector2, destination: Vector2, boss: bool) -> IEnemy:
	var enemy: IEnemy

	if boss:
		enemy = big_zombie_scene.instantiate()
	else:
		enemy = zombie_scene.instantiate()

	
	posistion.x += randi_range(-50, 50)
	enemy.position = posistion
	enemy.max_health += Global.game.wave * 2
	enemy.damage += Global.game.wave * 1.75
	enemy.money += Global.game.wave * randi() % 5
	enemy.speed += randi() % 20
	enemy.health = enemy.max_health
	enemy.state = 0
	enemy.destination = destination
	enemy.target = enemy.destination
	add_child(enemy)
	Global.units_alive += 1
	return enemy
