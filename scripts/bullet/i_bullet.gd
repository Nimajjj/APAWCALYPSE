class_name IBullet
extends Area2D

@export var speed: int
@export var piercing: bool = false

var shooter: IPlayer = null
var direction: Vector2
var damage: int
var life_time: float
var _fired: bool = false

func _physics_process(delta):
	if not _fired:
		return
	# Deplacement O(1) et independant du framerate. L'ancienne boucle
	# "for __ in range(speed * delta): position += direction" produisait la meme
	# position finale (les positions intermediaires ne declenchent aucune
	# detection de collision intra-frame) mais coutait jusqu'a des dizaines
	# d'iterations par balle et par frame, et tronquait la distance en entier.
	position += direction * speed * delta
	# Duree de vie geree par decompte : evite de creer (puis liberer) un Timer
	# node par balle -> beaucoup moins d'allocations / churn GC en tir nourri.
	life_time -= delta
	if life_time <= 0.0:
		queue_free()


func shoot(player: IPlayer, _aim_position: Vector2, d: Vector2) -> void:
	direction = d
	shooter = player
	rotation = direction.angle()
	_fired = true
	connect("area_entered", Callable(func(body: Node): _on_Area2D_body_entered(body)))


func _on_Area2D_body_entered(body: Node) -> void:
	if body.get_parent() is IEnemy && !body.get_parent().dead:
		body.get_parent().take_damage(damage, shooter)
		if !piercing:
			queue_free()
	if body.name == "WallCollisions":
		queue_free()
