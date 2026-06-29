class_name ISpawner
extends Node2D


var units_left_to_spawn: int
var is_boss_wave: bool
var spawn_delay: float = 2

@export var id: int
@export var enabled: bool = false
@export var direction: String
@export var destination: Vector2

@onready var timer: Timer = $Timer
@onready var fabric_enemy: Node2D = $FabricEnemy


func enable() -> void:
	enabled = true
	timer.connect("timeout", _on_timer_timeout)

func start_spawner(units_to_spawn: int, is_boss: bool) -> void:
	units_left_to_spawn = units_to_spawn
	timer.start()
	timer.wait_time = spawn_delay
	is_boss_wave = is_boss

func stop() -> void:
	timer.stop()

func is_all_spawner_units_spawned() -> bool:
	return units_left_to_spawn == 0

func _on_timer_timeout():
	if !is_all_spawner_units_spawned():
		# Une fraction des ennemis (hors boss) apparait directement autour du
		# joueur via un marqueur clignotant ; le reste passe par la fenetre.
		var near_ratio: float = Balance.get_v("spawn_near_ratio")
		var spawned_near: bool = false
		if not is_boss_wave and randf() < near_ratio and not Global.players.is_empty():
			spawned_near = fabric_enemy.spawn_near_player(false, direction)
		if not spawned_near:
			Global.units.append(fabric_enemy.create_enemy(fabric_enemy.position, destination, is_boss_wave, direction))
			if is_boss_wave:
				is_boss_wave = false
		units_left_to_spawn -= 1
		Global.units_left_to_spawn -= 1
	else:
		stop()
