extends IBonusEffect

#NUKE
func _effect() -> void:
	print("Nuke started")
	#Nuke effect is active at the end of the bonus, nothing should appear here.


func end_effect() -> void:
	for child in Global.game.get_children():
		if "ISpawner" in child.name:
			var fabric_enemy = child.get_node("FabricEnemy")
			if fabric_enemy != null:
				for enemy_child in fabric_enemy.get_children():
					if enemy_child is IEnemy:
						enemy_child.dies(get_parent())

	print("Nuke ended")
	get_parent().active_bonus.erase(self.name.trim_suffix("Effect"))
	queue_free()
