class_name IBullet
extends Area2D

@export var speed: int

var direction: Vector2
var damage: int
var life_time: float


func _physics_process(delta):
	position += direction * speed * delta 


func shoot(aim_position: Vector2) -> void:
	direction = (aim_position - position).normalized()
	rotation = direction.angle()

	var _timer: Timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = life_time
	_timer.connect("timeout", Callable(func(): queue_free()))
	add_child(_timer)
	_timer.start()

	connect("body_entered", Callable(func(body: Node): _on_Area2D_body_entered(body)))


func _on_Area2D_body_entered(body: Node) -> void:
	if body is IEnemy:
		body.damage(damage)
		queue_free()
