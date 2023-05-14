extends IBonusEffect

#DEAD SHOT
func _effect() -> void:
	get_parent().dead_shot = true


func end_effect() -> void:
	get_parent().active_bonus.erase((self.name.trim_suffix("Effect").to_lower()))
	get_parent().dead_shot = false
	queue_free()
