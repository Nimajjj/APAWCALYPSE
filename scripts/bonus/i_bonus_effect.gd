class_name IBonusEffect
extends Node2D

@onready var timer: Timer = $EffectDuration
@export var effectDuration: float = 0.0

func _ready() -> void:
	timer.connect("timeout", end_effect)


func apply_effect() -> void:
	timer.wait_time = effectDuration
	timer.start()
	if get_parent() is IPlayer:
		get_parent().active_bonus.append((self.name.trim_suffix("Effect").to_lower()))
		_effect()


func _effect() -> void:
	pass # override


func end_effect() -> void:
	pass # override
