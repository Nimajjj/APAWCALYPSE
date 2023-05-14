extends IBonusEffect

#MAX AMMO
func _effect() -> void:
	var weapon = get_parent().weapon
	weapon.current_mag = weapon.mag_capacity
	weapon.bullet_stock = weapon.max_bullet_stock
	$AudioStreamPlayer.play()

	#avoid infinite reload
	weapon.reloading = false
	weapon.timer.stop()
	Global.in_game_ui.stop_reloading()


func end_effect() -> void:
	get_parent().active_bonus.erase((self.name.trim_suffix("Effect").to_lower()))
	


func _on_audio_stream_player_finished():
	queue_free()
