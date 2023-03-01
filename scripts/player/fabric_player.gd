extends Node2D

var players: Array[IPlayer] = []

var player_scene: PackedScene = preload("res://scenes/player/candy.tscn");


func create_player() -> IPlayer:
	var player: IPlayer = player_scene.instantiate()
	players.append(player)
	player.id = players.size()
	add_child(player)
	return player;
