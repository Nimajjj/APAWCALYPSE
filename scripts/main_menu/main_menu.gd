extends Control

var singleplayer_game_scene: PackedScene = preload("res://scenes/game/game.tscn")
var multiplayer_game_scene: PackedScene = preload("res://scenes/main/main.tscn")


func _on_play_button_pressed() -> void:
	get_tree().get_root().add_child(singleplayer_game_scene.instantiate())
	queue_free()


func _on_multiplayer_button_pressed() -> void:
	var scene = multiplayer_game_scene.instantiate()
	get_tree().get_root().add_child(scene)
	scene.run_client()
	queue_free()


func _on_server_button_pressed() -> void:
	var scene = multiplayer_game_scene.instantiate()
	get_tree().get_root().add_child(scene)
	scene.host_server()
	queue_free()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
