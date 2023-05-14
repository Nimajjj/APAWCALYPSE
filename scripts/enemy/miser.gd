extends IEnemy

func retarget() -> void:
	for new_target in Global.players:
		if new_target.money > target.money:
			target = new_target
	agent.target_position = target.global_position
