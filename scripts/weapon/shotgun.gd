extends IWeapon


func shoot(player_damage_factor: float) -> void:
	if reloading: return
	if(fire_rate_timer.time_left > 0): return
	if(can_shoot):
		if(current_mag > 0):
			for i in range(12):
				fire_rate_timer.start()
				can_shoot = false
				if shoot_effect != null:
					shoot_effect.emitting = true
				_fire_bullet(player_damage_factor, false, weapon_direction.rotated(randf_range(-spread, spread)))
				current_mag -= 1
				actual_rate = 0
				get_parent().shake_camera(3, shake_power, shake_power, shake_power / 2)
				$AudioStreamPlayer.play()
			actual_rate += 1
