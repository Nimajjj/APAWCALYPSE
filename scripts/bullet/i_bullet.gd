class_name IBullet
extends Area2D

@export var speed: int
@export var piercing: bool = false

var shooter: IPlayer = null
var direction: Vector2
var damage: int
var life_time: float

func _physics_process(delta):
#	position += direction * speed * delta 
	
	for __ in range(speed * delta):
		position += direction


func shoot(player: IPlayer, aim_position: Vector2, d: Vector2) -> void:
	direction = d
	shooter = player
	rotation = direction.angle()

	var _timer: Timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = life_time
	_timer.connect("timeout", Callable(func(): queue_free()))
	add_child(_timer)
	_timer.start()

	connect("area_entered", Callable(func(body: Node): _on_Area2D_body_entered(body)))


func _on_Area2D_body_entered(body: Node) -> void:
	if body.get_parent() is IEnemy && !body.get_parent().dead:
		body.get_parent().take_damage(damage, shooter)
		if !piercing:
			queue_free()
	if body.name == "WallCollisions":
		queue_free()
