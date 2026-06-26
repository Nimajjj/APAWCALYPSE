extends IBonusEffect

#MAX AMMO
func _effect() -> void:
	var weapon = get_parent().weapon
	# La reserve est desormais infinie : ce bonus se contente d'un rechargement
	# instantane du chargeur (la limite de stock n'existe plus).
	weapon.current_mag = weapon.mag_capacity
	$AudioStreamPlayer.play()

	#avoid infinite reload
	weapon.reloading = false
	weapon.timer.stop()
	Global.in_game_ui.stop_reloading()


func end_effect() -> void:
	print("Max ammo ended")
	get_parent().active_bonus.erase((self.name.trim_suffix("Effect").to_lower()))
	


func _on_audio_stream_player_finished():
	queue_free()
