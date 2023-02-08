extends Node2D

var player_1: CharacterBody2D = null
var player_2: CharacterBody2D = null
var player_3: CharacterBody2D = null
var player_4: CharacterBody2D = null

var score: int = 0
var wave: int = 0
var time: float = 0.0

@onready var GameTimer: Timer = $GameTimer
#@onready var IPlayer: IPlayer = $IPlayer


func _ready():
	start_game()
	

func start_game() -> void:
#	IPlayer.create_player(1)
	GameTimer.start()


func end_game() -> void:
	player_1.queue_free()
	player_2.queue_free()
	player_3.queue_free()
	player_4.queue_free()
	
	wave = 0
	time = 0.0
	score = 0


func _on_game_timer_timeout():
	time += 0.1
