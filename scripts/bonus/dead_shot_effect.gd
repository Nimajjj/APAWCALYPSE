extends IBonusEffect

#DEAD SHOT
func _effect() -> void:
	get_parent().dead_shot = true
	print("Dead shot started")
	$AudioStreamPlayer.play()


func end_effect() -> void:
	print("Dead shot ended")
	get_parent().active_bonus.erase((self.name.trim_suffix("Effect").to_lower()))
	get_parent().dead_shot = false
	queue_free()
