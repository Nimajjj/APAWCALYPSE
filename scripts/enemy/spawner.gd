extends Node2D

class_name Spawner

var units_left_to_spawn: int
var units_alive: int
var actif: bool = false
var id: int
var spawn_delay: int

func start(units):
	pass
	
func stop():
	pass

func is_all_units_dead():
	#return bool
	pass
		
func is_all_units_spawned():
	pass
