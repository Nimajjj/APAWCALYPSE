extends Node2D

var players: Array[IPlayer] = []

@export var player_scene: PackedScene
@export var Portrait: TextureRect




func create_player() -> IPlayer:
	var player: IPlayer = player_scene.instantiate()
	
	player.id = Global.players.size()
	Global.players.append(player)
	Global.map.add_child(player)
	player.position = position
	
	return player;


