extends IBonusEffect

#NUKE
func _effect() -> void:
	print("Nuke started")
	$BeforeAudio.play()
	#Nuke effect is active at the end of the bonus, nothing should appear here.


func end_effect() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		enemy.dies(get_parent())
	$AudioStreamPlayer.play()

	print("Nuke ended")
	get_parent().active_bonus.erase((self.name.trim_suffix("Effect").to_lower()))
	


func _on_audio_stream_player_finished():
	queue_free()
