extends IBonusEffect

#NUKE
func _effect() -> void:
	print("Nuke started")
	#Nuke effect is active at the end of the bonus, nothing should appear here.


func end_effect() -> void:
#	print(Global.spawners)

	var enemies := get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		enemy.dies(get_parent())

	print("Nuke ended")
	get_parent().active_bonus.erase((self.name.trim_suffix("Effect").to_lower()))
	queue_free()
