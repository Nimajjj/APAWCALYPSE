extends IBonusEffect

#MONEY X2
func _effect() -> void:
	get_parent().money_x2 = true
	$AudioStreamPlayer.play()

func end_effect() -> void:
	get_parent().active_bonus.erase((self.name.trim_suffix("Effect").to_lower()))
	get_parent().money_x2 = false
	queue_free()
