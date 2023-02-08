class_name Bullet
extends Node2D

var direction: Vector2
var speed:int = 1

func _physics_process(delta):
	position += direction * speed * delta


func shoot(aim_position: Vector2, bullet_speed: int) -> void:
	speed = bullet_speed
	direction = (aim_position - position).normalized();
	rotation = direction.angle();


#func _on_area_entered(area) -> void:
#	if (area.get_parent().is_in_group("enemies")):
#		area.take_damage(damage);
#	queue_free();
