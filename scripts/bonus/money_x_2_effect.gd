extends IBonusEffect

#MONEY X2
func _effect() -> void:
	get_parent().money_x2 = true
	print("Money X2 started")


func end_effect() -> void:
	print("Money X2 ended")
	get_parent().active_bonus.erase(self.name.trim_suffix("Effect"))
	get_parent().money_x2 = false
	queue_free()
