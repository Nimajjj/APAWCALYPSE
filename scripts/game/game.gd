class_name Game
extends Node2D

var score: int = 0
var wave: int = 0
var wave_activated: bool = false
var spawners_activated: bool = false
var time: float = 0.0
var enabled_spawner: int = 0

@onready var GameTimer: Timer = $GameTimer
@onready var WaveTimer: Timer = $WaveTimer
@onready var FabricPlayer: Node2D = $FabricPlayer

func _enter_tree():
	Global.game = self
	
func _ready():
	start_game()
	
	
func start_game() -> void:
	_new_player()
	GameTimer.start()			
	var spawners := get_tree().get_nodes_in_group("spawners")
	for spawner in spawners:
		Global.spawners.append(spawner as ISpawner)
	

	new_wave()
	
func new_wave():
	if !wave_activated:
		WaveTimer.start()
		wave_activated = true
		spawners_activated = false
		wave += 1
		enabled_spawner = 0
		for spawner in Global.spawners:
			if spawner.enabled:
				enabled_spawner += 1
		Global.units_left_to_spawn = enabled_spawner * 5 * wave
	
func end_game() -> void:
	wave = 0
	time = 0.0
	score = 0
	
func _new_player() -> void:
	FabricPlayer.create_player()
	
	
func _on_game_timer_timeout():
	time += 0.1
	
func _on_wave_timer_timeout():
	if !spawners_activated:
		for spawner in Global.spawners:
				if spawner.enabled:
					spawner.start(Global.units_left_to_spawn/enabled_spawner)
		spawners_activated = true
