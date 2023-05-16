extends IWeapon

	
func _shoot_impl(player_damage_factor: int) -> void:
	for i in range(12):
		fire_rate_timer.start()
		can_shoot = false
		if shoot_effect:
			shoot_effect.emitting = true
		var bullet: IBullet = BulletScene.instantiate()
		bullet.position = WeaponEnd.get_global_transform().origin
		bullet.damage = damage * player_damage_factor
		bullet.life_time = weapon_range
		current_mag -= 1
		get_tree().get_root().add_child(bullet)
		var spread_angle = randf_range(-spread, spread)
		var shoot_direction = weapon_direction.rotated(spread_angle)
		bullet.shoot(get_parent(), get_global_mouse_position(), shoot_direction)
		actual_rate = 0
		get_parent().shake_camera(3, shake_power, shake_power, shake_power / 2)
		$AudioStreamPlayer.play()
