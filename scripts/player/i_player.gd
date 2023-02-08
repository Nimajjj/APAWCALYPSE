class_name IPlayer
extends Node2D

var player_scene:PackedScene = preload("res://scenes/player/player.tscn");

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
func create_player(id: int) -> Player:
	var player: Player = player_scene.instantiate()	
	player.id = id
	add_child(player)
	return player;
