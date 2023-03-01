class_name ISpawner
extends Node2D

var spawners: Array[Spawner]


func _ready():
	init_spawners()



func start_spawners(units_to_spawn):
	var enabled_spawners: int
	for spawner in spawners:
		if spawner.actif:
			enabled_spawners += 1
	


func stop_spawners():
	for spawner in spawners:
		spawner.stop()


func init_spawners():
	var children: Array[Node] = get_children()
	for child in children:
		if child.is_in_group("spawner"):
			spawners.append(child)
	
	
func enable_spawners(id):
	for spawner in spawners:
		if spawner.id == id & !spawner.actif:
			spawner.actif = true
