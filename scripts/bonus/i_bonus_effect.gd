class_name IBonusEffect
extends Node2D

@onready var timer: Timer = $EffectDuration
@export var effectDuration: float = 0.0

func _ready() -> void:
	timer.connect("timeout", end_effect)


func apply_effect() -> void:
	# Timer.wait_time rejette les valeurs <= 0 (erreur "Time should be greater
	# than zero"). Les effets sans effectDuration defini (0.0) conservent alors
	# le wait_time de leur scene : on ne l'ecrase que si une duree valide est fournie.
	if effectDuration > 0.0:
		timer.wait_time = effectDuration
	timer.start()
	if get_parent() is IPlayer:
		get_parent().active_bonus.append((self.name.trim_suffix("Effect").to_lower()))
		_effect()


func _effect() -> void:
	pass # override


func end_effect() -> void:
	pass # override
