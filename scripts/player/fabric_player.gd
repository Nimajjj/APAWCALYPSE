extends Node2D

var players: Array[IPlayer] = []

var player_scene: PackedScene = preload("res://scenes/player/candy.tscn");


func create_player() -> IPlayer:
	var player: IPlayer = player_scene.instantiate()
	
	player.id = Global.players.size()
	Global.players.append(player)
	
	add_child(player)
	return player;
