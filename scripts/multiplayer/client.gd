class_name Client
extends Node


func start_network() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 9999)
	multiplayer.set_multiplayer_peer(peer)
