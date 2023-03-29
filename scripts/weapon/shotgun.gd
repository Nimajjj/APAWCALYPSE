extends IWeapon


func _ready():
	spread = 0.4
	weapon_range = 0.1


func shoot() -> void:
	if(actual_rate == fire_rate):
		for i in range(12):
			var bullet: IBullet = BulletScene.instantiate()
			bullet.position = WeaponEnd.get_global_transform().origin
			bullet.damage = damage
			bullet.life_time = weapon_range
			get_tree().get_root().add_child(bullet)
			var spread_angle = randf_range(-spread, spread)
			var shoot_direction = weapon_direction.rotated(spread_angle)
			bullet.shoot(get_parent(), get_global_mouse_position(), shoot_direction)
			actual_rate = 0
	actual_rate += 1

