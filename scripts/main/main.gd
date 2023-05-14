extends Node2D

var server_scene: PackedScene = preload("res://scenes/multiplayer/server.tscn")
var client_scene: PackedScene = preload("res://scenes/multiplayer/client.tscn")

var singleplayer_game_scene: PackedScene = preload("res://scenes/game/game.tscn")
var multiplayer_game_scene: PackedScene = preload("res://scenes/multiplayer/multiplayer_game.tscn")

var game: Game = null

@onready var player_ms: MultiplayerSpawner = $PlayerMultiplayerSpawner
@onready var enemies_ms: MultiplayerSpawner = $EnemiesMultiplayerSpawner


func _ready() -> void:
	randomize()
	seed(1)
	
	_create_game()
	
	multiplayer.allow_object_decoding = true
	
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
	
	server.connect("player_connected", game._new_player)


func _create_client() -> void:
	var client: Client = client_scene.instantiate()
	add_child(client)
	client.start_network()


func _on_player_multiplayer_spawner_spawned(node: Node) -> void:
	if node is IPlayer:
		if !node in Global.players:
			Global.players.append(node)


func _on_player_multiplayer_spawner_despawned(node: Node) -> void:
	if node is IPlayer:
		if node in Global.players:
			Global.players.erase(node)
