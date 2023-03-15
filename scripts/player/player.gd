extends IPlayer


func _on_down_timer_timeout():
	state = PC_State.DEAD
