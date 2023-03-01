extends Node2D

var score: int = 0
var wave: int = 0
var time: float = 0.0

@onready var GameTimer: Timer = $GameTimer
@onready var FabricPlayer: Node2D = $FabricPlayer


func _ready():
	start_game()
	

func start_game() -> void:
	FabricPlayer.create_player()
	GameTimer.start()


func end_game() -> void:
	wave = 0
	time = 0.0
	score = 0


func _on_game_timer_timeout():
	time += 0.1
