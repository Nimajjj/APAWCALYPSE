extends GPUParticles2D


func _ready():
	amount = randi_range(10, 15)
	modulate.a8 = randi_range(135, 155)
	$Timer.wait_time = randf_range(0.15, 0.20)


func _on_timer_timeout():
	speed_scale = 0.0
