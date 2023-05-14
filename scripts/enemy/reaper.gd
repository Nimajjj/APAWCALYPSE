extends IEnemy

func slow() -> void:
	pass

func retarget() -> void:
	for new_target in Global.players:
		if new_target.health < target.health:
			target = new_target
	agent.target_position = target.global_position
