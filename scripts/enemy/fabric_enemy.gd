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
	enemy.health = enemy. max_health
	add_child(enemy)
	
	
	
	return enemy
