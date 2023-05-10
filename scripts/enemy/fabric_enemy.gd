extends Node2D

var zombie_scene: PackedScene = preload("res://scenes/enemy/zombie.tscn")
var dog_scene: PackedScene = preload("res://scenes/enemy/dog.tscn")


func create_enemy(type: String, posistion: Vector2, destination: Vector2) -> IEnemy:
	var enemy: IEnemy

	match type:
		"dog":
			enemy = dog_scene.instantiate()
		"zombie":
			enemy = zombie_scene.instantiate()
		_:
			pass

	# make the position a little bit random
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
