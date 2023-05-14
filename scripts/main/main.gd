extends Node2D

var server_scene: PackedScene = preload("res://scenes/multiplayer/server.tscn")
var client_scene: PackedScene = preload("res://scenes/multiplayer/client.tscn")

var singleplayer_game_scene: PackedScene = preload("res://scenes/game/game.tscn")
var multiplayer_game_scene: PackedScene = preload("res://scenes/multiplayer/multiplayer_game.tscn")

var game: Game = null

@onready var player_ms: MultiplayerSpawner = $PlayerMultiplayerSpawner


func _ready() -> void:
	_create_game()
	
	if "--server" in OS.get_cmdline_args():
		_create_server()
	else:
		_create_client()


func _create_game() -> void:
	game = multiplayer_game_scene.instantiate()
	add_child(game)
	player_ms.spawn_path = game.get_path()


func _create_server() -> void:
	var server: Server = server_scene.instantiate()
	add_child(server)
	server.init(game)


func _create_client() -> void:
	var client: Client = client_scene.instantiate()
	add_child(client)
	client.start_network()
