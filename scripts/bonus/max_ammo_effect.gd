extends IBonusEffect

#MAX AMMO
func _effect() -> void:
	var weapon = get_parent().weapon
	print("Max ammo started")
	weapon.current_mag = weapon.mag_capacity
	weapon.bullet_stock = weapon.max_bullet_stock
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
