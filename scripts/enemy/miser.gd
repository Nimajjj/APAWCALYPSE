extends IEnemy

func retarget() -> void:
	# Le miser vise le joueur le plus riche.
	for new_target in Global.players:
		if chase_target == null or new_target.money > chase_target.money:
			chase_target = new_target
	if chase_target != null:
		agent.target_position = chase_target.global_position
