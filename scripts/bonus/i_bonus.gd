class_name IBonus
extends Node2D

@onready var BonusTimer = $DispawnTimer

@export var BonusEffect: PackedScene = null


func _ready() -> void:
	BonusTimer.connect("timeout", delete_bonus)
	BonusTimer.start()


func _process(delta: float) -> void:
	pass


func _on_hitbox_area_entered(body) -> void:
	if body.get_parent() is IPlayer:
		var effect := BonusEffect.instantiate()
		if(!body.get_parent().active_bonus.has(effect.name.trim_suffix("Effect").to_lower())):
			body.get_parent().add_child(effect)
			effect.apply_effect()
			queue_free()


func delete_bonus() -> void:
	print("bonus deleted : nobody picked it")
	queue_free()
