class_name Server
extends Node

signal player_connected

var game: Game = null
var players: int = 0


func _enter_tree() -> void:
	Global.server = self


func init(game_node: Node) -> void:	
	game = game_node
	_start_network()


func _start_network() -> void:
	var peer = ENetMultiplayerPeer.new()
	
	# Listen to peer connections, and create new player for them
	multiplayer.peer_connected.connect(self._create_player)
	# Listen to peer disconnections, and destroy their players
	multiplayer.peer_disconnected.connect(self._destroy_player)
	
	peer.create_server(9999)
	print('Server listening on 127.0.0.1:9999')

	multiplayer.set_multiplayer_peer(peer)


func _create_player(id: int) -> void:
	# Instantiate a new player for this client.
	var player = game.FabricPlayer.create_player(players, str(id))

	# Set the name, so players can figure out their local authority
	game.add_child(player)
	print("New player joined [" + str(id) + "]")
	
	emit_signal("player_connected")
	
	players += 1


func _destroy_player(id: int) -> void:
	# Delete this peer's node.
	game.FabricPlayer.destroy_player(str(id))
			
	print("Player left [" + str(id) + "]")
	
	players -= 1
	
	if players == 0:
		print("No player left, disconnecting server...")
		get_tree().quit()
