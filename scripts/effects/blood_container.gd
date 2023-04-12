extends Node2D


func _enter_tree():
	Global.blood_container = self


func _on_timer_timeout():
	for child in get_children():
		if child is Timer: continue
		
		child.modulate.a8 -= 2
		
		if child.modulate.a8 <= 0:
			child.queue_free()
