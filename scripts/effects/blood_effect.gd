extends CPUParticles2D


func _ready():
	amount = randi_range(40, 60)
	modulate.a8 = randi_range(100, 150)
	$Timer.wait_time = randf_range(0.10, 0.20)


func _on_timer_timeout():
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	set_process_internal(false)
	set_process_unhandled_input(false)
	set_process_unhandled_key_input(false)
