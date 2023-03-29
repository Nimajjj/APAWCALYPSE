class_name Game
extends Node2D

var score: int = 0
var wave: int = 0
var wave_activated: bool = false
var time: float = 0.0

@onready var GameTimer: Timer = $GameTimer
@onready var FabricPlayer: Node2D = $FabricPlayer

func _ready():
	Global.game = self
	start_game()
	
func start_game() -> void:
	_new_player()
	GameTimer.start()
	for i in get_children():
		if i is ISpawner:
			Global.spawners.append(i)
	
			
func _process(delta):
	if !wave_activated:
		for spawner in Global.spawners:
			if spawner.enabled:
				print("spawner  enabled")
				spawner.start(5)
				wave_activated = true
			else:
				print("spawner  disabled")
	if Global.units.size() == 0 && wave_activated:
		wave += 1
	
	
func end_game() -> void:
	wave = 0
	time = 0.0
	score = 0
	
func _new_player() -> void:
	FabricPlayer.create_player()
	
func _on_game_timer_timeout():
	time += 0.1
	
