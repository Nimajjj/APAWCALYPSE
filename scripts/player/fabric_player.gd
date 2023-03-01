extends Node2D

var players: Array[IPlayer] = []

var player_scene: PackedScene = preload("res://scenes/player/player.tscn");


func create_player() -> Player:
	var player: Player = player_scene.instantiate()
	players.append(player)
	player.id = players.size()
    add_child(player)
	return player;