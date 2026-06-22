extends IEnemy

func slow() -> void:
	pass

func retarget() -> void:
	# Le reaper vise le joueur le plus faible (moins de vie).
	for new_target in Global.players:
		if chase_target == null or new_target.health < chase_target.health:
			chase_target = new_target
	if chase_target != null:
		agent.target_position = chase_target.global_position
