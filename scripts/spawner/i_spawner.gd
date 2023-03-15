class_name ISpawner
extends Node2D

@export var id: int
@export var window: Interactible	# to change to Window

var units: Array[IEnemy] = []
var units_left_to_spawn: int
var enabled: bool = false
var spawn_delay: float

@onready var timer: Timer = $Timer


func enable() -> void:
	enabled = true
	timer.connect("timeout", _on_timer_timeout)


func start(units: int):
	units_left_to_spawn = units
	timer.start()
	timer.wait_time = spawn_delay
		
	
func stop() -> void:
	timer.stop()


func is_all_units_dead() -> bool:
	return get_child_count() == 0
	
		
func is_all_units_spawned() -> bool:
	return units_left_to_spawn == 0


func _on_timer_timeout():
	if is_all_units_spawned():
		pass
	else:
		stop()
	
	
