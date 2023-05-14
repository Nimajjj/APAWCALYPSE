extends Node2D


var players_scene: Array[PackedScene] = [
	preload("res://scenes/player/bada-boom.tscn"),
	preload("res://scenes/player/blade.tscn"),
	preload("res://scenes/player/candy.tscn"),
	preload("res://scenes/player/grey.tscn"),
]


func create_player(i: int = 0, node_name: String = "default") -> IPlayer:
	var player: IPlayer = players_scene[i].instantiate()
	
	if node_name != "default":
		player.name = node_name
	
	player.id = Global.players.size()
	Global.players.append(player)
	player.global_position = global_position
	
	return player;


func destroy_player(node_name: String = "default") -> void:
	if node_name == "default":
		Global.players[0].queue_free()
		return
	
	for player in Global.players:
		if player.name == node_name:
			Global.players.erase(player)
			player.queue_free()
