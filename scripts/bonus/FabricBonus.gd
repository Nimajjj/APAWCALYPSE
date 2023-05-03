extends Node2D


var bonuses_scenes: Array[PackedScene] = [
	preload("res://scenes/bonus/money_x2.tscn"),
	preload("res://scenes/bonus/max_ammo.tscn"),
	preload("res://scenes/bonus/dead_shot.tscn"),
	preload("res://scenes/bonus/nuke.tscn"),
]

func _ready() -> void:
	Global.fabric_bonus = self

	
func pick_random_bonus() -> IBonus:
	var bonus = bonuses_scenes[randi() % bonuses_scenes.size()]
	return bonus.instantiate()


func spawn_bonus(pos: Vector2) -> void:
	var bonus = pick_random_bonus()
	bonus.position = pos
	Global.map.add_child(bonus)
