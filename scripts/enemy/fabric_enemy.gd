extends Node2D

var zombie_scene: PackedScene = preload("res://scenes/enemy/zombie.tscn")
var dog_scene: PackedScene = preload("res://scenes/enemy/dog.tscn")


func create_enemy(type: String, pos: Vector2) -> IEnemy:
	var enemy: IEnemy
	
	match type:
		"dog":
			enemy = dog_scene.instance()
		_:
			pass
			# fucking not normal
	
	get_parent().add_child(enemy)
	enemy.position = pos
	enemy.set_enemy(IEnemy)
	
	return enemy
