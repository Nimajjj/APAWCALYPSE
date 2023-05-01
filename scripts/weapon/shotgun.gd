extends IWeapon


func shoot() -> void:
	if reloading: return
	if(actual_rate == fire_rate):
		if(current_mag > 0):
			for i in range(12):
				var bullet: IBullet = BulletScene.instantiate()
				shoot_effect.emitting = true
				bullet.position = WeaponEnd.get_global_transform().origin
				bullet.damage = damage
				bullet.life_time = weapon_range
				current_mag -= 1
				get_tree().get_root().add_child(bullet)
				var spread_angle = randf_range(-spread, spread)
				var shoot_direction = weapon_direction.rotated(spread_angle)
				bullet.shoot(get_parent(), get_global_mouse_position(), shoot_direction)
				actual_rate = 0
				get_parent().shake_camera(3, weight + 1, weight + 1, weight)
	actual_rate += 1

