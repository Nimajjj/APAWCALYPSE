class_name ISpawner
extends Node2D

@export var id: int
@export var window: Interactible	# to change to Window
@export var enabled: bool = false


var units_left_to_spawn: int
var spawn_delay: float = 2


@onready var timer: Timer = $Timer
@onready var FabricEnemy: Node2D = $FabricEnemy


func enable() -> void:
	enabled = true
	timer.connect("timeout", _on_timer_timeout)


func start(units_to_spawn: int):
	units_left_to_spawn = units_to_spawn
	timer.start()
	timer.wait_time = spawn_delay	
	
	
func stop() -> void:
	timer.stop()


func is_last_wave_dead():
	if Global.is_all_units_spawned() && Global.is_all_units_dead():
		Global.game.wave_activated = false
		Global.game.new_wave()
	
	
func is_all_spawner_units_spawned() -> bool:
	return units_left_to_spawn == 0


func _on_timer_timeout():
	if !is_all_spawner_units_spawned():
		Global.units.append(FabricEnemy.create_enemy("zombie", FabricEnemy.position))
		units_left_to_spawn -= 1
		Global.units_left_to_spawn -= 1
	else:
		stop()
	
	
