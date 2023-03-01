class_name Spawner
extends Node2D

var units_left_to_spawn: int
var units_alive: int
var actif: bool = false
@export var id: int
var spawn_delay: int

@onready var timer: Timer = $Timer
@onready var i_enemy: IEnemy = $IEnemy

func start(units):
	units_left_to_spawn = units
	timer.start()
	timer.wait_time = spawn_delay
		
	
func stop() -> void:
	timer.stop()

func is_all_units_dead() -> bool:
	return units_alive == 0
		
func is_all_units_spawned() -> bool:
	return units_left_to_spawn == 0


func _on_timer_timeout():
	if is_all_units_spawned():
		units_left_to_spawn -= 1
		i_enemy.create_enemy(50,500,10)
	else:
		stop()
	
	
