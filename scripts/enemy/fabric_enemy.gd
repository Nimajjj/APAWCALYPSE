extends Node2D

var zombie_scene: PackedScene = preload("res://scenes/enemy/zombie.tscn")
var dog_scene: PackedScene = preload("res://scenes/enemy/dog.tscn")


func create_enemy(type: String, pos: Vector2) -> IEnemy:
	var enemy: IEnemy
	
	match type:
		"dog":
			enemy = dog_scene.instantiate()
		"zombie":
			enemy = zombie_scene.instantiate()
		_:
			pass
			# fucking not normal
	
	enemy.position = pos
	enemy.max_health += Global.game.wave * 2
	enemy.damage += Global.game.wave * 1.75
	enemy.money += Global.game.wave * randi() % 5
	enemy.speed += randi() % 20
	enemy.health = enemy.max_health
	add_child(enemy)
	Global.units_alive += 1
	return enemy
